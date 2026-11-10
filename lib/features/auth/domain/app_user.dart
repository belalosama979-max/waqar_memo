import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/firebase/json_converters.dart';
import 'enums.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

/// The signed-in account profile stored at `users/{authUid}`.
///
/// For teachers, [teacherId] points at `teachers/{teacherId}`: the teacher's
/// identity is separate from the login account, so the admin can issue a new
/// login (password reset) without touching students or history.
@freezed
abstract class AppUser with _$AppUser {
  const AppUser._();

  const factory AppUser({
    required String id,
    required UserRole role,
    required String displayName,
    Department? departmentId,
    String? teacherId,
    @Default(true) bool active,
    @Default(false) bool mustChangePassword,
    String? email,
    @TimestampConverter() DateTime? createdAt,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);

  bool get isAdmin => role == UserRole.admin;
  bool get isTeacher => role == UserRole.teacher;

  /// The id used on students/recitations for this teacher.
  String get teacherKey => teacherId ?? id;
}
