'use strict';

/**
 * Teacher account management shared by the callable functions and the
 * seed / admin scripts. Uses the Admin SDK — never shipped to the app.
 */
const crypto = require('crypto');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const DEPARTMENTS = ['male', 'female'];
const AUTH_EMAIL_DOMAIN = 'teachers.alwaqar.app';

class DomainError extends Error {
  /** @param {string} code functions error code  @param {string} message Arabic message */
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

function normalizeName(name) {
  if (typeof name !== 'string') throw new DomainError('invalid-argument', 'الاسم مطلوب');
  const n = name.trim().replace(/\s+/g, ' ');
  if (n.length < 2 || n.length > 60) throw new DomainError('invalid-argument', 'الاسم يجب أن يكون بين حرفين و٦٠ حرفاً');
  if (/[0-9٠-٩<>{}[\]\\/]/.test(n)) throw new DomainError('invalid-argument', 'الاسم يحتوي على رموز غير مسموحة');
  return n;
}

function assertDepartment(dep) {
  if (!DEPARTMENTS.includes(dep)) throw new DomainError('invalid-argument', 'القسم غير صالح');
  return dep;
}

/**
 * Initial password convention: first Arabic name + "123" (e.g. محمد123).
 * Firebase requires 6+ characters, so very short names get "1234".
 * It is temporary: the `mcp` claim forces a change on first login.
 */
function initialPassword(fullName) {
  const first = normalizeName(fullName).split(' ')[0];
  const p = `${first}123`;
  return p.length >= 6 ? p : `${first}1234`;
}

async function createTeacher({ fullName, departmentId, phone }) {
  const name = normalizeName(fullName);
  const dep = assertDepartment(departmentId);
  const password = initialPassword(name);
  const authEmail = `t.${crypto.randomBytes(6).toString('hex')}@${AUTH_EMAIL_DOMAIN}`;

  const auth = getAuth();
  const db = getFirestore();
  const user = await auth.createUser({ email: authEmail, password, displayName: name, emailVerified: true });
  try {
    await auth.setCustomUserClaims(user.uid, { role: 'teacher', dept: dep, mcp: true });
    const now = FieldValue.serverTimestamp();
    const batch = db.batch();
    batch.set(db.collection('users').doc(user.uid), {
      role: 'teacher',
      displayName: name,
      departmentId: dep,
      active: true,
      mustChangePassword: true,
      email: authEmail,
      tempPasswordIssuedAt: new Date(),
      createdAt: now,
    });
    batch.set(db.collection('teachers').doc(user.uid), {
      displayName: name,
      departmentId: dep,
      active: true,
      studentCount: 0,
      phone: typeof phone === 'string' && phone.trim() ? phone.trim().slice(0, 30) : null,
      createdAt: now,
    });
    batch.set(db.collection('login_directory').doc(user.uid), {
      displayName: name,
      departmentId: dep,
      authEmail,
      active: true,
    });
    await batch.commit();
  } catch (e) {
    await auth.deleteUser(user.uid).catch(() => {});
    throw e;
  }
  return { id: user.uid, temporaryPassword: password };
}

async function getTeacherDoc(teacherId) {
  if (typeof teacherId !== 'string' || !teacherId) throw new DomainError('invalid-argument', 'المعلم غير محدد');
  const snap = await getFirestore().collection('teachers').doc(teacherId).get();
  if (!snap.exists) throw new DomainError('not-found', 'المعلم غير موجود');
  return snap;
}

async function countStudents(teacherId) {
  const agg = await getFirestore().collection('students').where('teacherId', '==', teacherId).count().get();
  return agg.data().count;
}

async function updateTeacher({ teacherId, fullName, departmentId, phone }) {
  const snap = await getTeacherDoc(teacherId);
  const name = normalizeName(fullName);
  const dep = assertDepartment(departmentId);
  const db = getFirestore();
  const auth = getAuth();
  if (snap.get('departmentId') !== dep && (await countStudents(teacherId)) > 0) {
    throw new DomainError('failed-precondition', 'لا يمكن تغيير قسم معلم لديه طلاب؛ انقل طلابه أولاً');
  }
  const user = await auth.getUser(teacherId);
  await auth.updateUser(teacherId, { displayName: name });
  await auth.setCustomUserClaims(teacherId, { ...(user.customClaims || {}), role: 'teacher', dept: dep });

  const batch = db.batch();
  batch.update(db.collection('users').doc(teacherId), { displayName: name, departmentId: dep });
  batch.update(db.collection('teachers').doc(teacherId), {
    displayName: name,
    departmentId: dep,
    phone: typeof phone === 'string' && phone.trim() ? phone.trim().slice(0, 30) : null,
  });
  batch.update(db.collection('login_directory').doc(teacherId), { displayName: name, departmentId: dep });
  await batch.commit();

  // Keep the denormalized teacher name on current students in sync.
  if (snap.get('displayName') !== name) {
    const students = await db.collection('students').where('teacherId', '==', teacherId).get();
    for (let i = 0; i < students.docs.length; i += 400) {
      const b = db.batch();
      students.docs.slice(i, i + 400).forEach((d) => b.update(d.ref, { teacherName: name }));
      await b.commit();
    }
  }
}

async function setTeacherActive({ teacherId, active }) {
  await getTeacherDoc(teacherId);
  if (typeof active !== 'boolean') throw new DomainError('invalid-argument', 'قيمة غير صالحة');
  const auth = getAuth();
  const db = getFirestore();
  await auth.updateUser(teacherId, { disabled: !active });
  if (!active) await auth.revokeRefreshTokens(teacherId);
  const batch = db.batch();
  batch.update(db.collection('users').doc(teacherId), { active });
  batch.update(db.collection('teachers').doc(teacherId), { active });
  batch.update(db.collection('login_directory').doc(teacherId), { active });
  await batch.commit();
}

async function resetTeacherPassword({ teacherId }) {
  const snap = await getTeacherDoc(teacherId);
  const password = initialPassword(snap.get('displayName'));
  const auth = getAuth();
  const user = await auth.getUser(teacherId);
  await auth.updateUser(teacherId, { password });
  await auth.setCustomUserClaims(teacherId, { ...(user.customClaims || {}), mcp: true });
  await auth.revokeRefreshTokens(teacherId);
  await getFirestore().collection('users').doc(teacherId).update({
    mustChangePassword: true,
    tempPasswordIssuedAt: new Date(),
  });
  return { temporaryPassword: password };
}

async function deleteTeacher({ teacherId }) {
  await getTeacherDoc(teacherId);
  if ((await countStudents(teacherId)) > 0) {
    throw new DomainError('failed-precondition', 'لا يمكن حذف معلم لديه طلاب؛ انقل طلابه أولاً');
  }
  const db = getFirestore();
  await getAuth().deleteUser(teacherId).catch((e) => {
    if (e.code !== 'auth/user-not-found') throw e;
  });
  const batch = db.batch();
  batch.delete(db.collection('users').doc(teacherId));
  batch.delete(db.collection('teachers').doc(teacherId));
  batch.delete(db.collection('login_directory').doc(teacherId));
  await batch.commit();
}

/**
 * Clears the "must change password" flag once Firebase Auth shows the password
 * was changed after the temporary one was issued (password changes revoke older
 * sessions, which moves `tokensValidAfterTime` forward).
 */
async function confirmPasswordChanged(uid) {
  const auth = getAuth();
  const db = getFirestore();
  const userRef = db.collection('users').doc(uid);
  const [user, profile] = await Promise.all([auth.getUser(uid), userRef.get()]);
  if (!profile.exists) throw new DomainError('not-found', 'الحساب غير موجود');
  const issued = profile.get('tempPasswordIssuedAt');
  const issuedAt = issued && typeof issued.toDate === 'function' ? issued.toDate() : null;
  const validAfter = user.tokensValidAfterTime ? new Date(user.tokensValidAfterTime) : null;
  if (issuedAt && (!validAfter || validAfter.getTime() <= issuedAt.getTime())) {
    throw new DomainError('failed-precondition', 'لم يتم تغيير كلمة المرور بعد');
  }
  const claims = { ...(user.customClaims || {}) };
  delete claims.mcp;
  await auth.setCustomUserClaims(uid, claims);
  await userRef.update({ mustChangePassword: false, passwordChangedAt: FieldValue.serverTimestamp() });
}

module.exports = {
  DomainError,
  DEPARTMENTS,
  initialPassword,
  normalizeName,
  createTeacher,
  updateTeacher,
  setTeacherActive,
  resetTeacherPassword,
  deleteTeacher,
  confirmPasswordChanged,
};
