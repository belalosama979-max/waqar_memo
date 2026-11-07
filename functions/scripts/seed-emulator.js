'use strict';
/**
 * Seeds the LOCAL Firebase Emulator Suite with demo data.
 * Refuses to run against a real project.
 *
 *   firebase emulators:start --project demo-alwaqar
 *   node scripts/seed-emulator.js
 */
process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || 'demo-alwaqar';

if (!process.env.GCLOUD_PROJECT.startsWith('demo-')) {
  console.error('Refusing to seed a non-demo project.');
  process.exit(1);
}

const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const teachers = require('../src/teachers');

initializeApp({ projectId: process.env.GCLOUD_PROJECT });

const ADMIN = { email: 'admin@alwaqar.test', password: 'Admin@12345', name: 'المشرف العام' };

const TEACHERS = [
  { fullName: 'محمد عبدالله', departmentId: 'male' },
  { fullName: 'أحمد يوسف', departmentId: 'male' },
  { fullName: 'فاطمة علي', departmentId: 'female' },
  { fullName: 'مريم حسن', departmentId: 'female' },
];

const STUDENTS = {
  'محمد عبدالله': ['عبدالرحمن خالد', 'عمر سعيد', 'يوسف إبراهيم', 'حمزة ناصر'],
  'أحمد يوسف': ['أنس محمود', 'بلال أسامة', 'زيد عمر'],
  'فاطمة علي': ['عائشة أحمد', 'خديجة محمد', 'سارة يوسف', 'نور الهدى'],
  'مريم حسن': ['آمنة خالد', 'رقية سعد', 'هاجر علي'],
};

const POINTS = { excellentPlus: 60, excellent: 40, veryGood: 25, notRecited: 0, repeat: 10 };
const SURAHS = { 67: 'الملك', 78: 'النبأ', 36: 'يس', 18: 'الكهف', 55: 'الرحمن', 56: 'الواقعة' };
const JUZ = { 30: 'الثلاثون', 29: 'التاسع والعشرون', 28: 'الثامن والعشرون' };

async function main() {
  const auth = getAuth();
  const db = getFirestore();

  // Admin account
  let admin;
  try {
    admin = await auth.getUserByEmail(ADMIN.email);
  } catch {
    admin = await auth.createUser({ email: ADMIN.email, password: ADMIN.password, displayName: ADMIN.name, emailVerified: true });
  }
  await auth.setCustomUserClaims(admin.uid, { role: 'admin' });
  await db.collection('users').doc(admin.uid).set({
    role: 'admin', displayName: ADMIN.name, departmentId: null, active: true, mustChangePassword: false,
    email: ADMIN.email, createdAt: FieldValue.serverTimestamp(),
  });

  await db.collection('departments').doc('male').set({ name: 'قسم الذكور' });
  await db.collection('departments').doc('female').set({ name: 'قسم الإناث' });
  await db.collection('evaluation_settings').doc('default').set({ points: POINTS, maxExtraPoints: 100, updatedAt: FieldValue.serverTimestamp() });
  await db.collection('app_settings').doc('general').set({ academyName: 'حلقات الوقار التجريبية', milestoneStep: 500, updatedAt: FieldValue.serverTimestamp() });

  const credentials = [];
  const evals = Object.keys(POINTS);
  for (const t of TEACHERS) {
    const created = await teachers.createTeacher(t);
    credentials.push({ name: t.fullName, department: t.departmentId, password: created.temporaryPassword });
    let count = 0;
    for (const studentName of STUDENTS[t.fullName]) {
      const sRef = db.collection('students').doc();
      let total = 0;
      let n = 0;
      let last = null;
      const batch = db.batch();
      for (let d = 20; d >= 1; d -= 1 + Math.floor(Math.random() * 3)) {
        const evaluation = evals[Math.floor(Math.random() * evals.length)];
        const extra = Math.random() < 0.3 ? 5 * Math.floor(Math.random() * 4) : 0;
        const isJuz = Math.random() < 0.3;
        const num = isJuz ? [30, 29, 28][n % 3] : [67, 78, 36, 18, 55, 56][n % 6];
        const label = isJuz ? `الجزء ${JUZ[num]}` : `سورة ${SURAHS[num]}`;
        const date = new Date();
        date.setDate(date.getDate() - d);
        date.setHours(12, 0, 0, 0);
        const rRef = db.collection('recitations').doc();
        const totalPoints = POINTS[evaluation] + extra;
        batch.set(rRef, {
          studentId: sRef.id, studentName, teacherId: created.id, teacherName: t.fullName, departmentId: t.departmentId,
          recitationDate: Timestamp.fromDate(date), recitationType: isJuz ? 'juz' : 'surah',
          partNumber: isJuz ? num : null, surahNumber: isJuz ? null : num,
          evaluation, evaluationPoints: POINTS[evaluation], extraPoints: extra, totalPoints,
          createdBy: created.id, createdAt: FieldValue.serverTimestamp(),
        });
        total += totalPoints;
        n += 1;
        last = { id: rRef.id, label, date, evaluation };
      }
      batch.set(sRef, {
        fullName: studentName, searchName: studentName, teacherId: created.id, teacherName: t.fullName,
        departmentId: t.departmentId, totalPoints: total, recitationCount: n,
        lastRecitationId: last.id, lastRecitationLabel: last.label, lastRecitationDate: Timestamp.fromDate(last.date),
        lastEvaluation: last.evaluation, lastAppliedRecitationId: last.id,
        joinedAt: FieldValue.serverTimestamp(), createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
      });
      await batch.commit();
      count += 1;
    }
    await db.collection('teachers').doc(created.id).update({ studentCount: count });
  }

  await db.collection('notifications').add({
    title: 'مرحباً بكم في الوقار', body: 'تم تفعيل نظام إدارة التسميع. نسأل الله التوفيق للجميع.',
    audience: 'all', type: 'announcement', createdBy: admin.uid, createdAt: FieldValue.serverTimestamp(),
  });

  console.log('Seed complete.');
  console.log(`Admin: ${ADMIN.email} / ${ADMIN.password}`);
  for (const c of credentials) console.log(`Teacher (${c.department}): ${c.name} / ${c.password}`);
}

main().then(() => process.exit(0), (e) => {
  console.error(e);
  process.exit(1);
});
