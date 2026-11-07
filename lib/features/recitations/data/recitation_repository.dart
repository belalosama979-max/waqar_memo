import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/firebase/json_converters.dart';
import '../../../core/constants/quran_data.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/enums.dart';
import '../../students/domain/student.dart';
import '../domain/evaluation.dart';
import '../domain/evaluation_settings.dart';
import '../domain/points_calculator.dart';
import '../domain/recitation.dart';
import 'pending_sync_store.dart';

final recitationRepositoryProvider = Provider<RecitationRepository>(
  (ref) => RecitationRepository(ref.watch(firestoreProvider), ref.read(pendingSyncStoreProvider.notifier)),
);

enum SubmitOutcome { synced, queued }

/// Everything the teacher entered in the recitation form. [id] is generated once
/// per form so retries and double taps can never create duplicates.
class RecitationDraft {
  const RecitationDraft({
    required this.id,
    required this.student,
    required this.date,
    required this.type,
    this.partNumber,
    this.surahNumber,
    required this.evaluation,
    required this.extraPoints,
  });

  final String id;
  final Student student;
  final DateTime date;
  final RecitationType type;
  final int? partNumber;
  final int? surahNumber;
  final Evaluation evaluation;
  final int extraPoints;

  String get portionLabel => Recitation.describePortion(type, partNumber: partNumber, surahNumber: surahNumber);
}

class RecitationRepository {
  RecitationRepository(this._db, this._pending, {this.ackTimeout = const Duration(seconds: 6)});

  final FirebaseFirestore _db;
  final PendingSyncStore _pending;
  final Duration ackTimeout;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection(Col.recitations);

  /// Validates a draft against business rules. Returns an Arabic message or null.
  static String? validate(RecitationDraft d, {required AppUser teacher, required EvaluationSettings settings, DateTime? now}) {
    final today = now ?? DateTime.now();
    if (d.student.teacherId != teacher.id) return 'هذا الطالب غير مسجل لديك';
    if (d.student.departmentId != teacher.departmentId) return 'لا يمكن التسجيل لطالب من قسم آخر';
    if (d.type == RecitationType.juz) {
      final p = d.partNumber;
      if (p == null || p < 1 || p > QuranData.juzCount) return 'يرجى اختيار الجزء';
    } else {
      final s = d.surahNumber;
      if (s == null || s < 1 || s > QuranData.surahCount) return 'يرجى اختيار السورة';
    }
    if (d.extraPoints < 0) return 'لا يمكن أن تكون الكمية الإضافية سالبة';
    if (d.extraPoints > settings.maxExtraPoints) return 'الكمية الإضافية تتجاوز الحد المسموح';
    final endOfToday = DateTime(today.year, today.month, today.day, 23, 59, 59);
    if (d.date.isAfter(endOfToday)) return 'لا يمكن تسجيل تسميع بتاريخ مستقبلي';
    if (d.date.isBefore(today.subtract(const Duration(days: 365)))) return 'التاريخ قديم جداً';
    return null;
  }

  /// Writes the recitation and the student's aggregate atomically.
  ///
  /// Works offline: Firestore queues the batch locally and replays it when the
  /// connection returns. Returns [SubmitOutcome.queued] if the server did not
  /// acknowledge within [ackTimeout]; the [PendingSyncStore] then tracks it.
  Future<SubmitOutcome> submit(
    RecitationDraft d, {
    required AppUser teacher,
    required EvaluationSettings settings,
  }) async {
    final error = validate(d, teacher: teacher, settings: settings);
    if (error != null) throw AppFailure(error, code: 'invalid-argument');

    final pts = PointsCalculator.calculate(evaluation: d.evaluation, extraPoints: d.extraPoints, settings: settings);
    final recitationDate = DateTime(d.date.year, d.date.month, d.date.day, 12);
    final isNewest = d.student.lastRecitationDate == null || !recitationDate.isBefore(d.student.lastRecitationDate!);

    final batch = _db.batch();
    batch.set(_col.doc(d.id), {
      'studentId': d.student.id,
      'studentName': d.student.fullName,
      'teacherId': teacher.id,
      'teacherName': teacher.displayName,
      'departmentId': teacher.departmentId!.id,
      'recitationDate': Timestamp.fromDate(recitationDate),
      'recitationType': d.type.name,
      'partNumber': d.type == RecitationType.juz ? d.partNumber : null,
      'surahNumber': d.type == RecitationType.surah ? d.surahNumber : null,
      'evaluation': d.evaluation.name,
      'evaluationPoints': pts.evaluationPoints,
      'extraPoints': pts.extraPoints,
      'totalPoints': pts.total,
      'createdBy': teacher.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection(Col.students).doc(d.student.id), {
      'totalPoints': FieldValue.increment(pts.total),
      'recitationCount': FieldValue.increment(1),
      'lastAppliedRecitationId': d.id,
      'updatedAt': FieldValue.serverTimestamp(),
      if (isNewest) ...{
        'lastRecitationId': d.id,
        'lastRecitationLabel': d.portionLabel,
        'lastRecitationDate': Timestamp.fromDate(recitationDate),
        'lastEvaluation': d.evaluation.name,
      },
    });

    final title = '${d.student.fullName} — ${d.portionLabel}';
    await _pending.markPending(d.id, title);
    final commit = batch.commit();
    try {
      await commit.timeout(ackTimeout);
      await _pending.markSynced(d.id);
      return SubmitOutcome.synced;
    } on TimeoutException {
      // Still queued in Firestore's local cache; track the eventual result.
      unawaited(commit.then(
        (_) => _pending.markSynced(d.id),
        onError: (Object e) => _pending.markFailed(d.id, AppFailure.from(e).message),
      ));
      return SubmitOutcome.queued;
    } catch (e) {
      await _pending.markSynced(d.id);
      throw AppFailure.from(e);
    }
  }

  /// After a restart, confirms which tracked writes reached the server.
  Future<void> reconcilePending() async {
    final items = [..._pending.pendingItems];
    if (items.isEmpty) return;
    try {
      await _db.waitForPendingWrites().timeout(const Duration(seconds: 20));
    } catch (_) {
      return; // still offline; try again later
    }
    for (final item in items) {
      try {
        final doc = await _col.doc(item.id).get(const GetOptions(source: Source.server));
        if (doc.exists) {
          await _pending.markSynced(item.id);
        } else {
          await _pending.markFailed(item.id, 'رفض الخادم حفظ هذا التسميع، يرجى تسجيله مجدداً');
        }
      } catch (e) {
        debugPrint('reconcile ${item.id}: $e');
      }
    }
  }

  List<Recitation> _map(QuerySnapshot<Map<String, dynamic>> s) => s.docs
      .map((d) => Recitation.fromJson(docToJson(d)).copyWith(pendingSync: d.metadata.hasPendingWrites))
      .toList();

  /// Full history of one student (newest first), paginated by [limit].
  Stream<List<Recitation>> watchStudentHistory({
    required String studentId,
    required Department department,
    int limit = 30,
  }) {
    return _col
        .where('departmentId', isEqualTo: department.id)
        .where('studentId', isEqualTo: studentId)
        .orderBy('recitationDate', descending: true)
        .limit(limit)
        .snapshots(includeMetadataChanges: true)
        .map(_map);
  }

  /// Recitations since [since] for analytics, scoped by department / teacher.
  Stream<List<Recitation>> watchRecent({
    Department? department,
    String? teacherId,
    required DateTime since,
    int limit = 2000,
  }) {
    Query<Map<String, dynamic>> q = _col;
    if (department != null) q = q.where('departmentId', isEqualTo: department.id);
    if (teacherId != null) q = q.where('teacherId', isEqualTo: teacherId);
    q = q
        .where('recitationDate', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('recitationDate', descending: true)
        .limit(limit);
    return q.snapshots(includeMetadataChanges: true).map(_map);
  }

  /// Admin: cursor-paginated list of all recitations (newest first).
  Future<({List<Recitation> items, DocumentSnapshot<Map<String, dynamic>>? cursor, bool hasMore})> fetchPage({
    Department? department,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int pageSize = 25,
  }) async {
    try {
      Query<Map<String, dynamic>> q = _col;
      if (department != null) q = q.where('departmentId', isEqualTo: department.id);
      q = q.orderBy('recitationDate', descending: true).limit(pageSize);
      if (startAfter != null) q = q.startAfterDocument(startAfter);
      final snap = await q.get();
      return (
        items: _map(snap),
        cursor: snap.docs.isEmpty ? startAfter : snap.docs.last,
        hasMore: snap.docs.length == pageSize,
      );
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<int> countAll({Department? department}) async {
    Query<Map<String, dynamic>> q = _col;
    if (department != null) q = q.where('departmentId', isEqualTo: department.id);
    final agg = await q.count().get();
    return agg.count ?? 0;
  }

  /// Admin only: removes a record and reverses its points on the student.
  Future<void> deleteRecitation(Recitation r) async {
    try {
      final studentRef = _db.collection(Col.students).doc(r.studentId);
      await _db.runTransaction((tx) async {
        final student = await tx.get(studentRef);
        tx.delete(_col.doc(r.id));
        if (student.exists) {
          tx.update(studentRef, {
            'totalPoints': FieldValue.increment(-r.totalPoints),
            'recitationCount': FieldValue.increment(-1),
            'updatedAt': FieldValue.serverTimestamp(),
            if (student.data()?['lastRecitationId'] == r.id) ...{
              'lastRecitationId': null,
              'lastRecitationLabel': null,
              'lastRecitationDate': null,
              'lastEvaluation': null,
            },
          });
        }
      });
    } catch (e) {
      throw AppFailure.from(e);
    }
  }
}
