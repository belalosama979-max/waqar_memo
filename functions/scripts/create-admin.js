'use strict';
/**
 * Creates (or promotes) the first ADMIN account in a real Firebase project.
 * Run locally with Application Default Credentials — never ship these to the app:
 *
 *   gcloud auth application-default login        # or set GOOGLE_APPLICATION_CREDENTIALS
 *   node scripts/create-admin.js <projectId> <email> "<display name>"
 *
 * The password is read from the ALWAQAR_ADMIN_PASSWORD environment variable so it
 * never appears in shell history. Also seeds default settings documents.
 */
const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

async function main() {
  const [projectId, email, displayName = 'المشرف العام'] = process.argv.slice(2);
  const password = process.env.ALWAQAR_ADMIN_PASSWORD;
  if (!projectId || !email) {
    console.error('Usage: node scripts/create-admin.js <projectId> <email> "<display name>"');
    process.exit(1);
  }
  initializeApp({ credential: applicationDefault(), projectId });
  const auth = getAuth();
  const db = getFirestore();

  let user;
  try {
    user = await auth.getUserByEmail(email);
    console.log('User exists, promoting to admin.');
  } catch {
    if (!password || password.length < 10) {
      console.error('Set ALWAQAR_ADMIN_PASSWORD (10+ characters) to create a new admin.');
      process.exit(1);
    }
    user = await auth.createUser({ email, password, displayName, emailVerified: true });
  }
  await auth.setCustomUserClaims(user.uid, { role: 'admin' });
  await db.collection('users').doc(user.uid).set(
    { role: 'admin', displayName, departmentId: null, active: true, mustChangePassword: false, email, createdAt: FieldValue.serverTimestamp() },
    { merge: true },
  );
  await db.collection('departments').doc('male').set({ name: 'قسم الذكور' }, { merge: true });
  await db.collection('departments').doc('female').set({ name: 'قسم الإناث' }, { merge: true });
  const evalRef = db.collection('evaluation_settings').doc('default');
  if (!(await evalRef.get()).exists) {
    await evalRef.set({
      points: { excellentPlus: 60, excellent: 40, veryGood: 25, notRecited: 0, repeat: 10 },
      maxExtraPoints: 100,
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  console.log(`Admin ready: ${email} (uid ${user.uid})`);
}

main().then(() => process.exit(0), (e) => {
  console.error(e);
  process.exit(1);
});
