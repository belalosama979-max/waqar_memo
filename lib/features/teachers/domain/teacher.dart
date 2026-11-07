import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/firebase/json_converters.dart';
import '../../auth/domain/enums.dart';

part 'teacher.freezed.dart';
part 'teacher.g.dart';

/// Teacher profile stored at `teachers/{uid}` (readable within the same department).
@freezed
abstract class Teacher with _$Teacher {
  const factory Teacher({
    required String id,
    required String displayName,
    required Department departmentId,
    @Default(true) bool active,
    @Default(0) int studentCount,
    String? phone,
    @TimestampConverter() DateTime? createdAt,
  }) = _Teacher;

  factory Teacher.fromJson(Map<String, dynamic> json) => _$TeacherFromJson(json);
}

/// Public login directory entry at `login_directory/{uid}`: only what the login
/// screen needs (name + department + the synthetic auth e-mail).
@freezed
abstract class LoginDirectoryEntry with _$LoginDirectoryEntry {
  const factory LoginDirectoryEntry({
    required String id,
    required String displayName,
    required Department departmentId,
    required String authEmail,
    @Default(true) bool active,
  }) = _LoginDirectoryEntry;

  factory LoginDirectoryEntry.fromJson(Map<String, dynamic> json) => _$LoginDirectoryEntryFromJson(json);
}
