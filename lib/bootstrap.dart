import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/firebase/firebase_config.dart';

/// Background FCM handler (must be a top-level function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: FirebaseConfig.currentPlatform);
}

/// Initializes Firebase, offline persistence, App Check and emulators.
Future<void> bootstrapFirebase() async {
  await initializeDateFormatting('ar');
  if (!FirebaseConfig.isConfigured) return;

  // Idempotent: the native side may already hold [DEFAULT] if the activity
  // (and its Flutter engine) is recreated within the same process.
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(options: FirebaseConfig.currentPlatform);
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') rethrow;
    } on Exception catch (e) {
      if (!e.toString().contains('already exists')) rethrow;
    }
  }

  if (FirebaseConfig.useEmulator) {
    final host = FirebaseConfig.emulatorHost;
    // The host is explicit: 10.0.2.2 on the Android emulator, 127.0.0.1 on a
    // physical phone via `adb reverse`. Disable FlutterFire's own remapping.
    await FirebaseAuth.instance.useAuthEmulator(host, 9099, automaticHostMapping: false);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080, automaticHostMapping: false);
    FirebaseFunctions.instanceFor(region: 'europe-west1').useFunctionsEmulator(host, 5001, automaticHostMapping: false);
  } else {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kReleaseMode ? const AndroidPlayIntegrityProvider() : const AndroidDebugProvider(),
      providerApple: kReleaseMode ? const AppleAppAttestWithDeviceCheckFallbackProvider() : const AppleDebugProvider(),
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // Offline-first: cache everything the user has loaded and queue writes.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
}
