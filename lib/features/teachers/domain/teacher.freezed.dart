// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'teacher.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Teacher {

 String get id; String get displayName; Department get departmentId; bool get active; int get studentCount; String? get phone;@TimestampConverter() DateTime? get createdAt;
/// Create a copy of Teacher
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeacherCopyWith<Teacher> get copyWith => _$TeacherCopyWithImpl<Teacher>(this as Teacher, _$identity);

  /// Serializes this Teacher to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Teacher&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.departmentId, departmentId) || other.departmentId == departmentId)&&(identical(other.active, active) || other.active == active)&&(identical(other.studentCount, studentCount) || other.studentCount == studentCount)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,departmentId,active,studentCount,phone,createdAt);

@override
String toString() {
  return 'Teacher(id: $id, displayName: $displayName, departmentId: $departmentId, active: $active, studentCount: $studentCount, phone: $phone, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $TeacherCopyWith<$Res>  {
  factory $TeacherCopyWith(Teacher value, $Res Function(Teacher) _then) = _$TeacherCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, Department departmentId, bool active, int studentCount, String? phone,@TimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class _$TeacherCopyWithImpl<$Res>
    implements $TeacherCopyWith<$Res> {
  _$TeacherCopyWithImpl(this._self, this._then);

  final Teacher _self;
  final $Res Function(Teacher) _then;

/// Create a copy of Teacher
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? departmentId = null,Object? active = null,Object? studentCount = null,Object? phone = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,departmentId: null == departmentId ? _self.departmentId : departmentId // ignore: cast_nullable_to_non_nullable
as Department,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,studentCount: null == studentCount ? _self.studentCount : studentCount // ignore: cast_nullable_to_non_nullable
as int,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Teacher].
extension TeacherPatterns on Teacher {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Teacher value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Teacher() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Teacher value)  $default,){
final _that = this;
switch (_that) {
case _Teacher():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Teacher value)?  $default,){
final _that = this;
switch (_that) {
case _Teacher() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  Department departmentId,  bool active,  int studentCount,  String? phone, @TimestampConverter()  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Teacher() when $default != null:
return $default(_that.id,_that.displayName,_that.departmentId,_that.active,_that.studentCount,_that.phone,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  Department departmentId,  bool active,  int studentCount,  String? phone, @TimestampConverter()  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _Teacher():
return $default(_that.id,_that.displayName,_that.departmentId,_that.active,_that.studentCount,_that.phone,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  Department departmentId,  bool active,  int studentCount,  String? phone, @TimestampConverter()  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Teacher() when $default != null:
return $default(_that.id,_that.displayName,_that.departmentId,_that.active,_that.studentCount,_that.phone,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Teacher implements Teacher {
  const _Teacher({required this.id, required this.displayName, required this.departmentId, this.active = true, this.studentCount = 0, this.phone, @TimestampConverter() this.createdAt});
  factory _Teacher.fromJson(Map<String, dynamic> json) => _$TeacherFromJson(json);

@override final  String id;
@override final  String displayName;
@override final  Department departmentId;
@override@JsonKey() final  bool active;
@override@JsonKey() final  int studentCount;
@override final  String? phone;
@override@TimestampConverter() final  DateTime? createdAt;

/// Create a copy of Teacher
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeacherCopyWith<_Teacher> get copyWith => __$TeacherCopyWithImpl<_Teacher>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TeacherToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Teacher&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.departmentId, departmentId) || other.departmentId == departmentId)&&(identical(other.active, active) || other.active == active)&&(identical(other.studentCount, studentCount) || other.studentCount == studentCount)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,departmentId,active,studentCount,phone,createdAt);

@override
String toString() {
  return 'Teacher(id: $id, displayName: $displayName, departmentId: $departmentId, active: $active, studentCount: $studentCount, phone: $phone, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$TeacherCopyWith<$Res> implements $TeacherCopyWith<$Res> {
  factory _$TeacherCopyWith(_Teacher value, $Res Function(_Teacher) _then) = __$TeacherCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, Department departmentId, bool active, int studentCount, String? phone,@TimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class __$TeacherCopyWithImpl<$Res>
    implements _$TeacherCopyWith<$Res> {
  __$TeacherCopyWithImpl(this._self, this._then);

  final _Teacher _self;
  final $Res Function(_Teacher) _then;

/// Create a copy of Teacher
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? departmentId = null,Object? active = null,Object? studentCount = null,Object? phone = freezed,Object? createdAt = freezed,}) {
  return _then(_Teacher(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,departmentId: null == departmentId ? _self.departmentId : departmentId // ignore: cast_nullable_to_non_nullable
as Department,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,studentCount: null == studentCount ? _self.studentCount : studentCount // ignore: cast_nullable_to_non_nullable
as int,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$LoginDirectoryEntry {

 String get id; String get displayName; Department get departmentId; String get authEmail; bool get active;
/// Create a copy of LoginDirectoryEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginDirectoryEntryCopyWith<LoginDirectoryEntry> get copyWith => _$LoginDirectoryEntryCopyWithImpl<LoginDirectoryEntry>(this as LoginDirectoryEntry, _$identity);

  /// Serializes this LoginDirectoryEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginDirectoryEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.departmentId, departmentId) || other.departmentId == departmentId)&&(identical(other.authEmail, authEmail) || other.authEmail == authEmail)&&(identical(other.active, active) || other.active == active));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,departmentId,authEmail,active);

@override
String toString() {
  return 'LoginDirectoryEntry(id: $id, displayName: $displayName, departmentId: $departmentId, authEmail: $authEmail, active: $active)';
}


}

/// @nodoc
abstract mixin class $LoginDirectoryEntryCopyWith<$Res>  {
  factory $LoginDirectoryEntryCopyWith(LoginDirectoryEntry value, $Res Function(LoginDirectoryEntry) _then) = _$LoginDirectoryEntryCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, Department departmentId, String authEmail, bool active
});




}
/// @nodoc
class _$LoginDirectoryEntryCopyWithImpl<$Res>
    implements $LoginDirectoryEntryCopyWith<$Res> {
  _$LoginDirectoryEntryCopyWithImpl(this._self, this._then);

  final LoginDirectoryEntry _self;
  final $Res Function(LoginDirectoryEntry) _then;

/// Create a copy of LoginDirectoryEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? departmentId = null,Object? authEmail = null,Object? active = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,departmentId: null == departmentId ? _self.departmentId : departmentId // ignore: cast_nullable_to_non_nullable
as Department,authEmail: null == authEmail ? _self.authEmail : authEmail // ignore: cast_nullable_to_non_nullable
as String,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LoginDirectoryEntry].
extension LoginDirectoryEntryPatterns on LoginDirectoryEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LoginDirectoryEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LoginDirectoryEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LoginDirectoryEntry value)  $default,){
final _that = this;
switch (_that) {
case _LoginDirectoryEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LoginDirectoryEntry value)?  $default,){
final _that = this;
switch (_that) {
case _LoginDirectoryEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  Department departmentId,  String authEmail,  bool active)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LoginDirectoryEntry() when $default != null:
return $default(_that.id,_that.displayName,_that.departmentId,_that.authEmail,_that.active);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  Department departmentId,  String authEmail,  bool active)  $default,) {final _that = this;
switch (_that) {
case _LoginDirectoryEntry():
return $default(_that.id,_that.displayName,_that.departmentId,_that.authEmail,_that.active);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  Department departmentId,  String authEmail,  bool active)?  $default,) {final _that = this;
switch (_that) {
case _LoginDirectoryEntry() when $default != null:
return $default(_that.id,_that.displayName,_that.departmentId,_that.authEmail,_that.active);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LoginDirectoryEntry implements LoginDirectoryEntry {
  const _LoginDirectoryEntry({required this.id, required this.displayName, required this.departmentId, required this.authEmail, this.active = true});
  factory _LoginDirectoryEntry.fromJson(Map<String, dynamic> json) => _$LoginDirectoryEntryFromJson(json);

@override final  String id;
@override final  String displayName;
@override final  Department departmentId;
@override final  String authEmail;
@override@JsonKey() final  bool active;

/// Create a copy of LoginDirectoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoginDirectoryEntryCopyWith<_LoginDirectoryEntry> get copyWith => __$LoginDirectoryEntryCopyWithImpl<_LoginDirectoryEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LoginDirectoryEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoginDirectoryEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.departmentId, departmentId) || other.departmentId == departmentId)&&(identical(other.authEmail, authEmail) || other.authEmail == authEmail)&&(identical(other.active, active) || other.active == active));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,departmentId,authEmail,active);

@override
String toString() {
  return 'LoginDirectoryEntry(id: $id, displayName: $displayName, departmentId: $departmentId, authEmail: $authEmail, active: $active)';
}


}

/// @nodoc
abstract mixin class _$LoginDirectoryEntryCopyWith<$Res> implements $LoginDirectoryEntryCopyWith<$Res> {
  factory _$LoginDirectoryEntryCopyWith(_LoginDirectoryEntry value, $Res Function(_LoginDirectoryEntry) _then) = __$LoginDirectoryEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, Department departmentId, String authEmail, bool active
});




}
/// @nodoc
class __$LoginDirectoryEntryCopyWithImpl<$Res>
    implements _$LoginDirectoryEntryCopyWith<$Res> {
  __$LoginDirectoryEntryCopyWithImpl(this._self, this._then);

  final _LoginDirectoryEntry _self;
  final $Res Function(_LoginDirectoryEntry) _then;

/// Create a copy of LoginDirectoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? departmentId = null,Object? authEmail = null,Object? active = null,}) {
  return _then(_LoginDirectoryEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,departmentId: null == departmentId ? _self.departmentId : departmentId // ignore: cast_nullable_to_non_nullable
as Department,authEmail: null == authEmail ? _self.authEmail : authEmail // ignore: cast_nullable_to_non_nullable
as String,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
