// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Student _$StudentFromJson(Map<String, dynamic> json) => _Student(
  id: json['id'] as String,
  fullName: json['fullName'] as String,
  teacherId: json['teacherId'] as String,
  teacherName: json['teacherName'] as String,
  departmentId: $enumDecode(_$DepartmentEnumMap, json['departmentId']),
  totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
  recitationCount: (json['recitationCount'] as num?)?.toInt() ?? 0,
  lastRecitationLabel: json['lastRecitationLabel'] as String?,
  lastRecitationDate: const TimestampConverter().fromJson(
    json['lastRecitationDate'],
  ),
  lastEvaluation: $enumDecodeNullable(
    _$EvaluationEnumMap,
    json['lastEvaluation'],
  ),
  lastRecitationId: json['lastRecitationId'] as String?,
  guardianPhone: json['guardianPhone'] as String?,
  notes: json['notes'] as String?,
  joinedAt: const TimestampConverter().fromJson(json['joinedAt']),
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
);

Map<String, dynamic> _$StudentToJson(_Student instance) => <String, dynamic>{
  'id': instance.id,
  'fullName': instance.fullName,
  'teacherId': instance.teacherId,
  'teacherName': instance.teacherName,
  'departmentId': _$DepartmentEnumMap[instance.departmentId]!,
  'totalPoints': instance.totalPoints,
  'recitationCount': instance.recitationCount,
  'lastRecitationLabel': instance.lastRecitationLabel,
  'lastRecitationDate': const TimestampConverter().toJson(
    instance.lastRecitationDate,
  ),
  'lastEvaluation': _$EvaluationEnumMap[instance.lastEvaluation],
  'lastRecitationId': instance.lastRecitationId,
  'guardianPhone': instance.guardianPhone,
  'notes': instance.notes,
  'joinedAt': const TimestampConverter().toJson(instance.joinedAt),
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
};

const _$DepartmentEnumMap = {
  Department.male: 'male',
  Department.female: 'female',
};

const _$EvaluationEnumMap = {
  Evaluation.excellentPlus: 'excellentPlus',
  Evaluation.excellent: 'excellent',
  Evaluation.veryGood: 'veryGood',
  Evaluation.notRecited: 'notRecited',
  Evaluation.repeat: 'repeat',
};
