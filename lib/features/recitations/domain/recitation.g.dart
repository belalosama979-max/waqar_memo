// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recitation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Recitation _$RecitationFromJson(Map<String, dynamic> json) => _Recitation(
  id: json['id'] as String,
  studentId: json['studentId'] as String,
  studentName: json['studentName'] as String,
  teacherId: json['teacherId'] as String,
  teacherName: json['teacherName'] as String,
  departmentId: $enumDecode(_$DepartmentEnumMap, json['departmentId']),
  recitationDate: const TimestampConverter().fromJson(json['recitationDate']),
  recitationType: $enumDecode(_$RecitationTypeEnumMap, json['recitationType']),
  partNumber: (json['partNumber'] as num?)?.toInt(),
  surahNumber: (json['surahNumber'] as num?)?.toInt(),
  evaluation: $enumDecode(_$EvaluationEnumMap, json['evaluation']),
  evaluationPoints: (json['evaluationPoints'] as num).toInt(),
  extraPoints: (json['extraPoints'] as num?)?.toInt() ?? 0,
  totalPoints: (json['totalPoints'] as num).toInt(),
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
);

Map<String, dynamic> _$RecitationToJson(
  _Recitation instance,
) => <String, dynamic>{
  'id': instance.id,
  'studentId': instance.studentId,
  'studentName': instance.studentName,
  'teacherId': instance.teacherId,
  'teacherName': instance.teacherName,
  'departmentId': _$DepartmentEnumMap[instance.departmentId]!,
  'recitationDate': const TimestampConverter().toJson(instance.recitationDate),
  'recitationType': _$RecitationTypeEnumMap[instance.recitationType]!,
  'partNumber': instance.partNumber,
  'surahNumber': instance.surahNumber,
  'evaluation': _$EvaluationEnumMap[instance.evaluation]!,
  'evaluationPoints': instance.evaluationPoints,
  'extraPoints': instance.extraPoints,
  'totalPoints': instance.totalPoints,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
};

const _$DepartmentEnumMap = {
  Department.male: 'male',
  Department.female: 'female',
};

const _$RecitationTypeEnumMap = {
  RecitationType.juz: 'juz',
  RecitationType.surah: 'surah',
};

const _$EvaluationEnumMap = {
  Evaluation.excellentPlus: 'excellentPlus',
  Evaluation.excellent: 'excellent',
  Evaluation.veryGood: 'veryGood',
  Evaluation.notRecited: 'notRecited',
  Evaluation.repeat: 'repeat',
};
