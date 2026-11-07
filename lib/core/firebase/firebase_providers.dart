import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Firebase singletons exposed as providers so tests can override them.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final functionsProvider = Provider<FirebaseFunctions>(
  (ref) => FirebaseFunctions.instanceFor(region: 'europe-west1'),
);
final messagingProvider = Provider<FirebaseMessaging>((ref) => FirebaseMessaging.instance);

/// Must be overridden in `main` after [SharedPreferences.getInstance].
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

/// Collection names.
abstract final class Col {
  static const users = 'users';
  static const teachers = 'teachers';
  static const loginDirectory = 'login_directory';
  static const students = 'students';
  static const recitations = 'recitations';
  static const departments = 'departments';
  static const evaluationSettings = 'evaluation_settings';
  static const appSettings = 'app_settings';
  static const notifications = 'notifications';
}
