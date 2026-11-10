# إعداد Firebase — Firebase setup (free Spark plan)

The app runs entirely on Firebase's **free Spark plan** (no billing account):
**Authentication + Cloud Firestore + App Check**. There are no Cloud Functions.
Everything that needs elevated rights is done by the admin from inside the app and
enforced by `firestore.rules`.

No credentials are committed: the app reads its Firebase options at build time from
`--dart-define-from-file=env/firebase.json` (git-ignored).

## 1. Create the project

1. Create a project in the [Firebase console](https://console.firebase.google.com)
   (or `firebase projects:create`). Stay on the **Spark** plan.
2. **Authentication → Get started → Email/Password → Enable** (first option only).
3. **Firestore Database → Create database** (production mode). Suggested location `eur3`.

## 2. Register the apps

| Platform | Identifier |
|---|---|
| Android | package `com.alwaqar.app` |
| iOS | bundle `com.alwaqar.app` |

Copy the values into `env/firebase.json` (template: `env/firebase.example.json`):
`apiKey`, `messagingSenderId`, `projectId`, `storageBucket`, Android `appId`, iOS `appId`.
`google-services.json` / `GoogleService-Info.plist` are **not** needed.

With the CLI:

```bash
firebase apps:create ANDROID "Alwaqar Android" --package-name com.alwaqar.app --project <id>
firebase apps:create IOS "Alwaqar iOS" --bundle-id com.alwaqar.app --project <id>
firebase apps:sdkconfig ANDROID <android-app-id> --project <id>
```

## 3. Deploy rules and indexes

```bash
cd functions && npm install && cd ..
npx --prefix functions firebase deploy --only firestore --project <id>
```

(On Windows with the Arabic folder name, run this from the `W:` drive mapping — see DEVELOPMENT.md.)

## 4. Build and create the first admin

```bash
flutter build apk --release --dart-define-from-file=env/firebase.json
```

Open the app → **تسجيل الدخول → الإدارة → «إعداد حساب الإدارة لأول مرة»**. This one-time
screen creates the first admin (you choose the e-mail and password). The rules allow it
only while `app_settings/bootstrap` does not exist, so **do it right after deploying**.
After that, the admin adds teachers and students from the app.

## 5. App Check (recommended)

Register the Android app with **Play Integrity** (add the SHA-256 of your signing key)
and iOS with **App Attest**, check the metrics, then **Enforce** for Firestore and
Authentication. Debug builds use the debug provider (add the token from the device log).

---

## Data model

| Collection | Purpose | Who can read |
|---|---|---|
| `users/{authUid}` | Login profile: `role`, `active`, `mustChangePassword`, `teacherId`, `departmentId` | self, admin |
| `teachers/{teacherId}` | Teacher identity (`authUid` = current login), `studentCount` | admin, same-department teachers |
| `login_directory/{teacherId}` | Name + department + login e-mail (for the login screen) | public |
| `students/{id}` | Student, `teacherId`, denormalized teacher name, aggregates | admin, same-department teachers |
| `recitations/{id}` | Append-only history with teacher/department snapshot | admin, same-department teachers |
| `evaluation_settings/default` | Points per evaluation, max extra points | signed-in |
| `app_settings/general` | Academy name, milestone step | signed-in |
| `app_settings/bootstrap` | Marks the one-time admin setup as done | public |
| `notifications/{id}` | Announcements (`audience`) and personal milestones (`userId` = teacherId) | admin, matching teachers |

A teacher's **identity** (`teachers/{teacherId}`) is separate from their **login**
(`users/{authUid}`). Students and recitations reference the teacher id, so the admin can
issue a new login without touching any history.

## How account management works without a server

| Operation | How |
|---|---|
| Create teacher | Admin app creates the Auth login through a *secondary* FirebaseApp (the admin stays signed in), then writes `teachers`, `login_directory`, `users` in one batch. Temporary password: first name + `123`. |
| First-login password | Teacher changes it in the app; the rules let a user only clear their own `mustChangePassword` (true → false). Until then the rules deny all academic data. |
| Reset access | Admin issues a **new** login (new temporary password) for the same teacher and retires the old login (`active: false`). |
| Deactivate | `active: false` on the teacher's logins; the rules deny everything and the app signs out. |
| Delete teacher | Only with no students assigned; identity and directory entry removed, logins retired. |
| Roles | Read from `users/{authUid}` by the rules (no custom claims). |

## Free-plan trade-offs

* **Push notifications while the app is closed** need a server (FCM sending), so they are
  not available. Notifications are stored in Firestore and shown in the app; while the
  app is open, new ones also raise a phone alert.
* Retired/deactivated logins still exist in Firebase Auth (an admin client cannot
  delete other users) but are powerless: the rules check `active`.
* The admin's own password can be reset by e-mail from the login screen.
* `login_directory` (names + department) is publicly readable because the login screen
  needs it before sign-in. Enforce App Check to limit access to the genuine app.
* Spark limits (50k reads / 20k writes per day) comfortably cover a typical academy.
