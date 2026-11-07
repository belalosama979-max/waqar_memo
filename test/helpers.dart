import 'package:alwaqar/features/auth/domain/app_user.dart';
import 'package:alwaqar/features/auth/domain/enums.dart';
import 'package:alwaqar/features/students/domain/student.dart';
import 'package:alwaqar/features/teachers/domain/teacher.dart';

const maleTeacher = AppUser(
  id: 'tm1',
  role: UserRole.teacher,
  displayName: 'محمد عبدالله',
  departmentId: Department.male,
);

const femaleTeacher = AppUser(
  id: 'tf1',
  role: UserRole.teacher,
  displayName: 'فاطمة علي',
  departmentId: Department.female,
);

const adminUser = AppUser(id: 'admin1', role: UserRole.admin, displayName: 'المشرف العام', email: 'admin@alwaqar.test');

Student student(
  String id, {
  String name = 'طالب',
  String teacherId = 'tm1',
  Department dep = Department.male,
  int points = 0,
  int count = 0,
  DateTime? last,
}) =>
    Student(
      id: id,
      fullName: name,
      teacherId: teacherId,
      teacherName: 'محمد عبدالله',
      departmentId: dep,
      totalPoints: points,
      recitationCount: count,
      lastRecitationDate: last,
      lastRecitationLabel: last == null ? null : 'سورة الملك',
    );

const teacherDoc = Teacher(id: 'tm1', displayName: 'محمد عبدالله', departmentId: Department.male, studentCount: 0);
const teacherDoc2 = Teacher(id: 'tm2', displayName: 'أحمد يوسف', departmentId: Department.male, studentCount: 0);
