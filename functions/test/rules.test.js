'use strict';
/**
 * Firestore Security Rules tests (run inside the Firestore emulator):
 *   npm run test:rules
 */
const { test, before, after, beforeEach, describe } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const firebase = require('firebase/compat/app');
require('firebase/compat/firestore');

const { FieldValue, Timestamp } = firebase.firestore;
let env;

// Roles come from users/{authUid} profile documents (no custom claims).
// Login uid and teacher id differ on purpose: a teacher's identity is
// teachers/{tid}; users/{uid}.teacherId links a login to it.
const ADMIN = { uid: 'admin1' };
const T_MALE = { uid: 'u_tm1', tid: 'tm1', dep: 'male' };
const T_MALE2 = { uid: 'u_tm2', tid: 'tm2', dep: 'male' };
const T_FEMALE = { uid: 'u_tf1', tid: 'tf1', dep: 'female' };
const T_MCP = { uid: 'u_tm3', tid: 'tm3', dep: 'male' };
const RETIRED = { uid: 'u_tm1_old', tid: 'tm1', dep: 'male' };

const db = (who) => (who ? env.authenticatedContext(who.uid) : env.unauthenticatedContext()).firestore();

before(async () => {
  const [host, port] = (process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080').split(':');
  env = await initializeTestEnvironment({
    projectId: 'demo-alwaqar-rules',
    firestore: { rules: fs.readFileSync(path.join(__dirname, '..', '..', 'firestore.rules'), 'utf8'), host, port: Number(port) },
  });
});

after(async () => env && env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const f = ctx.firestore();
    const teacher = (uid, name, dep) => f.doc(`teachers/${uid}`).set({ displayName: name, departmentId: dep, active: true, studentCount: 1 });
    await teacher('tm1', 'محمد', 'male');
    await teacher('tm2', 'أحمد', 'male');
    await teacher('tf1', 'فاطمة', 'female');
    await teacher('tm3', 'سالم', 'male');
    await f.doc('users/admin1').set({ role: 'admin', displayName: 'المشرف', departmentId: null, active: true, mustChangePassword: false });
    const login = (who, name, extra = {}) => f.doc(`users/${who.uid}`).set({
      role: 'teacher', displayName: name, departmentId: who.dep, teacherId: who.tid, active: true, mustChangePassword: false, ...extra,
    });
    await login(T_MALE, 'محمد');
    await login(T_MALE2, 'أحمد');
    await login(T_FEMALE, 'فاطمة');
    await login(T_MCP, 'سالم', { mustChangePassword: true });
    await login(RETIRED, 'محمد', { active: false });
    await f.doc('app_settings/bootstrap').set({ adminUid: 'admin1', createdAt: Timestamp.now() });
    await f.doc('login_directory/tm1').set({ displayName: 'محمد', departmentId: 'male', authEmail: 'x@y.z', active: true });
    const student = (id, teacherId, dep) => f.doc(`students/${id}`).set({
      fullName: `طالب ${id}`, searchName: id, teacherId, teacherName: 'x', departmentId: dep, totalPoints: 100, recitationCount: 2,
    });
    await student('sm1', 'tm1', 'male');
    await student('sm2', 'tm2', 'male');
    await student('sf1', 'tf1', 'female');
    await f.doc('recitations/rf1').set({ studentId: 'sf1', departmentId: 'female', teacherId: 'tf1', totalPoints: 40 });
    await f.doc('recitations/rm1').set({ studentId: 'sm1', departmentId: 'male', teacherId: 'tm1', totalPoints: 40 });
    await f.doc('evaluation_settings/default').set({
      points: { excellentPlus: 60, excellent: 40, veryGood: 25, notRecited: 0, repeat: 10 }, maxExtraPoints: 100,
    });
    await f.doc('notifications/all1').set({ title: 'a', body: 'b', audience: 'all', type: 'announcement', createdAt: Timestamp.now() });
    await f.doc('notifications/fem1').set({ title: 'a', body: 'b', audience: 'dept_female', type: 'announcement', createdAt: Timestamp.now() });
  });
});

/** Builds the exact batch the app writes when recording a recitation. */
function recitationBatch(f, { rid = 'new1', studentId = 'sm1', teacher = T_MALE, evaluation = 'excellent', evalPts = 40, extra = 5, total, dep = 'male', type = 'surah', num = 67, inc } = {}) {
  const b = f.batch();
  const t = total === undefined ? evalPts + extra : total;
  b.set(f.doc(`recitations/${rid}`), {
    studentId, studentName: 'طالب', teacherId: teacher.tid, teacherName: 'محمد', departmentId: dep,
    recitationDate: Timestamp.now(), recitationType: type,
    partNumber: type === 'juz' ? num : null, surahNumber: type === 'surah' ? num : null,
    evaluation, evaluationPoints: evalPts, extraPoints: extra, totalPoints: t,
    createdBy: teacher.uid, createdAt: FieldValue.serverTimestamp(),
  });
  b.update(f.doc(`students/${studentId}`), {
    totalPoints: FieldValue.increment(inc === undefined ? t : inc),
    recitationCount: FieldValue.increment(1),
    lastAppliedRecitationId: rid,
    lastRecitationId: rid,
    lastRecitationLabel: 'سورة الملك',
    lastEvaluation: evaluation,
    updatedAt: FieldValue.serverTimestamp(),
  });
  return b;
}

describe('department isolation', () => {
  test('teacher reads students of own department only', async () => {
    const f = db(T_MALE);
    await assertSucceeds(f.collection('students').where('departmentId', '==', 'male').get());
    await assertFails(f.collection('students').where('departmentId', '==', 'female').get());
    await assertFails(f.collection('students').get());
    await assertFails(f.doc('students/sf1').get());
  });

  test('female teacher cannot see male teachers', async () => {
    const f = db(T_FEMALE);
    await assertSucceeds(f.collection('teachers').where('departmentId', '==', 'female').get());
    await assertFails(f.collection('teachers').where('departmentId', '==', 'male').get());
    await assertFails(f.doc('teachers/tm1').get());
  });

  test('male teacher cannot see female teachers', async () => {
    await assertFails(db(T_MALE).doc('teachers/tf1').get());
  });

  test('recitations are isolated by department', async () => {
    const f = db(T_MALE);
    await assertSucceeds(f.doc('recitations/rm1').get());
    await assertFails(f.doc('recitations/rf1').get());
    await assertFails(f.collection('recitations').where('departmentId', '==', 'female').get());
  });

  test('admin reads everything', async () => {
    const f = db(ADMIN);
    await assertSucceeds(f.collection('students').get());
    await assertSucceeds(f.collection('teachers').get());
    await assertSucceeds(f.collection('recitations').get());
  });

  test('unauthenticated users only see the login directory', async () => {
    const f = db(null);
    await assertSucceeds(f.collection('login_directory').where('departmentId', '==', 'male').get());
    await assertFails(f.collection('students').where('departmentId', '==', 'male').get());
    await assertFails(f.doc(`users/${T_MALE.uid}`).get());
  });
});

describe('recitation registration', () => {
  test('teacher records a valid recitation for own student', async () => {
    await assertSucceeds(recitationBatch(db(T_MALE)).commit());
  });

  test('juz recitation is accepted', async () => {
    await assertSucceeds(recitationBatch(db(T_MALE), { type: 'juz', num: 30, evaluation: 'excellentPlus', evalPts: 60, extra: 0 }).commit());
  });

  test('wrong evaluation points are rejected', async () => {
    await assertFails(recitationBatch(db(T_MALE), { evaluation: 'excellent', evalPts: 60 }).commit());
  });

  test('total must equal evaluation + extra', async () => {
    await assertFails(recitationBatch(db(T_MALE), { total: 500 }).commit());
  });

  test('extra points above the maximum are rejected', async () => {
    await assertFails(recitationBatch(db(T_MALE), { extra: 101 }).commit());
  });

  test('negative extra points are rejected', async () => {
    await assertFails(recitationBatch(db(T_MALE), { extra: -5 }).commit());
  });

  test('student total must increase by exactly the session total', async () => {
    await assertFails(recitationBatch(db(T_MALE), { inc: 1000 }).commit());
  });

  test('invalid surah number is rejected', async () => {
    await assertFails(recitationBatch(db(T_MALE), { num: 115 }).commit());
    await assertFails(recitationBatch(db(T_MALE), { type: 'juz', num: 31 }).commit());
  });

  test('teacher cannot record for another teacher\'s student', async () => {
    await assertFails(recitationBatch(db(T_MALE), { studentId: 'sm2' }).commit());
  });

  test('teacher cannot record for a student in another department', async () => {
    await assertFails(recitationBatch(db(T_MALE), { studentId: 'sf1', dep: 'female' }).commit());
  });

  test('recitation without the student aggregate update is rejected', async () => {
    const f = db(T_MALE);
    await assertFails(f.doc('recitations/lonely').set({
      studentId: 'sm1', studentName: 'x', teacherId: 'tm1', teacherName: 'x', departmentId: 'male',
      recitationDate: Timestamp.now(), recitationType: 'surah', partNumber: null, surahNumber: 1,
      evaluation: 'excellent', evaluationPoints: 40, extraPoints: 0, totalPoints: 40,
      createdBy: 'tm1', createdAt: FieldValue.serverTimestamp(),
    }));
  });

  test('teacher cannot inflate points without a recitation', async () => {
    await assertFails(db(T_MALE).doc('students/sm1').update({ totalPoints: 9999 }));
  });

  test('duplicate submission with the same id is rejected', async () => {
    await assertSucceeds(recitationBatch(db(T_MALE), { rid: 'dup' }).commit());
    await assertFails(recitationBatch(db(T_MALE), { rid: 'dup' }).commit());
  });

  test('history is append-only for teachers', async () => {
    await assertFails(db(T_MALE).doc('recitations/rm1').update({ totalPoints: 1 }));
    await assertFails(db(T_MALE).doc('recitations/rm1').delete());
    await assertSucceeds(db(ADMIN).doc('recitations/rm1').delete());
  });

  test('teacher with a temporary password cannot write academic data', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => ctx.firestore().doc('students/sm3').set({
      fullName: 'x', teacherId: 'tm3', teacherName: 'x', departmentId: 'male', totalPoints: 0, recitationCount: 0, lastAppliedRecitationId: null,
    }));
    await assertFails(recitationBatch(db(T_MCP), { studentId: 'sm3', teacher: T_MCP }).commit());
    await assertFails(db(T_MCP).collection('students').where('departmentId', '==', 'male').get());
  });

  test('admin-modified points are enforced', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => ctx.firestore().doc('evaluation_settings/default').set({
      points: { excellentPlus: 70, excellent: 45, veryGood: 25, notRecited: 0, repeat: 10 }, maxExtraPoints: 20,
    }));
    await assertFails(recitationBatch(db(T_MALE), { evalPts: 40 }).commit());
    await assertSucceeds(recitationBatch(db(T_MALE), { evalPts: 45, extra: 20 }).commit());
    await assertFails(recitationBatch(db(T_MALE), { rid: 'n2', evalPts: 45, extra: 21 }).commit());
  });
});

describe('administration', () => {
  test('only admin creates students, and the teacher must match the department', async () => {
    const data = { fullName: 'طالب جديد', searchName: 'x', teacherId: 'tm1', teacherName: 'محمد', departmentId: 'male', totalPoints: 0, recitationCount: 0 };
    await assertFails(db(T_MALE).doc('students/n1').set(data));
    await assertSucceeds(db(ADMIN).doc('students/n1').set(data));
    await assertFails(db(ADMIN).doc('students/n2').set({ ...data, departmentId: 'female' }));
    await assertFails(db(ADMIN).doc('students/n3').set({ ...data, totalPoints: 50 }));
  });

  test('transfer must target a teacher of the student\'s new department', async () => {
    const f = db(ADMIN);
    await assertSucceeds(f.doc('students/sm1').update({ teacherId: 'tm2', teacherName: 'أحمد', departmentId: 'male' }));
    await assertFails(f.doc('students/sm1').update({ teacherId: 'tf1', teacherName: 'فاطمة', departmentId: 'male' }));
  });

  test('profiles: teachers cannot change roles, departments or others; can finish first-login', async () => {
    const me = db(T_MALE).doc(`users/${T_MALE.uid}`);
    await assertFails(db(T_MALE).doc('teachers/x').set({ displayName: 'xx', departmentId: 'male', active: true, studentCount: 0 }));
    await assertFails(me.update({ role: 'admin' }));
    await assertFails(me.update({ departmentId: 'female' }));
    await assertFails(me.update({ teacherId: 'tm2' }));
    await assertFails(me.update({ active: true, mustChangePassword: true }));
    await assertSucceeds(me.update({ fcmTokens: ['abc'] }));
    await assertFails(db(T_FEMALE).doc(`users/${T_MALE.uid}`).update({ fcmTokens: ['x'] }));
    await assertFails(db(T_FEMALE).doc(`users/${T_MALE.uid}`).get());
    // First-login: a teacher may only clear their own flag (true -> false).
    const mcp = db(T_MCP).doc(`users/${T_MCP.uid}`);
    await assertSucceeds(mcp.update({ mustChangePassword: false, passwordChangedAt: FieldValue.serverTimestamp() }));
    await assertFails(mcp.update({ passwordChangedAt: Timestamp.fromDate(new Date(2020, 1, 1)) }));
  });

  test('retired / deactivated logins can do nothing', async () => {
    const f = db(RETIRED);
    await assertSucceeds(f.doc(`users/${RETIRED.uid}`).get());
    await assertFails(f.collection('students').where('departmentId', '==', 'male').get());
    await assertFails(recitationBatch(f, { teacher: RETIRED }).commit());
  });

  test('admin creates a teacher (identity + directory + login) atomically', async () => {
    const f = db(ADMIN);
    const b = f.batch();
    b.set(f.doc('teachers/tnew'), { displayName: 'خالد', departmentId: 'male', active: true, studentCount: 0, phone: null, authUid: 'u_new', createdAt: FieldValue.serverTimestamp() });
    b.set(f.doc('login_directory/tnew'), { displayName: 'خالد', departmentId: 'male', authEmail: 't.1@teachers.alwaqar.app', active: true });
    b.set(f.doc('users/u_new'), { role: 'teacher', displayName: 'خالد', departmentId: 'male', teacherId: 'tnew', active: true, mustChangePassword: true, email: 't.1@teachers.alwaqar.app', createdAt: FieldValue.serverTimestamp() });
    await assertSucceeds(b.commit());
    // Must start with a temporary password, and match the teacher's department.
    await assertFails(f.doc('users/u_x').set({ role: 'teacher', displayName: 'خالد', departmentId: 'male', teacherId: 'tnew', active: true, mustChangePassword: false }));
    await assertFails(f.doc('users/u_y').set({ role: 'teacher', displayName: 'خالد', departmentId: 'female', teacherId: 'tnew', active: true, mustChangePassword: true }));
    await assertFails(f.doc('users/u_z').set({ role: 'admin', displayName: 'خالد', active: true, mustChangePassword: false }));
    // Teachers cannot create logins.
    await assertFails(db(T_MALE).doc('users/u_w').set({ role: 'teacher', displayName: 'خالد', departmentId: 'male', teacherId: 'tm1', active: true, mustChangePassword: true }));
  });

  test('admin deactivates and retires logins; teacher with students keeps department', async () => {
    const f = db(ADMIN);
    await assertSucceeds(f.doc(`users/${T_MALE2.uid}`).update({ active: false, replacedAt: FieldValue.serverTimestamp() }));
    await assertFails(f.doc(`users/${T_MALE2.uid}`).update({ role: 'admin' }));
    await assertFails(f.doc('teachers/tm1').update({ departmentId: 'female' }));
    await assertFails(f.doc('teachers/tm1').delete());
  });

  test('first-run admin setup works once only', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => ctx.firestore().doc('app_settings/bootstrap').delete());
    const setup = (who) => {
      const f = db(who);
      const b = f.batch();
      b.set(f.doc(`users/${who.uid}`), { role: 'admin', displayName: 'المشرف العام', departmentId: null, active: true, mustChangePassword: false, email: 'a@b.c', createdAt: FieldValue.serverTimestamp() });
      b.set(f.doc('app_settings/bootstrap'), { adminUid: who.uid, createdAt: FieldValue.serverTimestamp() });
      return b.commit();
    };
    await assertSucceeds(db(null).doc('app_settings/bootstrap').get());
    await assertSucceeds(setup({ uid: 'boss' }));
    await assertFails(setup({ uid: 'intruder' }));
    // Cannot self-promote without the bootstrap document either.
    await assertFails(db({ uid: 'intruder' }).doc('users/intruder').set({ role: 'admin', displayName: 'xx', active: true, mustChangePassword: false }));
  });

  test('evaluation settings: admin only, validated', async () => {
    const valid = { points: { excellentPlus: 60, excellent: 40, veryGood: 25, notRecited: 0, repeat: 10 }, maxExtraPoints: 50 };
    await assertFails(db(T_MALE).doc('evaluation_settings/default').set(valid));
    await assertSucceeds(db(ADMIN).doc('evaluation_settings/default').set(valid));
    await assertFails(db(ADMIN).doc('evaluation_settings/default').set({ ...valid, points: { ...valid.points, excellent: -1 } }));
    await assertFails(db(ADMIN).doc('evaluation_settings/default').set({ ...valid, points: { excellent: 40 } }));
  });

  test('login directory: public read, admin-only validated writes', async () => {
    const entry = { displayName: 'خالد', departmentId: 'male', authEmail: 't.1@teachers.alwaqar.app', active: true };
    await assertSucceeds(db(null).doc('login_directory/tm1').get());
    await assertFails(db(null).doc('login_directory/x').set(entry));
    await assertFails(db(T_MALE).doc('login_directory/x').set(entry));
    await assertSucceeds(db(ADMIN).doc('login_directory/x').set(entry));
    await assertFails(db(ADMIN).doc('login_directory/y').set({ ...entry, departmentId: 'other' }));
  });
});

describe('notifications', () => {
  test('teachers see announcements for all and their department only', async () => {
    const f = db(T_MALE);
    await assertSucceeds(f.collection('notifications').where('audience', '==', 'all').get());
    await assertSucceeds(f.collection('notifications').where('audience', '==', 'dept_male').get());
    await assertFails(f.collection('notifications').where('audience', '==', 'dept_female').get());
    await assertFails(f.doc('notifications/fem1').get());
    await assertSucceeds(db(T_FEMALE).doc('notifications/fem1').get());
  });

  test('only admins publish announcements', async () => {
    const n = { title: 'إعلان', body: 'نص', audience: 'all', type: 'announcement', createdBy: 'admin1', createdAt: FieldValue.serverTimestamp() };
    await assertSucceeds(db(ADMIN).collection('notifications').add(n));
    await assertFails(db(T_MALE).collection('notifications').add({ ...n, createdBy: T_MALE.uid }));
  });

  test('teachers write only their own milestone notifications', async () => {
    const m = { title: 'إنجاز', body: 'بلغ الطالب ٥٠٠ نقطة', audience: 'user', type: 'milestone', userId: 'tm1', studentId: 'sm1', createdBy: T_MALE.uid, createdAt: FieldValue.serverTimestamp() };
    await assertSucceeds(db(T_MALE).collection('notifications').add(m));
    await assertFails(db(T_MALE).collection('notifications').add({ ...m, userId: 'tm2' }));
    await assertFails(db(T_MALE).collection('notifications').add({ ...m, audience: 'all' }));
    await assertSucceeds(db(T_MALE).collection('notifications').where('userId', '==', 'tm1').get());
    await assertFails(db(T_MALE).collection('notifications').where('userId', '==', 'tm2').get());
  });
});
