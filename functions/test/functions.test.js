'use strict';
/**
 * Cloud Functions integration tests against the Auth + Firestore + Functions emulators:
 *   npm run test:functions
 */
const { test, before, describe } = require('node:test');
const assert = require('node:assert/strict');

process.env.GCLOUD_PROJECT = 'demo-alwaqar';
const admin = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');
const { initializeApp, deleteApp } = require('firebase/app');
const { getAuth: clientAuth, connectAuthEmulator, signInWithEmailAndPassword, updatePassword, signOut } = require('firebase/auth');
const { getFunctions, connectFunctionsEmulator, httpsCallable } = require('firebase/functions');

admin.initializeApp({ projectId: 'demo-alwaqar' });
const ADMIN_EMAIL = 'rules-admin@alwaqar.test';
const ADMIN_PASSWORD = 'Admin@12345';

let n = 0;
function client() {
  const app = initializeApp({ apiKey: 'demo-key', projectId: 'demo-alwaqar', appId: 'demo' }, `c${n++}`);
  const auth = clientAuth(app);
  connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
  const fns = getFunctions(app, 'europe-west1');
  connectFunctionsEmulator(fns, '127.0.0.1', 5001);
  return { app, auth, call: (name, data) => httpsCallable(fns, name)(data).then((r) => r.data) };
}

let adminClient;

before(async () => {
  let user;
  try {
    user = await getAuth().getUserByEmail(ADMIN_EMAIL);
  } catch {
    user = await getAuth().createUser({ email: ADMIN_EMAIL, password: ADMIN_PASSWORD });
  }
  await getAuth().setCustomUserClaims(user.uid, { role: 'admin' });
  adminClient = client();
  await signInWithEmailAndPassword(adminClient.auth, ADMIN_EMAIL, ADMIN_PASSWORD);
});

describe('teacher account lifecycle', () => {
  test('create → first login → forced change → reset → deactivate → delete', async () => {
    // Create
    const created = await adminClient.call('createTeacher', { fullName: 'خالد محمود', departmentId: 'male' });
    assert.equal(created.temporaryPassword, 'خالد123');
    const db = getFirestore();
    const dir = await db.doc(`login_directory/${created.id}`).get();
    assert.equal(dir.get('displayName'), 'خالد محمود');
    const profile = await db.doc(`users/${created.id}`).get();
    assert.equal(profile.get('mustChangePassword'), true);
    assert.equal(JSON.stringify(profile.data()).includes('خالد123'), false, 'password must never be stored');

    // First login with the temporary password
    const teacher = client();
    const cred = await signInWithEmailAndPassword(teacher.auth, dir.get('authEmail'), 'خالد123');
    let token = await cred.user.getIdTokenResult(true);
    assert.equal(token.claims.role, 'teacher');
    assert.equal(token.claims.dept, 'male');
    assert.equal(token.claims.mcp, true);

    // Confirming without changing the password must fail
    await assert.rejects(teacher.call('confirmPasswordChanged', {}), /failed-precondition|لم يتم تغيير/);

    // Change password, then confirm
    await new Promise((r) => setTimeout(r, 1100));
    await updatePassword(cred.user, 'NewPass2026');
    await signInWithEmailAndPassword(teacher.auth, dir.get('authEmail'), 'NewPass2026');
    await teacher.call('confirmPasswordChanged', {});
    token = await teacher.auth.currentUser.getIdTokenResult(true);
    assert.equal(token.claims.mcp, undefined);
    assert.equal((await db.doc(`users/${created.id}`).get()).get('mustChangePassword'), false);

    // Teacher cannot call admin functions
    await assert.rejects(teacher.call('createTeacher', { fullName: 'محتال', departmentId: 'male' }), /permission-denied|للإدارة/);

    // Reset access
    const reset = await adminClient.call('resetTeacherPassword', { teacherId: created.id });
    assert.equal(reset.temporaryPassword, 'خالد123');
    assert.equal((await db.doc(`users/${created.id}`).get()).get('mustChangePassword'), true);

    // Rename keeps student denormalization in sync
    await db.doc('students/fn-s1').set({ fullName: 'طالب', teacherId: created.id, teacherName: 'خالد محمود', departmentId: 'male', totalPoints: 0, recitationCount: 0 });
    await adminClient.call('updateTeacher', { teacherId: created.id, fullName: 'خالد محمود السالم', departmentId: 'male' });
    assert.equal((await db.doc('students/fn-s1').get()).get('teacherName'), 'خالد محمود السالم');

    // Department change and deletion are blocked while students are assigned
    await assert.rejects(adminClient.call('updateTeacher', { teacherId: created.id, fullName: 'خالد', departmentId: 'female' }), /failed-precondition|انقل/);
    await assert.rejects(adminClient.call('deleteTeacher', { teacherId: created.id }), /failed-precondition|انقل/);
    await db.doc('students/fn-s1').delete();

    // Deactivate blocks sign-in
    await adminClient.call('setTeacherActive', { teacherId: created.id, active: false });
    const again = client();
    await assert.rejects(signInWithEmailAndPassword(again.auth, dir.get('authEmail'), 'خالد123'), /user-disabled/);
    assert.equal((await db.doc(`login_directory/${created.id}`).get()).get('active'), false);

    // Delete
    await adminClient.call('deleteTeacher', { teacherId: created.id });
    assert.equal((await db.doc(`teachers/${created.id}`).get()).exists, false);
    await assert.rejects(getAuth().getUser(created.id));

    await signOut(teacher.auth);
    await Promise.all([teacher.app, again.app].map(deleteApp));
  });

  test('first-login confirmation via Firestore trigger', async () => {
    const created = await adminClient.call('createTeacher', { fullName: 'سعد ناصر', departmentId: 'male' });
    const db = getFirestore();
    const email = (await db.doc(`login_directory/${created.id}`).get()).get('authEmail');
    const teacher = client();
    const cred = await signInWithEmailAndPassword(teacher.auth, email, created.temporaryPassword);
    await new Promise((r) => setTimeout(r, 1100));
    await updatePassword(cred.user, 'Trigger2026');
    await db.doc(`users/${created.id}`).update({ passwordChangeRequestedAt: new Date() });
    let flag = true;
    for (let i = 0; i < 50 && flag; i++) {
      await new Promise((r) => setTimeout(r, 200));
      flag = (await db.doc(`users/${created.id}`).get()).get('mustChangePassword');
    }
    assert.equal(flag, false);
    assert.equal((await getAuth().getUser(created.id)).customClaims.mcp, undefined);
    await adminClient.call('deleteTeacher', { teacherId: created.id });
    await deleteApp(teacher.app);
  });

  test('input validation returns Arabic errors', async () => {
    await assert.rejects(adminClient.call('createTeacher', { fullName: 'ا', departmentId: 'male' }), /الاسم/);
    await assert.rejects(adminClient.call('createTeacher', { fullName: 'سالم', departmentId: 'other' }), /القسم/);
  });

  test('short first names still meet the 6-character minimum', async () => {
    const created = await adminClient.call('createTeacher', { fullName: 'مي أحمد', departmentId: 'female' });
    assert.equal(created.temporaryPassword, 'مي1234');
    await adminClient.call('deleteTeacher', { teacherId: created.id });
  });
});
