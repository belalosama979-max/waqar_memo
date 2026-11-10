// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppUser _$AppUserFromJson(Map<String, dynamic> json) => _AppUser(
  id: json['id'] as String,
  role: $enumDecode(_$UserRoleEnumMap, json['role']),
  displayName: json['displayName'] as String,
  departmentId: $enumDecodeNullable(_$DepartmentEnumMap, json['departmentId']),
  teacherId: json['teacherId'] as String?,
  active: json['active'] as bool? ?? true,
  mustChangePassword: json['mustChangePassword'] as bool? ?? false,
  email: json['email'] as String?,
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
);

Map<String, dynamic> _$AppUserToJson(_AppUser instance) => <String, dynamic>{
  'id': instance.id,
  'role': _$UserRoleEnumMap[instance.role]!,
  'displayName': instance.displayName,
  'departmentId': _$DepartmentEnumMap[instance.departmentId],
  'teacherId': instance.teacherId,
  'active': instance.active,
  'mustChangePassword': instance.mustChangePassword,
  'email': instance.email,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
};

const _$UserRoleEnumMap = {
  UserRole.admin: 'admin',
  UserRole.teacher: 'teacher',
};

const _$DepartmentEnumMap = {
  Department.male: 'male',
  Department.female: 'female',
};
