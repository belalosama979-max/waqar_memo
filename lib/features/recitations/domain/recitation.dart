import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/constants/quran_data.dart';
import '../../../core/firebase/json_converters.dart';
import '../../auth/domain/enums.dart';
import 'evaluation.dart';

part 'recitation.freezed.dart';
part 'recitation.g.dart';

/// Immutable recitation record at `recitations/{id}`. Teacher/department fields
/// are snapshotted at creation time so history stays accurate after transfers.
@freezed
abstract class Recitation with _$Recitation {
  const Recitation._();

  const factory Recitation({
    required String id,
    required String studentId,
    required String studentName,
    required String teacherId,
    required String teacherName,
    required Department departmentId,
    @TimestampConverter() required DateTime? recitationDate,
    required RecitationType recitationType,
    int? partNumber,
    int? surahNumber,
    required Evaluation evaluation,
    required int evaluationPoints,
    @Default(0) int extraPoints,
    required int totalPoints,
    @TimestampConverter() DateTime? createdAt,
    @JsonKey(includeFromJson: false, includeToJson: false) @Default(false) bool pendingSync,
  }) = _Recitation;

  factory Recitation.fromJson(Map<String, dynamic> json) => _$RecitationFromJson(json);

  /// Human readable portion, e.g. "سورة الملك" or "الجزء الثلاثون".
  String get portionLabel => describePortion(recitationType, partNumber: partNumber, surahNumber: surahNumber);

  static String describePortion(RecitationType type, {int? partNumber, int? surahNumber}) {
    switch (type) {
      case RecitationType.juz:
        if (partNumber == null || partNumber < 1 || partNumber > QuranData.juzCount) return 'جزء';
        return QuranData.juzName(partNumber);
      case RecitationType.surah:
        if (surahNumber == null || surahNumber < 1 || surahNumber > QuranData.surahCount) return 'سورة';
        return 'سورة ${QuranData.surahName(surahNumber)}';
    }
  }
}
