// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'student.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Student {

 String get id; String get fullName; String get teacherId; String get teacherName; Department get departmentId; int get totalPoints; int get recitationCount; String? get lastRecitationLabel;@TimestampConverter() DateTime? get lastRecitationDate; Evaluation? get lastEvaluation; String? get lastRecitationId; String? get guardianPhone; String? get notes;@TimestampConverter() DateTime? get joinedAt;@TimestampConverter() DateTime? get createdAt;
/// Create a copy of Student
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudentCopyWith<Student> get copyWith => _$StudentCopyWithImpl<Student>(this as Student, _$identity);

  /// Serializes this Student to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Student&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.teacherId, teacherId) || other.teacherId == teacherId)&&(identical(other.teacherName, teacherName) || other.teacherName == teacherName)&&(identical(other.departmentId, departmentId) || other.departmentId == departmentId)&&(identical(other.totalPoints, totalPoints) || other.totalPoints == totalPoints)&&(identical(other.recitationCount, recitationCount) || other.recitationCount == recitationCount)&&(identical(other.lastRecitationLabel, lastRecitationLabel) || other.lastRecitationLabel == lastRecitationLabel)&&(identical(other.lastRecitationDate, lastRecitationDate) || other.lastRecitationDate == lastRecitationDate)&&(identical(other.lastEvaluation, lastEvaluation) || other.lastEvaluation == lastEvaluation)&&(identical(other.lastRecitationId, lastRecitationId) || other.lastRecitationId == lastRecitationId)&&(identical(other.guardianPhone, guardianPhone) || other.guardianPhone == guardianPhone)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,teacherId,teacherName,departmentId,totalPoints,recitationCount,lastRecitationLabel,lastRecitationDate,lastEvaluation,lastRecitationId,guardianPhone,notes,joinedAt,createdAt);

@override
String toString() {
  return 'Student(id: $id, fullName: $fullName, teacherId: $teacherId, teacherName: $teacherName, departmentId: $departmentId, totalPoints: $totalPoints, recitationCount: $recitationCount, lastRecitationLabel: $lastRecitationLabel, lastRecitationDate: $lastRecitationDate, lastEvaluation: $lastEvaluation, lastRecitationId: $lastRecitationId, guardianPhone: $guardianPhone, notes: $notes, joinedAt: $joinedAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $StudentCopyWith<$Res>  {
  factory $StudentCopyWith(Student value, $Res Function(Student) _then) = _$StudentCopyWithImpl;
@useResult
$Res call({
 String id, String fullName, String teacherId, String teacherName, Department departmentId, int totalPoints, int recitationCount, String? lastRecitationLabel,@TimestampConverter() DateTime? lastRecitationDate, Evaluation? lastEvaluation, String? lastRecitationId, String? guardianPhone, String? notes,@TimestampConverter() DateTime? joinedAt,@TimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class _$StudentCopyWithImpl<$Res>
    implements $StudentCopyWith<$Res> {
  _$StudentCopyWithImpl(this._self, this._then);

  final Student _self;
  final $Res Function(Student) _then;

/// Create a copy of Student
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? teacherId = null,Object? teacherName = null,Object? departmentId = null,Object? totalPoints = null,Object? recitationCount = null,Object? lastRecitationLabel = freezed,Object? lastRecitationDate = freezed,Object? lastEvaluation = freezed,Object? lastRecitationId = freezed,Object? guardianPhone = freezed,Object? notes = freezed,Object? joinedAt = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,teacherId: null == teacherId ? _self.teacherId : teacherId // ignore: cast_nullable_to_non_nullable
as String,teacherName: null == teacherName ? _self.teacherName : teacherName // ignore: cast_nullable_to_non_nullable
as String,departmentId: null == departmentId ? _self.departmentId : departmentId // ignore: cast_nullable_to_non_nullable
as Department,totalPoints: null == totalPoints ? _self.totalPoints : totalPoints // ignore: cast_nullable_to_non_nullable
as int,recitationCount: null == recitationCount ? _self.recitationCount : recitationCount // ignore: cast_nullable_to_non_nullable
as int,lastRecitationLabel: freezed == lastRecitationLabel ? _self.lastRecitationLabel : lastRecitationLabel // ignore: cast_nullable_to_non_nullable
as String?,lastRecitationDate: freezed == lastRecitationDate ? _self.lastRecitationDate : lastRecitationDate // ignore: cast_nullable_to_non_nullable
as DateTime?,lastEvaluation: freezed == lastEvaluation ? _self.lastEvaluation : lastEvaluation // ignore: cast_nullable_to_non_nullable
as Evaluation?,lastRecitationId: freezed == lastRecitationId ? _self.lastRecitationId : lastRecitationId // ignore: cast_nullable_to_non_nullable
as String?,guardianPhone: freezed == guardianPhone ? _self.guardianPhone : guardianPhone // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,joinedAt: freezed == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Student].
extension StudentPatterns on Student {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Student value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Student() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Student value)  $default,){
final _that = this;
switch (_that) {
case _Student():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Student value)?  $default,){
final _that = this;
switch (_that) {
case _Student() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String fullName,  String teacherId,  String teacherName,  Department departmentId,  int totalPoints,  int recitationCount,  String? lastRecitationLabel, @TimestampConverter()  DateTime? lastRecitationDate,  Evaluation? lastEvaluation,  String? lastRecitationId,  String? guardianPhone,  String? notes, @TimestampConverter()  DateTime? joinedAt, @TimestampConverter()  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Student() when $default != null:
return $default(_that.id,_that.fullName,_that.teacherId,_that.teacherName,_that.departmentId,_that.totalPoints,_that.recitationCount,_that.lastRecitationLabel,_that.lastRecitationDate,_that.lastEvaluation,_that.lastRecitationId,_that.guardianPhone,_that.notes,_that.joinedAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String fullName,  String teacherId,  String teacherName,  Department departmentId,  int totalPoints,  int recitationCount,  String? lastRecitationLabel, @TimestampConverter()  DateTime? lastRecitationDate,  Evaluation? lastEvaluation,  String? lastRecitationId,  String? guardianPhone,  String? notes, @TimestampConverter()  DateTime? joinedAt, @TimestampConverter()  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _Student():
return $default(_that.id,_that.fullName,_that.teacherId,_that.teacherName,_that.departmentId,_that.totalPoints,_that.recitationCount,_that.lastRecitationLabel,_that.lastRecitationDate,_that.lastEvaluation,_that.lastRecitationId,_that.guardianPhone,_that.notes,_that.joinedAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String fullName,  String teacherId,  String teacherName,  Department departmentId,  int totalPoints,  int recitationCount,  String? lastRecitationLabel, @TimestampConverter()  DateTime? lastRecitationDate,  Evaluation? lastEvaluation,  String? lastRecitationId,  String? guardianPhone,  String? notes, @TimestampConverter()  DateTime? joinedAt, @TimestampConverter()  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Student() when $default != null:
return $default(_that.id,_that.fullName,_that.teacherId,_that.teacherName,_that.departmentId,_that.totalPoints,_that.recitationCount,_that.lastRecitationLabel,_that.lastRecitationDate,_that.lastEvaluation,_that.lastRecitationId,_that.guardianPhone,_that.notes,_that.joinedAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Student implements Student {
  const _Student({required this.id, required this.fullName, required this.teacherId, required this.teacherName, required this.departmentId, this.totalPoints = 0, this.recitationCount = 0, this.lastRecitationLabel, @TimestampConverter() this.lastRecitationDate, this.lastEvaluation, this.lastRecitationId, this.guardianPhone, this.notes, @TimestampConverter() this.joinedAt, @TimestampConverter() this.createdAt});
  factory _Student.fromJson(Map<String, dynamic> json) => _$StudentFromJson(json);

@override final  String id;
@override final  String fullName;
@override final  String teacherId;
@override final  String teacherName;
@override final  Department departmentId;
@override@JsonKey() final  int totalPoints;
@override@JsonKey() final  int recitationCount;
@override final  String? lastRecitationLabel;
@override@TimestampConverter() final  DateTime? lastRecitationDate;
@override final  Evaluation? lastEvaluation;
@override final  String? lastRecitationId;
@override final  String? guardianPhone;
@override final  String? notes;
@override@TimestampConverter() final  DateTime? joinedAt;
@override@TimestampConverter() final  DateTime? createdAt;

/// Create a copy of Student
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudentCopyWith<_Student> get copyWith => __$StudentCopyWithImpl<_Student>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StudentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Student&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.teacherId, teacherId) || other.teacherId == teacherId)&&(identical(other.teacherName, teacherName) || other.teacherName == teacherName)&&(identical(other.departmentId, departmentId) || other.departmentId == departmentId)&&(identical(other.totalPoints, totalPoints) || other.totalPoints == totalPoints)&&(identical(other.recitationCount, recitationCount) || other.recitationCount == recitationCount)&&(identical(other.lastRecitationLabel, lastRecitationLabel) || other.lastRecitationLabel == lastRecitationLabel)&&(identical(other.lastRecitationDate, lastRecitationDate) || other.lastRecitationDate == lastRecitationDate)&&(identical(other.lastEvaluation, lastEvaluation) || other.lastEvaluation == lastEvaluation)&&(identical(other.lastRecitationId, lastRecitationId) || other.lastRecitationId == lastRecitationId)&&(identical(other.guardianPhone, guardianPhone) || other.guardianPhone == guardianPhone)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,teacherId,teacherName,departmentId,totalPoints,recitationCount,lastRecitationLabel,lastRecitationDate,lastEvaluation,lastRecitationId,guardianPhone,notes,joinedAt,createdAt);

@override
String toString() {
  return 'Student(id: $id, fullName: $fullName, teacherId: $teacherId, teacherName: $teacherName, departmentId: $departmentId, totalPoints: $totalPoints, recitationCount: $recitationCount, lastRecitationLabel: $lastRecitationLabel, lastRecitationDate: $lastRecitationDate, lastEvaluation: $lastEvaluation, lastRecitationId: $lastRecitationId, guardianPhone: $guardianPhone, notes: $notes, joinedAt: $joinedAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$StudentCopyWith<$Res> implements $StudentCopyWith<$Res> {
  factory _$StudentCopyWith(_Student value, $Res Function(_Student) _then) = __$StudentCopyWithImpl;
@override @useResult
$Res call({
 String id, String fullName, String teacherId, String teacherName, Department departmentId, int totalPoints, int recitationCount, String? lastRecitationLabel,@TimestampConverter() DateTime? lastRecitationDate, Evaluation? lastEvaluation, String? lastRecitationId, String? guardianPhone, String? notes,@TimestampConverter() DateTime? joinedAt,@TimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class __$StudentCopyWithImpl<$Res>
    implements _$StudentCopyWith<$Res> {
  __$StudentCopyWithImpl(this._self, this._then);

  final _Student _self;
  final $Res Function(_Student) _then;

/// Create a copy of Student
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? teacherId = null,Object? teacherName = null,Object? departmentId = null,Object? totalPoints = null,Object? recitationCount = null,Object? lastRecitationLabel = freezed,Object? lastRecitationDate = freezed,Object? lastEvaluation = freezed,Object? lastRecitationId = freezed,Object? guardianPhone = freezed,Object? notes = freezed,Object? joinedAt = freezed,Object? createdAt = freezed,}) {
  return _then(_Student(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,teacherId: null == teacherId ? _self.teacherId : teacherId // ignore: cast_nullable_to_non_nullable
as String,teacherName: null == teacherName ? _self.teacherName : teacherName // ignore: cast_nullable_to_non_nullable
as String,departmentId: null == departmentId ? _self.departmentId : departmentId // ignore: cast_nullable_to_non_nullable
as Department,totalPoints: null == totalPoints ? _self.totalPoints : totalPoints // ignore: cast_nullable_to_non_nullable
as int,recitationCount: null == recitationCount ? _self.recitationCount : recitationCount // ignore: cast_nullable_to_non_nullable
as int,lastRecitationLabel: freezed == lastRecitationLabel ? _self.lastRecitationLabel : lastRecitationLabel // ignore: cast_nullable_to_non_nullable
as String?,lastRecitationDate: freezed == lastRecitationDate ? _self.lastRecitationDate : lastRecitationDate // ignore: cast_nullable_to_non_nullable
as DateTime?,lastEvaluation: freezed == lastEvaluation ? _self.lastEvaluation : lastEvaluation // ignore: cast_nullable_to_non_nullable
as Evaluation?,lastRecitationId: freezed == lastRecitationId ? _self.lastRecitationId : lastRecitationId // ignore: cast_nullable_to_non_nullable
as String?,guardianPhone: freezed == guardianPhone ? _self.guardianPhone : guardianPhone // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,joinedAt: freezed == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
