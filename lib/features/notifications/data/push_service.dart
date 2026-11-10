import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/firebase/firebase_providers.dart';
import 'notifications_repository.dart';

final localNotificationsProvider = Provider<FlutterLocalNotificationsPlugin>(
  (ref) => FlutterLocalNotificationsPlugin(),
);

final pushServiceProvider = Provider<PushService>(
  (ref) => PushService(ref.watch(localNotificationsProvider), ref.watch(sharedPreferencesProvider)),
);

/// Device alerts on the Firebase free plan (no server to send push messages).
///
/// In-app notifications live in Firestore; while the app is running, new ones
/// (announcements, milestones) are also shown as a phone notification.
class PushService {
  PushService(this._local, this._prefs);

  final FlutterLocalNotificationsPlugin _local;
  final SharedPreferences _prefs;

  static const channel = AndroidNotificationChannel(
    'alwaqar_general',
    'إشعارات الوقار',
    description: 'التنبيهات والإعلانات الخاصة بالتسميع',
    importance: Importance.high,
  );

  bool _initialized = false;

  Future<void> initLocal() async {
    if (_initialized) return;
    _initialized = true;
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    final android = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(channel);
  }

  /// Asks for notification permission once a user is signed in.
  Future<void> registerUser() async {
    try {
      await initLocal();
      await _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _local
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }
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

  static String _seenKey(String userId) => 'notifications.lastSeen.$userId';

  /// Shows a phone alert for notifications newer than the last one seen on
  /// this device. The first load only records the baseline (no alert burst).
  Future<void> alertNew(String userId, List<AppNotification> list) async {
    final key = _seenKey(userId);
    final dated = list.where((n) => n.createdAt != null).toList();
    if (dated.isEmpty) return;
    final newest = dated.map((n) => n.createdAt!).reduce((a, b) => a.isAfter(b) ? a : b);
    final lastSeenMs = _prefs.getInt(key);
    await _prefs.setInt(key, newest.millisecondsSinceEpoch);
    if (lastSeenMs == null) return;
    final lastSeen = DateTime.fromMillisecondsSinceEpoch(lastSeenMs);
    final fresh = dated.where((n) => n.createdAt!.isAfter(lastSeen)).take(3);
    for (final n in fresh) {
      await showLocal(title: n.title, body: n.body);
    }
  }
}
