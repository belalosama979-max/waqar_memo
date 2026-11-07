import '../../recitations/domain/evaluation.dart';
import '../../recitations/domain/recitation.dart';
import '../../students/domain/student.dart';

/// One bucket of activity (a day, a week or a month).
class ActivityPoint {
  const ActivityPoint({required this.start, required this.count, required this.points});
  final DateTime start;
  final int count;
  final int points;
}

class TeacherScore {
  const TeacherScore({required this.teacherId, required this.teacherName, required this.points, required this.students});
  final String teacherId;
  final String teacherName;
  final int points;
  final int students;
}

/// Pure analytics helpers (unit tested).
abstract final class Analytics {
  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Start of the week (Saturday, as customary in the region).
  static DateTime weekStart(DateTime d) {
    final day = _day(d);
    final diff = (day.weekday - DateTime.saturday) % 7;
    return day.subtract(Duration(days: diff));
  }

  static List<ActivityPoint> daily(List<Recitation> list, {required DateTime now, int days = 14}) {
    final today = _day(now);
    final buckets = {for (var i = days - 1; i >= 0; i--) today.subtract(Duration(days: i)): <Recitation>[]};
    for (final r in list) {
      final d = r.recitationDate;
      if (d == null) continue;
      buckets[_day(d)]?.add(r);
    }
    return buckets.entries
        .map((e) => ActivityPoint(start: e.key, count: e.value.length, points: _sum(e.value)))
        .toList();
  }

  static List<ActivityPoint> weekly(List<Recitation> list, {required DateTime now, int weeks = 8}) {
    final current = weekStart(now);
    final buckets = {for (var i = weeks - 1; i >= 0; i--) current.subtract(Duration(days: 7 * i)): <Recitation>[]};
    for (final r in list) {
      final d = r.recitationDate;
      if (d == null) continue;
      buckets[weekStart(d)]?.add(r);
    }
    return buckets.entries
        .map((e) => ActivityPoint(start: e.key, count: e.value.length, points: _sum(e.value)))
        .toList();
  }

  static List<ActivityPoint> monthly(List<Recitation> list, {required DateTime now, int months = 6}) {
    final keys = <DateTime>[];
    for (var i = months - 1; i >= 0; i--) {
      keys.add(DateTime(now.year, now.month - i));
    }
    final buckets = {for (final k in keys) k: <Recitation>[]};
    for (final r in list) {
      final d = r.recitationDate;
      if (d == null) continue;
      buckets[DateTime(d.year, d.month)]?.add(r);
    }
    return buckets.entries
        .map((e) => ActivityPoint(start: e.key, count: e.value.length, points: _sum(e.value)))
        .toList();
  }

  static Map<Evaluation, int> evaluationBreakdown(List<Recitation> list) {
    final m = {for (final e in Evaluation.values) e: 0};
    for (final r in list) {
      m[r.evaluation] = m[r.evaluation]! + 1;
    }
    return m;
  }

  static List<Student> topStudents(List<Student> students, {int count = 5}) {
    final sorted = [...students]..sort(compareByRank);
    return sorted.take(count).toList();
  }

  /// Leaderboard order: points desc, then more recitations, then name.
  static int compareByRank(Student a, Student b) {
    final p = b.totalPoints.compareTo(a.totalPoints);
    if (p != 0) return p;
    final c = b.recitationCount.compareTo(a.recitationCount);
    if (c != 0) return c;
    return a.fullName.compareTo(b.fullName);
  }

  /// Competition ranking ("1, 2, 2, 4"): equal points share a rank.
  static List<int> ranks(List<Student> sorted) {
    final out = <int>[];
    for (var i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i].totalPoints == sorted[i - 1].totalPoints) {
        out.add(out[i - 1]);
      } else {
        out.add(i + 1);
      }
    }
    return out;
  }

  static List<TeacherScore> topTeachers(List<Student> students, {int count = 5}) {
    final map = <String, TeacherScore>{};
    for (final s in students) {
      final prev = map[s.teacherId];
      map[s.teacherId] = TeacherScore(
        teacherId: s.teacherId,
        teacherName: s.teacherName,
        points: (prev?.points ?? 0) + s.totalPoints,
        students: (prev?.students ?? 0) + 1,
      );
    }
    final list = map.values.toList()..sort((a, b) => b.points.compareTo(a.points));
    return list.take(count).toList();
  }

  /// Cumulative points over time for a student's profile chart (oldest first).
  static List<ActivityPoint> cumulativePoints(List<Recitation> history) {
    final sorted = [...history.where((r) => r.recitationDate != null)]
      ..sort((a, b) => a.recitationDate!.compareTo(b.recitationDate!));
    var running = 0;
    return [
      for (final r in sorted)
        ActivityPoint(start: r.recitationDate!, count: 1, points: running += r.totalPoints),
    ];
  }

  static int _sum(List<Recitation> l) => l.fold(0, (a, r) => a + r.totalPoints);
}
