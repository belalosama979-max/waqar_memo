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

const ADMIN = { uid: 'admin1', claims: { role: 'admin' } };
const T_MALE = { uid: 'tm1', claims: { role: 'teacher', dept: 'male' } };
const T_MALE2 = { uid: 'tm2', claims: { role: 'teacher', dept: 'male' } };
const T_FEMALE = { uid: 'tf1', claims: { role: 'teacher', dept: 'female' } };
const T_MCP = { uid: 'tm3', claims: { role: 'teacher', dept: 'male', mcp: true } };

const db = (who) => (who ? env.authenticatedContext(who.uid, who.claims) : env.unauthenticatedContext()).firestore();

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
    await f.doc('users/tm1').set({ role: 'teacher', displayName: 'محمد', departmentId: 'male', active: true, mustChangePassword: true });
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
    studentId, studentName: 'طالب', teacherId: teacher.uid, teacherName: 'محمد', departmentId: dep,
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
    await assertFails(f.doc('users/tm1').get());
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
      fullName: 'x', teacherId: 'tm3', teacherName: 'x', departmentId: 'male', totalPoints: 0, recitationCount: 0,
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

  test('teachers cannot create teacher accounts or change roles', async () => {
    await assertFails(db(T_MALE).doc('teachers/x').set({ displayName: 'x', departmentId: 'male' }));
    await assertFails(db(T_MALE).doc('users/tm1').update({ role: 'admin' }));
    await assertFails(db(T_MALE).doc('users/tm1').update({ departmentId: 'female' }));
    await assertFails(db(T_MALE).doc('users/tm1').update({ mustChangePassword: false }));
    await assertSucceeds(db(T_MALE).doc('users/tm1').update({ fcmTokens: ['abc'] }));
    await assertSucceeds(db(T_MALE).doc('users/tm1').update({ passwordChangeRequestedAt: FieldValue.serverTimestamp() }));
    await assertFails(db(T_MALE).doc('users/tm1').update({ passwordChangeRequestedAt: Timestamp.fromDate(new Date(2020, 1, 1)) }));
    await assertFails(db(T_FEMALE).doc('users/tm1').update({ passwordChangeRequestedAt: FieldValue.serverTimestamp() }));
  });

  test('evaluation settings: admin only, validated', async () => {
    const valid = { points: { excellentPlus: 60, excellent: 40, veryGood: 25, notRecited: 0, repeat: 10 }, maxExtraPoints: 50 };
    await assertFails(db(T_MALE).doc('evaluation_settings/default').set(valid));
    await assertSucceeds(db(ADMIN).doc('evaluation_settings/default').set(valid));
    await assertFails(db(ADMIN).doc('evaluation_settings/default').set({ ...valid, points: { ...valid.points, excellent: -1 } }));
    await assertFails(db(ADMIN).doc('evaluation_settings/default').set({ ...valid, points: { excellent: 40 } }));
  });

  test('login directory is read-only for clients', async () => {
    await assertFails(db(null).doc('login_directory/x').set({ displayName: 'x' }));
    await assertFails(db(ADMIN).doc('login_directory/x').set({ displayName: 'x' }));
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
    await assertFails(db(T_MALE).collection('notifications').add({ ...n, createdBy: 'tm1' }));
  });
});
