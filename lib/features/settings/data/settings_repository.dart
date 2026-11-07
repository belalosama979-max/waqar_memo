import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../recitations/domain/evaluation_settings.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(firestoreProvider)),
);

/// Live evaluation points (falls back to defaults when the doc is missing).
final evaluationSettingsProvider = StreamProvider<EvaluationSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).watchEvaluationSettings(),
);

final appSettingsProvider = StreamProvider<AppSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).watchAppSettings(),
);

class AppSettings {
  const AppSettings({this.academyName = 'حلقات الوقار', this.milestoneStep = 500});

  factory AppSettings.fromMap(Map<String, dynamic>? m) => AppSettings(
        academyName: (m?['academyName'] as String?)?.trim().isNotEmpty == true
            ? m!['academyName'] as String
            : 'حلقات الوقار',
        milestoneStep: (m?['milestoneStep'] as num?)?.toInt() ?? 500,
      );

  final String academyName;

  /// Teachers get a notification each time a student crosses this many points.
  final int milestoneStep;
}

class SettingsRepository {
  SettingsRepository(this._db);
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get _evalDoc => _db.collection(Col.evaluationSettings).doc('default');
  DocumentReference<Map<String, dynamic>> get _appDoc => _db.collection(Col.appSettings).doc('general');

  Stream<EvaluationSettings> watchEvaluationSettings() =>
      _evalDoc.snapshots().map((d) => EvaluationSettings.fromMap(d.data()));

  Future<void> saveEvaluationSettings(EvaluationSettings s) async {
    try {
      await _evalDoc.set({...s.toMap(), 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Stream<AppSettings> watchAppSettings() => _appDoc.snapshots().map((d) => AppSettings.fromMap(d.data()));

  Future<void> saveAppSettings({required String academyName, required int milestoneStep}) async {
    try {
      await _appDoc.set({
        'academyName': academyName.trim(),
        'milestoneStep': milestoneStep,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw AppFailure.from(e);
    }
  }
}
