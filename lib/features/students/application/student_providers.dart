import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/session_providers.dart';
import '../../auth/domain/enums.dart';
import '../../recitations/data/recitation_repository.dart';
import '../../recitations/domain/recitation.dart';
import '../data/student_repository.dart';
import '../domain/student.dart';

/// The signed-in teacher's students.
final myStudentsProvider = StreamProvider<List<Student>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || user.departmentId == null) return Stream.value(const []);
  return ref.watch(studentRepositoryProvider).watchTeacherStudents(teacherId: user.teacherKey, department: user.departmentId!);
});

final studentProvider = StreamProvider.family<Student?, String>(
  (ref, id) => ref.watch(studentRepositoryProvider).watchStudent(id),
);

/// History query key: student + department + page size.
typedef HistoryKey = ({String studentId, Department department, int limit});

final studentHistoryProvider = StreamProvider.family<List<Recitation>, HistoryKey>(
  (ref, k) => ref
      .watch(recitationRepositoryProvider)
      .watchStudentHistory(studentId: k.studentId, department: k.department, limit: k.limit),
);

final departmentLeaderboardProvider = StreamProvider.family<List<Student>, Department>(
  (ref, d) => ref.watch(studentRepositoryProvider).watchDepartmentLeaderboard(d),
);

final allStudentsProvider = StreamProvider.family<List<Student>, Department?>(
  (ref, d) => ref.watch(studentRepositoryProvider).watchAllStudents(department: d),
);

enum StudentSort {
  points('الأعلى نقاطاً'),
  name('الاسم'),
  lastDate('آخر تسميع'),
  oldest('الأقدم تسميعاً');

  const StudentSort(this.label);
  final String label;
}

enum StudentFilter {
  all('الكل'),
  recitedToday('سمّع اليوم'),
  notThisWeek('لم يسمّع منذ أسبوع'),
  never('لم يسمّع بعد');

  const StudentFilter(this.label);
  final String label;
}

/// Pure search / filter / sort (unit tested).
List<Student> applyStudentQuery(
  List<Student> input, {
  String search = '',
  StudentSort sort = StudentSort.points,
  StudentFilter filter = StudentFilter.all,
  DateTime? now,
  String Function(String)? normalize,
}) {
  final n = normalize ?? (String s) => s;
  final ref = now ?? DateTime.now();
  final today = DateTime(ref.year, ref.month, ref.day);
  final q = n(search.trim());
  var list = input.where((s) {
    if (q.isNotEmpty && !n(s.fullName).contains(q)) return false;
    final d = s.lastRecitationDate;
    return switch (filter) {
      StudentFilter.all => true,
      StudentFilter.recitedToday => d != null && !d.isBefore(today),
      StudentFilter.notThisWeek => d == null || d.isBefore(today.subtract(const Duration(days: 7))),
      StudentFilter.never => d == null,
    };
  }).toList();
  int byName(Student a, Student b) => a.fullName.compareTo(b.fullName);
  list.sort(switch (sort) {
    StudentSort.points => (a, b) {
        final c = b.totalPoints.compareTo(a.totalPoints);
        return c != 0 ? c : byName(a, b);
      },
    StudentSort.name => byName,
    StudentSort.lastDate => (a, b) =>
        (b.lastRecitationDate ?? DateTime(1900)).compareTo(a.lastRecitationDate ?? DateTime(1900)),
    StudentSort.oldest => (a, b) =>
        (a.lastRecitationDate ?? DateTime(1900)).compareTo(b.lastRecitationDate ?? DateTime(1900)),
  });
  return list;
}
