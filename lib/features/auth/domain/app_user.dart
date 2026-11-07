import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/firebase/json_converters.dart';
import 'enums.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

/// The signed-in account profile stored at `users/{uid}`.
@freezed
abstract class AppUser with _$AppUser {
  const AppUser._();

  const factory AppUser({
    required String id,
    required UserRole role,
    required String displayName,
    Department? departmentId,
    @Default(true) bool active,
    @Default(false) bool mustChangePassword,
    String? email,
    @TimestampConverter() DateTime? createdAt,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);

  bool get isAdmin => role == UserRole.admin;
  bool get isTeacher => role == UserRole.teacher;
}
