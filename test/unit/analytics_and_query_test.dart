import 'package:alwaqar/core/utils/formatters.dart';
import 'package:alwaqar/features/analytics/domain/analytics.dart';
import 'package:alwaqar/features/auth/domain/enums.dart';
import 'package:alwaqar/features/recitations/domain/evaluation.dart';
import 'package:alwaqar/features/recitations/domain/recitation.dart';
import 'package:alwaqar/features/students/application/student_providers.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;

import '../helpers.dart';

Recitation rec(DateTime d, Evaluation e, int total, {String teacherId = 'tm1'}) => Recitation(
      id: '${d.millisecondsSinceEpoch}$total',
      studentId: 's',
      studentName: 'x',
      teacherId: teacherId,
      teacherName: 'x',
      departmentId: Department.male,
      recitationDate: d,
      recitationType: RecitationType.surah,
      surahNumber: 1,
      evaluation: e,
      evaluationPoints: total,
      totalPoints: total,
    );

void main() {
  final now = DateTime(2026, 11, 7, 10); // Saturday

  group('Leaderboard ranking', () {
    test('competition ranks share ties', () {
      final sorted = [student('a', points: 100), student('b', points: 80), student('c', points: 80), student('d', points: 50)];
      expect(Analytics.ranks(sorted), [1, 2, 2, 4]);
    });

    test('ordering: points, then recitation count, then name', () {
      final list = [
        student('a', name: 'ب', points: 50, count: 1),
        student('b', name: 'أ', points: 50, count: 1),
        student('c', name: 'ج', points: 50, count: 3),
        student('d', name: 'د', points: 90),
      ]..sort(Analytics.compareByRank);
      expect(list.map((s) => s.id), ['d', 'c', 'b', 'a']);
    });

    test('top teachers aggregate their students', () {
      final top = Analytics.topTeachers([
        student('1', teacherId: 't1', points: 10),
        student('2', teacherId: 't2', points: 30),
        student('3', teacherId: 't1', points: 25),
      ]);
      expect(top.first.teacherId, 't1');
      expect(top.first.points, 35);
      expect(top.first.students, 2);
    });
  });

  group('Activity buckets', () {
    test('daily buckets cover the window and count by day', () {
      final list = [
        rec(DateTime(2026, 11, 7, 9), Evaluation.excellent, 40),
        rec(DateTime(2026, 11, 7, 12), Evaluation.veryGood, 25),
        rec(DateTime(2026, 11, 1), Evaluation.repeat, 10),
        rec(DateTime(2026, 9, 1), Evaluation.repeat, 10), // outside window
      ];
      final d = Analytics.daily(list, now: now, days: 14);
      expect(d.length, 14);
      expect(d.last.count, 2);
      expect(d.last.points, 65);
      expect(d.fold(0, (a, p) => a + p.count), 3);
    });

    test('weeks start on Saturday', () {
      expect(Analytics.weekStart(DateTime(2026, 11, 7)), DateTime(2026, 11, 7));
      expect(Analytics.weekStart(DateTime(2026, 11, 12)), DateTime(2026, 11, 7));
      expect(Analytics.weekStart(DateTime(2026, 11, 6)), DateTime(2026, 10, 31));
    });

    test('monthly buckets', () {
      final m = Analytics.monthly([rec(DateTime(2026, 10, 3), Evaluation.excellent, 40)], now: now, months: 3);
      expect(m.map((p) => p.start.month), [9, 10, 11]);
      expect(m[1].count, 1);
    });

    test('evaluation breakdown and cumulative points', () {
      final list = [
        rec(DateTime(2026, 11, 2), Evaluation.excellent, 40),
        rec(DateTime(2026, 11, 1), Evaluation.excellent, 45),
        rec(DateTime(2026, 11, 3), Evaluation.notRecited, 0),
      ];
      final b = Analytics.evaluationBreakdown(list);
      expect(b[Evaluation.excellent], 2);
      expect(b[Evaluation.notRecited], 1);
      final c = Analytics.cumulativePoints(list);
      expect(c.map((p) => p.points), [45, 85, 85]);
    });
  });

  group('Student search / filter / sort', () {
    final list = [
      student('1', name: 'أحمد علي', points: 10, last: DateTime(2026, 11, 7, 8)),
      student('2', name: 'فاطمة', points: 50, last: DateTime(2026, 10, 20)),
      student('3', name: 'عمر', points: 30),
    ];

    test('search tolerates hamza and taa marbuta variants', () {
      expect(applyStudentQuery(list, search: 'احمد', normalize: Fmt.searchKey).single.id, '1');
      expect(applyStudentQuery(list, search: 'فاطمه', normalize: Fmt.searchKey).single.id, '2');
    });

    test('filters', () {
      expect(applyStudentQuery(list, filter: StudentFilter.recitedToday, now: now).map((s) => s.id), ['1']);
      expect(applyStudentQuery(list, filter: StudentFilter.notThisWeek, now: now).map((s) => s.id).toSet(), {'2', '3'});
      expect(applyStudentQuery(list, filter: StudentFilter.never, now: now).map((s) => s.id), ['3']);
    });

    test('sorts', () {
      expect(applyStudentQuery(list).map((s) => s.id), ['2', '3', '1']);
      expect(applyStudentQuery(list, sort: StudentSort.lastDate).map((s) => s.id), ['1', '2', '3']);
      expect(applyStudentQuery(list, sort: StudentSort.oldest).first.id, '3');
    });
  });
}
