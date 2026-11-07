import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/firebase/json_converters.dart';
import '../../auth/domain/enums.dart';
import '../../recitations/domain/evaluation.dart';

part 'student.freezed.dart';
part 'student.g.dart';

/// Student document at `students/{id}`.
@freezed
abstract class Student with _$Student {
  const factory Student({
    required String id,
    required String fullName,
    required String teacherId,
    required String teacherName,
    required Department departmentId,
    @Default(0) int totalPoints,
    @Default(0) int recitationCount,
    String? lastRecitationLabel,
    @TimestampConverter() DateTime? lastRecitationDate,
    Evaluation? lastEvaluation,
    String? lastRecitationId,
    String? guardianPhone,
    String? notes,
    @TimestampConverter() DateTime? joinedAt,
    @TimestampConverter() DateTime? createdAt,
  }) = _Student;

  factory Student.fromJson(Map<String, dynamic> json) => _$StudentFromJson(json);
}
