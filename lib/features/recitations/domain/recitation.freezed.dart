// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recitation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Recitation {

 String get id; String get studentId; String get studentName; String get teacherId; String get teacherName; Department get departmentId;@TimestampConverter() DateTime? get recitationDate; RecitationType get recitationType; int? get partNumber; int? get surahNumber; Evaluation get evaluation; int get evaluationPoints; int get extraPoints; int get totalPoints;@TimestampConverter() DateTime? get createdAt;@JsonKey(includeFromJson: false, includeToJson: false) bool get pendingSync;
/// Create a copy of Recitation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecitationCopyWith<Recitation> get copyWith => _$RecitationCopyWithImpl<Recitation>(this as Recitation, _$identity);

  /// Serializes this Recitation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Recitation&&(identical(other.id, id) || other.id == id)&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.studentName, studentName) || other.studentName == studentName)&&(identical(other.teacherId, teacherId) || other.teacherId == teacherId)&&(identical(other.teacherName, teacherName) || other.teacherName == teacherName)&&(identical(other.departmentId, departmentId) || other.departmentId == departmentId)&&(identical(other.recitationDate, recitationDate) || other.recitationDate == recitationDate)&&(identical(other.recitationType, recitationType) || other.recitationType == recitationType)&&(identical(other.partNumber, partNumber) || other.partNumber == partNumber)&&(identical(other.surahNumber, surahNumber) || other.surahNumber == surahNumber)&&(identical(other.evaluation, evaluation) || other.evaluation == evaluation)&&(identical(other.evaluationPoints, evaluationPoints) || other.evaluationPoints == evaluationPoints)&&(identical(other.extraPoints, extraPoints) || other.extraPoints == extraPoints)&&(identical(other.totalPoints, totalPoints) || other.totalPoints == totalPoints)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.pendingSync, pendingSync) || other.pendingSync == pendingSync));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,studentId,studentName,teacherId,teacherName,departmentId,recitationDate,recitationType,partNumber,surahNumber,evaluation,evaluationPoints,extraPoints,totalPoints,createdAt,pendingSync);

@override
String toString() {
  return 'Recitation(id: $id, studentId: $studentId, studentName: $studentName, teacherId: $teacherId, teacherName: $teacherName, departmentId: $departmentId, recitationDate: $recitationDate, recitationType: $recitationType, partNumber: $partNumber, surahNumber: $surahNumber, evaluation: $evaluation, evaluationPoints: $evaluationPoints, extraPoints: $extraPoints, totalPoints: $totalPoints, createdAt: $createdAt, pendingSync: $pendingSync)';
}


}

/// @nodoc
abstract mixin class $RecitationCopyWith<$Res>  {
  factory $RecitationCopyWith(Recitation value, $Res Function(Recitation) _then) = _$RecitationCopyWithImpl;
@useResult
$Res call({
 String id, String studentId, String studentName, String teacherId, String teacherName, Department departmentId,@TimestampConverter() DateTime? recitationDate, RecitationType recitationType, int? partNumber, int? surahNumber, Evaluation evaluation, int evaluationPoints, int extraPoints, int totalPoints,@TimestampConverter() DateTime? createdAt,@JsonKey(includeFromJson: false, includeToJson: false) bool pendingSync
});




}
/// @nodoc
class _$RecitationCopyWithImpl<$Res>
    implements $RecitationCopyWith<$Res> {
  _$RecitationCopyWithImpl(this._self, this._then);

  final Recitation _self;
  final $Res Function(Recitation) _then;

/// Create a copy of Recitation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? studentId = null,Object? studentName = null,Object? teacherId = null,Object? teacherName = null,Object? departmentId = null,Object? recitationDate = freezed,Object? recitationType = null,Object? partNumber = freezed,Object? surahNumber = freezed,Object? evaluation = null,Object? evaluationPoints = null,Object? extraPoints = null,Object? totalPoints = null,Object? createdAt = freezed,Object? pendingSync = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,studentName: null == studentName ? _self.studentName : studentName // ignore: cast_nullable_to_non_nullable
as String,teacherId: null == teacherId ? _self.teacherId : teacherId // ignore: cast_nullable_to_non_nullable
as String,teacherName: null == teacherName ? _self.teacherName : teacherName // ignore: cast_nullable_to_non_nullable
as String,departmentId: null == departmentId ? _self.departmentId : departmentId // ignore: cast_nullable_to_non_nullable
as Department,recitationDate: freezed == recitationDate ? _self.recitationDate : recitationDate // ignore: cast_nullable_to_non_nullable
as DateTime?,recitationType: null == recitationType ? _self.recitationType : recitationType // ignore: cast_nullable_to_non_nullable
as RecitationType,partNumber: freezed == partNumber ? _self.partNumber : partNumber // ignore: cast_nullable_to_non_nullable
as int?,surahNumber: freezed == surahNumber ? _self.surahNumber : surahNumber // ignore: cast_nullable_to_non_nullable
as int?,evaluation: null == evaluation ? _self.evaluation : evaluation // ignore: cast_nullable_to_non_nullable
as Evaluation,evaluationPoints: null == evaluationPoints ? _self.evaluationPoints : evaluationPoints // ignore: cast_nullable_to_non_nullable
as int,extraPoints: null == extraPoints ? _self.extraPoints : extraPoints // ignore: cast_nullable_to_non_nullable
as int,totalPoints: null == totalPoints ? _self.totalPoints : totalPoints // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,pendingSync: null == pendingSync ? _self.pendingSync : pendingSync // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Recitation].
extension RecitationPatterns on Recitation {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Recitation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Recitation() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Recitation value)  $default,){
final _that = this;
switch (_that) {
case _Recitation():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Recitation value)?  $default,){
final _that = this;
switch (_that) {
case _Recitation() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String studentId,  String studentName,  String teacherId,  String teacherName,  Department departmentId, @TimestampConverter()  DateTime? recitationDate,  RecitationType recitationType,  int? partNumber,  int? surahNumber,  Evaluation evaluation,  int evaluationPoints,  int extraPoints,  int totalPoints, @TimestampConverter()  DateTime? createdAt, @JsonKey(includeFromJson: false, includeToJson: false)  bool pendingSync)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Recitation() when $default != null:
return $default(_that.id,_that.studentId,_that.studentName,_that.teacherId,_that.teacherName,_that.departmentId,_that.recitationDate,_that.recitationType,_that.partNumber,_that.surahNumber,_that.evaluation,_that.evaluationPoints,_that.extraPoints,_that.totalPoints,_that.createdAt,_that.pendingSync);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String studentId,  String studentName,  String teacherId,  String teacherName,  Department departmentId, @TimestampConverter()  DateTime? recitationDate,  RecitationType recitationType,  int? partNumber,  int? surahNumber,  Evaluation evaluation,  int evaluationPoints,  int extraPoints,  int totalPoints, @TimestampConverter()  DateTime? createdAt, @JsonKey(includeFromJson: false, includeToJson: false)  bool pendingSync)  $default,) {final _that = this;
switch (_that) {
case _Recitation():
return $default(_that.id,_that.studentId,_that.studentName,_that.teacherId,_that.teacherName,_that.departmentId,_that.recitationDate,_that.recitationType,_that.partNumber,_that.surahNumber,_that.evaluation,_that.evaluationPoints,_that.extraPoints,_that.totalPoints,_that.createdAt,_that.pendingSync);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String studentId,  String studentName,  String teacherId,  String teacherName,  Department departmentId, @TimestampConverter()  DateTime? recitationDate,  RecitationType recitationType,  int? partNumber,  int? surahNumber,  Evaluation evaluation,  int evaluationPoints,  int extraPoints,  int totalPoints, @TimestampConverter()  DateTime? createdAt, @JsonKey(includeFromJson: false, includeToJson: false)  bool pendingSync)?  $default,) {final _that = this;
switch (_that) {
case _Recitation() when $default != null:
return $default(_that.id,_that.studentId,_that.studentName,_that.teacherId,_that.teacherName,_that.departmentId,_that.recitationDate,_that.recitationType,_that.partNumber,_that.surahNumber,_that.evaluation,_that.evaluationPoints,_that.extraPoints,_that.totalPoints,_that.createdAt,_that.pendingSync);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Recitation extends Recitation {
  const _Recitation({required this.id, required this.studentId, required this.studentName, required this.teacherId, required this.teacherName, required this.departmentId, @TimestampConverter() required this.recitationDate, required this.recitationType, this.partNumber, this.surahNumber, required this.evaluation, required this.evaluationPoints, this.extraPoints = 0, required this.totalPoints, @TimestampConverter() this.createdAt, @JsonKey(includeFromJson: false, includeToJson: false) this.pendingSync = false}): super._();
  factory _Recitation.fromJson(Map<String, dynamic> json) => _$RecitationFromJson(json);

@override final  String id;
@override final  String studentId;
@override final  String studentName;
@override final  String teacherId;
@override final  String teacherName;
@override final  Department departmentId;
@override@TimestampConverter() final  DateTime? recitationDate;
@override final  RecitationType recitationType;
@override final  int? partNumber;
@override final  int? surahNumber;
@override final  Evaluation evaluation;
@override final  int evaluationPoints;
@override@JsonKey() final  int extraPoints;
@override final  int totalPoints;
@override@TimestampConverter() final  DateTime? createdAt;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  bool pendingSync;

/// Create a copy of Recitation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecitationCopyWith<_Recitation> get copyWith => __$RecitationCopyWithImpl<_Recitation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecitationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Recitation&&(identical(other.id, id) || other.id == id)&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.studentName, studentName) || other.studentName == studentName)&&(identical(other.teacherId, teacherId) || other.teacherId == teacherId)&&(identical(other.teacherName, teacherName) || other.teacherName == teacherName)&&(identical(other.departmentId, departmentId) || other.departmentId == departmentId)&&(identical(other.recitationDate, recitationDate) || other.recitationDate == recitationDate)&&(identical(other.recitationType, recitationType) || other.recitationType == recitationType)&&(identical(other.partNumber, partNumber) || other.partNumber == partNumber)&&(identical(other.surahNumber, surahNumber) || other.surahNumber == surahNumber)&&(identical(other.evaluation, evaluation) || other.evaluation == evaluation)&&(identical(other.evaluationPoints, evaluationPoints) || other.evaluationPoints == evaluationPoints)&&(identical(other.extraPoints, extraPoints) || other.extraPoints == extraPoints)&&(identical(other.totalPoints, totalPoints) || other.totalPoints == totalPoints)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.pendingSync, pendingSync) || other.pendingSync == pendingSync));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,studentId,studentName,teacherId,teacherName,departmentId,recitationDate,recitationType,partNumber,surahNumber,evaluation,evaluationPoints,extraPoints,totalPoints,createdAt,pendingSync);

@override
String toString() {
  return 'Recitation(id: $id, studentId: $studentId, studentName: $studentName, teacherId: $teacherId, teacherName: $teacherName, departmentId: $departmentId, recitationDate: $recitationDate, recitationType: $recitationType, partNumber: $partNumber, surahNumber: $surahNumber, evaluation: $evaluation, evaluationPoints: $evaluationPoints, extraPoints: $extraPoints, totalPoints: $totalPoints, createdAt: $createdAt, pendingSync: $pendingSync)';
}


}

/// @nodoc
abstract mixin class _$RecitationCopyWith<$Res> implements $RecitationCopyWith<$Res> {
  factory _$RecitationCopyWith(_Recitation value, $Res Function(_Recitation) _then) = __$RecitationCopyWithImpl;
@override @useResult
$Res call({
 String id, String studentId, String studentName, String teacherId, String teacherName, Department departmentId,@TimestampConverter() DateTime? recitationDate, RecitationType recitationType, int? partNumber, int? surahNumber, Evaluation evaluation, int evaluationPoints, int extraPoints, int totalPoints,@TimestampConverter() DateTime? createdAt,@JsonKey(includeFromJson: false, includeToJson: false) bool pendingSync
});




}
/// @nodoc
class __$RecitationCopyWithImpl<$Res>
    implements _$RecitationCopyWith<$Res> {
  __$RecitationCopyWithImpl(this._self, this._then);

  final _Recitation _self;
  final $Res Function(_Recitation) _then;

/// Create a copy of Recitation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? studentId = null,Object? studentName = null,Object? teacherId = null,Object? teacherName = null,Object? departmentId = null,Object? recitationDate = freezed,Object? recitationType = null,Object? partNumber = freezed,Object? surahNumber = freezed,Object? evaluation = null,Object? evaluationPoints = null,Object? extraPoints = null,Object? totalPoints = null,Object? createdAt = freezed,Object? pendingSync = null,}) {
  return _then(_Recitation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,studentName: null == studentName ? _self.studentName : studentName // ignore: cast_nullable_to_non_nullable
as String,teacherId: null == teacherId ? _self.teacherId : teacherId // ignore: cast_nullable_to_non_nullable
as String,teacherName: null == teacherName ? _self.teacherName : teacherName // ignore: cast_nullable_to_non_nullable
as String,departmentId: null == departmentId ? _self.departmentId : departmentId // ignore: cast_nullable_to_non_nullable
as Department,recitationDate: freezed == recitationDate ? _self.recitationDate : recitationDate // ignore: cast_nullable_to_non_nullable
as DateTime?,recitationType: null == recitationType ? _self.recitationType : recitationType // ignore: cast_nullable_to_non_nullable
as RecitationType,partNumber: freezed == partNumber ? _self.partNumber : partNumber // ignore: cast_nullable_to_non_nullable
as int?,surahNumber: freezed == surahNumber ? _self.surahNumber : surahNumber // ignore: cast_nullable_to_non_nullable
as int?,evaluation: null == evaluation ? _self.evaluation : evaluation // ignore: cast_nullable_to_non_nullable
as Evaluation,evaluationPoints: null == evaluationPoints ? _self.evaluationPoints : evaluationPoints // ignore: cast_nullable_to_non_nullable
as int,extraPoints: null == extraPoints ? _self.extraPoints : extraPoints // ignore: cast_nullable_to_non_nullable
as int,totalPoints: null == totalPoints ? _self.totalPoints : totalPoints // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,pendingSync: null == pendingSync ? _self.pendingSync : pendingSync // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
