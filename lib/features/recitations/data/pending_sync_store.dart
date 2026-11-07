import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/firebase/firebase_providers.dart';

/// A recitation written locally that the server has not acknowledged yet.
class PendingItem {
  const PendingItem({required this.id, required this.title, required this.queuedAt, this.error});

  factory PendingItem.fromJson(Map<String, dynamic> j) => PendingItem(
        id: j['id'] as String,
        title: j['title'] as String,
        queuedAt: DateTime.fromMillisecondsSinceEpoch(j['queuedAt'] as int),
        error: j['error'] as String?,
      );

  final String id;
  final String title;
  final DateTime queuedAt;
  final String? error;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'queuedAt': queuedAt.millisecondsSinceEpoch,
        if (error != null) 'error': error,
      };
}

class SyncSnapshot {
  const SyncSnapshot({this.pending = const [], this.failed = const []});
  final List<PendingItem> pending;
  final List<PendingItem> failed;
}

/// Persists the queue of unacknowledged / rejected recitation writes so the
/// sync status survives app restarts. Firestore itself persists and replays the
/// writes; this store only tracks them for the UI and reconciliation.
class PendingSyncStore extends Notifier<SyncSnapshot> {
  static const _kPending = 'sync.pending';
  static const _kFailed = 'sync.failed';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  List<PendingItem> get pendingItems => state.pending;

  @override
  SyncSnapshot build() => SyncSnapshot(pending: _read(_kPending), failed: _read(_kFailed));

  List<PendingItem> _read(String key) {
    final raw = _prefs.getStringList(key) ?? const [];
    return raw
        .map((s) {
          try {
            return PendingItem.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<PendingItem>()
        .toList();
  }

  Future<void> _write(List<PendingItem> pending, List<PendingItem> failed) async {
    state = SyncSnapshot(pending: pending, failed: failed);
    await _prefs.setStringList(_kPending, pending.map((e) => jsonEncode(e.toJson())).toList());
    await _prefs.setStringList(_kFailed, failed.map((e) => jsonEncode(e.toJson())).toList());
  }

  Future<void> markPending(String id, String title) async {
    if (state.pending.any((p) => p.id == id)) return;
    await _write([...state.pending, PendingItem(id: id, title: title, queuedAt: DateTime.now())], state.failed);
  }

  Future<void> markSynced(String id) async {
    await _write(state.pending.where((p) => p.id != id).toList(), state.failed.where((p) => p.id != id).toList());
  }

  Future<void> markFailed(String id, String error) async {
    final item = state.pending.where((p) => p.id == id).firstOrNull;
    final pending = state.pending.where((p) => p.id != id).toList();
    final failed = [
      ...state.failed.where((p) => p.id != id),
      PendingItem(id: id, title: item?.title ?? 'تسميع', queuedAt: item?.queuedAt ?? DateTime.now(), error: error),
    ];
    await _write(pending, failed);
  }

  Future<void> dismissFailed(String id) async {
    await _write(state.pending, state.failed.where((p) => p.id != id).toList());
  }
}

final pendingSyncStoreProvider = NotifierProvider<PendingSyncStore, SyncSnapshot>(PendingSyncStore.new);
