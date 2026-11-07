import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_config.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../auth/domain/app_user.dart';

final localNotificationsProvider = Provider<FlutterLocalNotificationsPlugin>(
  (ref) => FlutterLocalNotificationsPlugin(),
);

final pushServiceProvider = Provider<PushService>(
  (ref) => PushService(ref.watch(messagingProvider), ref.watch(firestoreProvider), ref.watch(localNotificationsProvider)),
);

/// Firebase Cloud Messaging + local notifications (Arabic channel).
class PushService {
  PushService(this._fcm, this._db, this._local);

  final FirebaseMessaging _fcm;
  final FirebaseFirestore _db;
  final FlutterLocalNotificationsPlugin _local;

  static const channel = AndroidNotificationChannel(
    'alwaqar_general',
    'إشعارات الوقار',
    description: 'التنبيهات والإعلانات الخاصة بالتسميع',
    importance: Importance.high,
  );

  bool _initialized = false;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<String>? _tokenSub;
  final _subscribedTopics = <String>{};
  String? _registrationId;

  Future<void> initLocal() async {
    if (_initialized) return;
    _initialized = true;
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> showLocal({required String title, required String body}) async {
    await initLocal();
    await _local.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
    );
  }

  List<String> _topicsFor(AppUser user) => [
        'all',
        if (user.isAdmin) 'admins',
        if (user.isTeacher && user.departmentId != null) 'dept_${user.departmentId!.id}',
      ];

  /// Requests permission, registers the device token and subscribes to topics.
  Future<void> registerUser(AppUser user) async {
    if (FirebaseConfig.useEmulator) return; // FCM is not emulated.
    try {
      await initLocal();
      final settings = await _fcm.requestPermission(alert: true, badge: true, sound: true);
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      await _fcm.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

      await _tokenSub?.cancel();
      _tokenSub = _fcm.onRegistered.listen((id) {
        _registrationId = id;
        _saveToken(user.id, id);
      });
      await _fcm.register();

      for (final topic in _topicsFor(user)) {
        await _fcm.subscribeToTopic(topic);
        _subscribedTopics.add(topic);
      }

      await _foregroundSub?.cancel();
      _foregroundSub = FirebaseMessaging.onMessage.listen((m) {
        final n = m.notification;
        if (n != null && defaultTargetPlatform == TargetPlatform.android) {
          showLocal(title: n.title ?? 'الوقار', body: n.body ?? '');
        }
      });
    } catch (e) {
      debugPrint('Push registration failed: $e');
    }
  }

  Future<void> _saveToken(String uid, String token) => _db.collection(Col.users).doc(uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });

  /// Called before sign-out so the device stops receiving this user's pushes.
  Future<void> unregister(String uid) async {
    if (FirebaseConfig.useEmulator) return;
    try {
      await _foregroundSub?.cancel();
      await _tokenSub?.cancel();
      for (final t in _subscribedTopics) {
        await _fcm.unsubscribeFromTopic(t);
      }
      _subscribedTopics.clear();
      final id = _registrationId;
      if (id != null) {
        await _db.collection(Col.users).doc(uid).update({
          'fcmTokens': FieldValue.arrayRemove([id]),
        });
      }
      _registrationId = null;
    } catch (e) {
      debugPrint('Push unregister failed: $e');
    }
  }
}
