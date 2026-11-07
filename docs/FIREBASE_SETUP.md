# إعداد Firebase — Firebase setup

The app uses **Firebase only** (Auth, Firestore, Storage, Cloud Messaging, Cloud Functions, App Check).
No credentials are committed: the Flutter app reads its Firebase options from
`--dart-define-from-file=env/firebase.json` (git-ignored).

## 1. Create the project

1. Create a project in the [Firebase console](https://console.firebase.google.com).
2. Upgrade to the **Blaze** plan — Cloud Functions require it (teacher accounts are
   created server-side with the Admin SDK).
3. Enable **Authentication → Email/Password**.
4. Create **Cloud Firestore** (production mode). Recommended location: `eur3` / `europe-west1`
   (the functions are deployed to `europe-west1`).
5. Enable **Cloud Storage** and **Cloud Messaging**.

## 2. Register the apps

| Platform | Identifier |
|---|---|
| Android | package `com.alwaqar.app` |
| iOS | bundle `com.alwaqar.app` |

Copy the values into `env/firebase.json` (start from `env/firebase.example.json`):
`apiKey`, `messagingSenderId`, `projectId`, `storageBucket`, Android `appId`, iOS `appId`.
You do **not** need `google-services.json` / `GoogleService-Info.plist`.

## 3. App Check

* Android: register the app with **Play Integrity** (add the SHA-256 of your upload
  key and of the Play App Signing key).
* iOS: register with **App Attest** (falls back to DeviceCheck).
* Debug builds use the debug provider — add the debug token printed in the device log
  under *App Check → Manage debug tokens*.
* Once traffic looks good, click **Enforce** for Firestore, Storage and Functions.
  The callable functions already set `enforceAppCheck: true` in production.

## 4. Push notifications (iOS)

Upload an **APNs Authentication Key** (.p8) in *Project settings → Cloud Messaging*,
and enable the *Push Notifications* + *Background Modes → Remote notifications*
capabilities in Xcode (the entitlements file is already in `ios/Runner`).
Set `aps-environment` to `production` for App Store builds.

## 5. Deploy rules, indexes and functions

```bash
npm install -g firebase-tools
firebase login
firebase use --add            # select your project, alias "default"
cd functions && npm install && cd ..
firebase deploy --only firestore,storage,functions
```

## 6. Create the first admin

```bash
cd functions
gcloud auth application-default login
ALWAQAR_ADMIN_PASSWORD='a-strong-password' node scripts/create-admin.js <projectId> admin@your-domain.com "المشرف العام"
```

This sets the `role: admin` custom claim, creates `users/{uid}` and seeds
`departments` and `evaluation_settings/default`.

## 7. Build the app against the project

```bash
flutter build apk --release --dart-define-from-file=env/firebase.json
flutter build appbundle --release --dart-define-from-file=env/firebase.json
flutter build ipa --release --dart-define-from-file=env/firebase.json   # on macOS
```

A build without configuration shows an Arabic "التطبيق غير مهيأ بعد" screen instead of crashing.

---

## Firestore data model

| Collection | Purpose | Who can read |
|---|---|---|
| `users/{uid}` | Private profile: role, department, `mustChangePassword`, FCM ids | self, admin |
| `teachers/{uid}` | Teacher profile, `studentCount` | admin, teachers of the same department |
| `login_directory/{uid}` | Name + department + synthetic auth e-mail (login screen) | public |
| `students/{id}` | Student, assigned teacher (denormalized name), aggregates | admin, same-department teachers |
| `recitations/{id}` | Append-only history with teacher/department snapshot | admin, same-department teachers |
| `evaluation_settings/default` | Points per evaluation, max extra points | signed-in |
| `app_settings/general` | Academy name, milestone step | signed-in |
| `notifications/{id}` | Announcements (`audience`) and personal milestones (`userId`) | admin, matching teachers |
| `departments/{male,female}` | Department labels | signed-in |

**Custom claims** (set only by Cloud Functions): `role`, `dept`, `mcp` (must change password).

### Security highlights (`firestore.rules`)

* Every teacher query must be provably restricted to the caller's department — the
  rules reject any query that could return another department's data.
* A teacher can only create a recitation **in the same batch** that adds exactly its
  points to their own student (`getAfter`), with the evaluation points matching the
  admin's current settings, extra points within the limit, and a valid juz/surah.
* Recitations are append-only for teachers; only admins delete (and the app reverses
  the points).
* A teacher holding a temporary password (`mcp` claim) can read only their own profile
  until `confirmPasswordChanged` verifies the change server-side.
* Passwords are never stored in Firestore.

**Known trade-off:** the login screen needs teacher names before sign-in, so
`login_directory` (names + department only) is publicly readable. Protect it further by
enforcing App Check on Firestore.

### Cloud Functions (`functions/index.js`)

| Function | Type | Purpose |
|---|---|---|
| `createTeacher` | callable (admin) | Auth user + claims + profile docs, returns temporary password |
| `updateTeacher` | callable (admin) | Rename / change department (blocked if students assigned) |
| `setTeacherActive` | callable (admin) | Disable/enable account, revoke sessions |
| `resetTeacherPassword` | callable (admin) | Back to "first name + 123", forces change |
| `deleteTeacher` | callable (admin) | Only when no students are assigned |
| `confirmPasswordChanged` | callable (user) | Clears `mcp` after verifying the password changed |
| `onNotificationCreated` | Firestore trigger | Sends announcements to FCM topics |
| `onRecitationCreated` | Firestore trigger | Milestone notification to the teacher |
