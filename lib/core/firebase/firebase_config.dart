import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration is injected at build time with
/// `--dart-define-from-file=env/firebase.json` so that no project
/// credentials live in source control. See docs/FIREBASE_SETUP.md.
abstract final class FirebaseConfig {
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'demo-alwaqar');
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const androidAppId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID', defaultValue: 'com.alwaqar.app');

  /// When true the app talks to the local Firebase Emulator Suite.
  static const useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');
  static const emulatorHost = String.fromEnvironment('FIREBASE_EMULATOR_HOST', defaultValue: '10.0.2.2');

  /// The app is usable only when a real project is configured or the emulator is used.
  static bool get isConfigured {
    if (useEmulator) return true;
    final appId = defaultTargetPlatform == TargetPlatform.iOS ? iosAppId : androidAppId;
    return apiKey.isNotEmpty && appId.isNotEmpty && messagingSenderId.isNotEmpty && !projectId.startsWith('demo-');
  }

  static FirebaseOptions get currentPlatform {
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    return FirebaseOptions(
      apiKey: apiKey.isEmpty ? 'demo-api-key' : apiKey,
      appId: (isIos ? iosAppId : androidAppId).isEmpty
          ? '1:000000000000:${isIos ? 'ios' : 'android'}:0000000000000000'
          : (isIos ? iosAppId : androidAppId),
      messagingSenderId: messagingSenderId.isEmpty ? '000000000000' : messagingSenderId,
      projectId: projectId,
      storageBucket: storageBucket.isEmpty ? '$projectId.appspot.com' : storageBucket,
      iosBundleId: isIos ? iosBundleId : null,
    );
  }
}
