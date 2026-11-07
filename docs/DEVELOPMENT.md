# Development guide

## ⚠️ Arabic folder name on Windows

The project folder is named `الوقار`. Several tools fail on non-ASCII paths on Windows
(Dart analysis server, build_runner AOT, Android Gradle Plugin). Use an ASCII alias:

```powershell
# For analysis, tests, codegen, Firebase emulators (directory junction)
cmd /c mklink /J C:\dev\alwaqar "C:\path\to\الوقار"
cd C:\dev\alwaqar

# For Android builds (Gradle resolves junctions, so use a drive letter)
subst W: "C:\path\to\الوقار"
cd W:\
```

`android/gradle.properties` sets `kotlin.incremental=false` because Kotlin's incremental
caches break when sources and the pub cache are on different drives. Cloning into an
ASCII path (e.g. `C:\dev\alwaqar`) avoids all of this.

## Tooling

* Flutter 3.44+ / Dart 3.12+
* Node 22, Java 17+ (Firestore emulator) — Android Studio's JBR works:
  `$env:JAVA_HOME="C:\Program Files\Android\Android Studio\jbr"`

## Code generation (Freezed / json_serializable)

```bash
dart run build_runner build --delete-conflicting-outputs --force-jit
```

## Local backend: Firebase Emulator Suite

```bash
cd functions && npm install
npx firebase emulators:start --project demo-alwaqar      # terminal 1
node scripts/seed-emulator.js                             # terminal 2 — prints demo logins
```

Demo accounts after seeding: admin `admin@alwaqar.test` / `Admin@12345`; teachers
use the "first name + 123" password (e.g. `محمد123`) and must change it on first login.

Run the app against the emulators (Android emulator reaches the host at `10.0.2.2`):

```bash
flutter run --dart-define-from-file=env/emulator.json
```

### On a physical phone

Forward the emulator ports over ADB (USB or wireless debugging) and use the
loopback host. FlutterFire's automatic `10.0.2.2` remapping is disabled in `bootstrap.dart`.

```bash
adb reverse tcp:9099 tcp:9099 && adb reverse tcp:8080 tcp:8080 && adb reverse tcp:5001 tcp:5001
flutter run --dart-define-from-file=env/device.json -d <device-id>
```

Xiaomi/MIUI phones ask for confirmation on every ADB install ("Install via USB").

## Tests

```bash
flutter analyze
flutter test                                   # unit + widget tests
cd functions
npm run test:rules                             # Firestore security rules (emulator)
npm run test:functions                         # Cloud Functions (auth+firestore+functions emulators)
# End-to-end on an Android emulator, with seeded emulators running:
flutter test integration_test/app_test.dart --dart-define-from-file=env/emulator.json -d emulator-5554
```

## Architecture

Feature-first Clean Architecture:

```
lib/
  core/            theme, Firebase bootstrap/providers, errors (Arabic), utils, shared widgets
  features/<f>/
    domain/        entities (Freezed), pure business rules (PointsCalculator, Analytics)
    data/          repositories (Firestore / Functions), offline queue
    application/   Riverpod providers
    presentation/  screens & widgets
  router/          GoRouter with auth/role redirects, adaptive shell (bottom bar / rail)
```

State: Riverpod 3. Navigation: GoRouter 18 with `StatefulShellRoute` per role.

### Offline strategy

* Firestore persistence is enabled with an unlimited cache: previously loaded
  students, history and leaderboards are available offline.
* A recitation is one atomic batch (record + student aggregate) with a client-generated
  id, so retries and double taps can never duplicate it; the server rules also reject a
  second create with the same id.
* If the server doesn't acknowledge within 6 s, the write stays in Firestore's durable
  queue and `PendingSyncStore` (SharedPreferences) tracks it; the Arabic banner shows
  "غير متصل — N تسميع بانتظار المزامنة". When the batch is later accepted it disappears; if the
  server rejects it (e.g. points changed meanwhile) it moves to a "failed" list the
  teacher can review. After restarts, `reconcilePending()` checks each id on the server.
