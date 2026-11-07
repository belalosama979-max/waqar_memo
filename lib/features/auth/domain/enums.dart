import 'package:json_annotation/json_annotation.dart';

enum UserRole {
  @JsonValue('admin')
  admin,
  @JsonValue('teacher')
  teacher;

  String get label => switch (this) {
        UserRole.admin => 'المشرف العام',
        UserRole.teacher => 'معلم',
      };

  static UserRole? tryParse(Object? v) => switch (v) {
        'admin' => UserRole.admin,
        'teacher' => UserRole.teacher,
        _ => null,
      };
}

enum Department {
  @JsonValue('male')
  male,
  @JsonValue('female')
  female;

  String get id => name;

  String get label => switch (this) {
        Department.male => 'قسم الذكور',
        Department.female => 'قسم الإناث',
      };

  String get teacherNoun => switch (this) {
        Department.male => 'المعلم',
        Department.female => 'المعلمة',
      };

  String get studentNoun => switch (this) {
        Department.male => 'الطالب',
        Department.female => 'الطالبة',
      };

  static Department? tryParse(Object? v) => switch (v) {
        'male' => Department.male,
        'female' => Department.female,
        _ => null,
      };
}
