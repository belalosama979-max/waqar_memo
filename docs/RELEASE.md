# Release guide

## Android

### 1. Upload keystore (once)

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Create `android/key.properties` (git-ignored):

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=upload-keystore.jks
```

Without `key.properties` the release build falls back to the debug key — fine for
local testing, **not** accepted by Google Play.

### 2. Build

```bash
flutter build apk --release --dart-define-from-file=env/firebase.json
flutter build appbundle --release --dart-define-from-file=env/firebase.json
```

Outputs: `build/app/outputs/flutter-apk/app-release.apk`,
`build/app/outputs/bundle/release/app-release.aab`.

Configured: package `com.alwaqar.app`, minSdk 23, compileSdk 37, R8 minify + resource
shrinking, adaptive + monochrome launcher icons, Android 12 splash, notification channel
`alwaqar_general`, `POST_NOTIFICATIONS` permission, cleartext traffic disabled (debug
builds allow `10.0.2.2` for the emulator only), backups disabled.

Bump `version:` in `pubspec.yaml` for each store upload.

## iOS (requires macOS + Xcode)

Configured in the repo: bundle id `com.alwaqar.app`, display name «الوقار», Arabic
development region, iOS 15 deployment target, app icons (alpha removed), launch screen,
push entitlement (`Runner.entitlements`), background modes (remote notifications),
`ITSAppUsesNonExemptEncryption = false`, iPhone + iPad orientations.

On a Mac:

```bash
flutter pub get
cd ios && pod install && cd ..
open ios/Runner.xcworkspace   # set Team, enable Push Notifications & Background Modes
flutter build ipa --release --dart-define-from-file=env/firebase.json
```

Set `aps-environment` to `production` in `ios/Runner/Runner.entitlements` for App Store
builds, and upload the APNs key to Firebase (see FIREBASE_SETUP.md).
