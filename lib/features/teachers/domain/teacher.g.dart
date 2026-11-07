// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Teacher _$TeacherFromJson(Map<String, dynamic> json) => _Teacher(
  id: json['id'] as String,
  displayName: json['displayName'] as String,
  departmentId: $enumDecode(_$DepartmentEnumMap, json['departmentId']),
  active: json['active'] as bool? ?? true,
  studentCount: (json['studentCount'] as num?)?.toInt() ?? 0,
  phone: json['phone'] as String?,
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
);

Map<String, dynamic> _$TeacherToJson(_Teacher instance) => <String, dynamic>{
  'id': instance.id,
  'displayName': instance.displayName,
  'departmentId': _$DepartmentEnumMap[instance.departmentId]!,
  'active': instance.active,
  'studentCount': instance.studentCount,
  'phone': instance.phone,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
};

const _$DepartmentEnumMap = {
  Department.male: 'male',
  Department.female: 'female',
};

_LoginDirectoryEntry _$LoginDirectoryEntryFromJson(Map<String, dynamic> json) =>
    _LoginDirectoryEntry(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      departmentId: $enumDecode(_$DepartmentEnumMap, json['departmentId']),
      authEmail: json['authEmail'] as String,
      active: json['active'] as bool? ?? true,
    );

Map<String, dynamic> _$LoginDirectoryEntryToJson(
  _LoginDirectoryEntry instance,
) => <String, dynamic>{
  'id': instance.id,
  'displayName': instance.displayName,
  'departmentId': _$DepartmentEnumMap[instance.departmentId]!,
  'authEmail': instance.authEmail,
  'active': instance.active,
};
