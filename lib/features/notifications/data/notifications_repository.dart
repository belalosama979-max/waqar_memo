import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/firebase/json_converters.dart';
import '../../auth/domain/app_user.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.watch(firestoreProvider)),
);

/// Audience values: `all`, `dept_male`, `dept_female`, `admins`, `user` (with userId).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.audience,
    required this.type,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        title: (j['title'] as String?) ?? '',
        body: (j['body'] as String?) ?? '',
        audience: (j['audience'] as String?) ?? 'all',
        type: (j['type'] as String?) ?? 'announcement',
        createdAt: const TimestampConverter().fromJson(j['createdAt']),
      );

  final String id;
  final String title;
  final String body;
  final String audience;
  final String type;
  final DateTime? createdAt;

  String get audienceLabel => switch (audience) {
        'all' => 'الجميع',
        'dept_male' => 'قسم الذكور',
        'dept_female' => 'قسم الإناث',
        'admins' => 'الإدارة',
        'user' => 'خاص',
        _ => audience,
      };
}

class NotificationsRepository {
  NotificationsRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection(Col.notifications);

  List<AppNotification> _map(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map((d) => AppNotification.fromJson(docToJson(d))).toList();

  /// Notifications visible to [user]. Teachers combine three rule-provable queries.
  Stream<List<AppNotification>> watchFor(AppUser user, {int limit = 50}) {
    if (user.isAdmin) {
      return _col.orderBy('createdAt', descending: true).limit(limit).snapshots().map(_map);
    }
    final queries = [
      _col.where('audience', isEqualTo: 'all'),
      _col.where('audience', isEqualTo: 'dept_${user.departmentId!.id}'),
      _col.where('userId', isEqualTo: user.teacherKey),
    ].map((q) => q.orderBy('createdAt', descending: true).limit(limit).snapshots().map(_map)).toList();

    final controller = StreamController<List<AppNotification>>();
    final latest = List<List<AppNotification>?>.filled(queries.length, null);
    final subs = <StreamSubscription<List<AppNotification>>>[];
    void emit() {
      final merged = <String, AppNotification>{};
      for (final list in latest) {
        for (final n in list ?? const <AppNotification>[]) {
          merged[n.id] = n;
        }
      }
      final out = merged.values.toList()
        ..sort((a, b) => (b.createdAt ?? DateTime(2100)).compareTo(a.createdAt ?? DateTime(2100)));
      controller.add(out.take(limit).toList());
    }

    controller.onListen = () {
      for (var i = 0; i < queries.length; i++) {
        subs.add(queries[i].listen((v) {
          latest[i] = v;
          emit();
        }, onError: controller.addError));
      }
    };
    controller.onCancel = () async {
      for (final s in subs) {
        await s.cancel();
      }
    };
    return controller.stream;
  }

  /// Admin announcement. A Cloud Function fans it out via FCM.
  Future<void> sendAnnouncement({
    required String title,
    required String body,
    required String audience,
    required String adminId,
  }) async {
    try {
      await _col.add({
        'title': title.trim(),
        'body': body.trim(),
        'audience': audience,
        'type': 'announcement',
        'createdBy': adminId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _col.doc(id).delete();
    } catch (e) {
      throw AppFailure.from(e);
    }
  }
}

final notificationsProvider = StreamProvider.family<List<AppNotification>, AppUser>(
  (ref, user) => ref.watch(notificationsRepositoryProvider).watchFor(user),
);
