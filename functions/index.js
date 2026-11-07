'use strict';

const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { setGlobalOptions } = require('firebase-functions/v2');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const logger = require('firebase-functions/logger');

const teachers = require('./src/teachers');

initializeApp();
setGlobalOptions({ region: 'europe-west1', maxInstances: 10 });

// App Check is enforced in production; the local emulator has no attestation.
const callableOptions = { enforceAppCheck: !process.env.FUNCTIONS_EMULATOR, cors: false };

function requireAdmin(request) {
  if (!request.auth) throw new HttpsError('unauthenticated', 'يرجى تسجيل الدخول');
  if (request.auth.token.role !== 'admin') throw new HttpsError('permission-denied', 'هذه العملية متاحة للإدارة فقط');
}

/** Wraps domain logic and converts errors to Arabic HttpsErrors. */
function adminCallable(handler) {
  return onCall(callableOptions, async (request) => {
    requireAdmin(request);
    try {
      return (await handler(request.data || {}, request)) || { ok: true };
    } catch (e) {
      if (e instanceof teachers.DomainError) throw new HttpsError(e.code, e.message);
      if (e instanceof HttpsError) throw e;
      logger.error('admin operation failed', e);
      throw new HttpsError('internal', 'تعذر تنفيذ العملية، حاول مرة أخرى');
    }
  });
}

exports.createTeacher = adminCallable((data) => teachers.createTeacher(data));
exports.updateTeacher = adminCallable(async (data) => {
  await teachers.updateTeacher(data);
});
exports.setTeacherActive = adminCallable(async (data) => {
  await teachers.setTeacherActive(data);
});
exports.resetTeacherPassword = adminCallable((data) => teachers.resetTeacherPassword(data));
exports.deleteTeacher = adminCallable(async (data) => {
  await teachers.deleteTeacher(data);
});

/** Called by any signed-in user right after changing their password. */
exports.confirmPasswordChanged = onCall(callableOptions, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'يرجى تسجيل الدخول');
  try {
    await teachers.confirmPasswordChanged(request.auth.uid);
    return { ok: true };
  } catch (e) {
    if (e instanceof teachers.DomainError) throw new HttpsError(e.code, e.message);
    logger.error('confirmPasswordChanged failed', e);
    throw new HttpsError('internal', 'تعذر تأكيد تغيير كلمة المرور');
  }
});

/**
 * The app signals a completed password change by writing
 * `users/{uid}.passwordChangeRequestedAt`; the server verifies it against
 * Firebase Auth and clears the first-login claim/flag.
 */
exports.onPasswordChangeRequested = onDocumentUpdated('users/{uid}', async (event) => {
  const before = event.data.before.data() || {};
  const after = event.data.after.data() || {};
  const b = before.passwordChangeRequestedAt;
  const a = after.passwordChangeRequestedAt;
  if (!a || (b && b.isEqual && b.isEqual(a)) || after.mustChangePassword !== true) return;
  try {
    await teachers.confirmPasswordChanged(event.params.uid);
  } catch (e) {
    logger.warn('password change not confirmed', { uid: event.params.uid, reason: e.message });
  }
});

/** Admin announcements -> FCM topic push. */
exports.onNotificationCreated = onDocumentCreated('notifications/{id}', async (event) => {
  const n = event.data && event.data.data();
  if (!n || n.type !== 'announcement') return;
  const topic = { all: 'all', dept_male: 'dept_male', dept_female: 'dept_female' }[n.audience];
  if (!topic) return;
  try {
    await getMessaging().send({
      topic,
      notification: { title: n.title, body: n.body },
      android: { priority: 'high', notification: { channelId: 'alwaqar_general', icon: 'ic_notification', color: '#0E4D3C' } },
      apns: { payload: { aps: { sound: 'default' } } },
      data: { type: 'announcement', id: event.params.id },
    });
  } catch (e) {
    logger.warn('announcement push failed', e);
  }
});

/** Recitation milestones: notify the teacher when a student crosses N points. */
exports.onRecitationCreated = onDocumentCreated('recitations/{id}', async (event) => {
  const r = event.data && event.data.data();
  if (!r) return;
  const db = getFirestore();
  const [student, settings, teacherUser] = await Promise.all([
    db.collection('students').doc(r.studentId).get(),
    db.collection('app_settings').doc('general').get(),
    db.collection('users').doc(r.teacherId).get(),
  ]);
  if (!student.exists) return;
  const step = Math.max(50, Number(settings.get('milestoneStep')) || 500);
  const after = Number(student.get('totalPoints')) || 0;
  const before = after - (Number(r.totalPoints) || 0);
  if (Math.floor(after / step) <= Math.floor(before / step)) return;

  const milestone = Math.floor(after / step) * step;
  const title = 'إنجاز جديد 🎉';
  const body = `بلغ ${r.studentName} ${milestone.toLocaleString('ar-EG')} نقطة. بارك الله في جهده!`;
  await db.collection('notifications').add({
    title,
    body,
    audience: 'user',
    userId: r.teacherId,
    type: 'milestone',
    studentId: r.studentId,
    createdAt: FieldValue.serverTimestamp(),
  });

  const tokens = (teacherUser.get('fcmTokens') || []).filter((t) => typeof t === 'string');
  if (tokens.length === 0) return;
  try {
    const res = await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      android: { priority: 'high', notification: { channelId: 'alwaqar_general', icon: 'ic_notification' } },
      data: { type: 'milestone', studentId: r.studentId },
    });
    const stale = tokens.filter((_, i) => !res.responses[i].success);
    if (stale.length) {
      await teacherUser.ref.update({ fcmTokens: FieldValue.arrayRemove(...stale) });
    }
  } catch (e) {
    logger.warn('milestone push failed', e);
  }
});
