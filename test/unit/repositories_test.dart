import 'dart:async';

import 'package:alwaqar/core/errors/app_failure.dart';
import 'package:alwaqar/core/firebase/firebase_providers.dart';
import 'package:alwaqar/features/auth/domain/enums.dart';
import 'package:alwaqar/features/recitations/data/pending_sync_store.dart';
import 'package:alwaqar/features/recitations/data/recitation_repository.dart';
import 'package:alwaqar/features/recitations/domain/evaluation.dart';
import 'package:alwaqar/features/recitations/domain/evaluation_settings.dart';
import 'package:alwaqar/features/students/data/student_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

class MockFirestore extends Mock implements FirebaseFirestore {}

class MockBatch extends Mock implements WriteBatch {}

Future<ProviderContainer> makeContainer(FirebaseFirestore db) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    firestoreProvider.overrideWithValue(db),
  ]);
  addTearDown(c.dispose);
  return c;
}

Future<void> seedStudent(FakeFirebaseFirestore db, String id, {String teacherId = 'tm1', String dep = 'male', int points = 0}) =>
    db.collection('students').doc(id).set({
      'fullName': 'طالب $id',
      'teacherId': teacherId,
      'teacherName': 'محمد عبدالله',
      'departmentId': dep,
      'totalPoints': points,
      'recitationCount': 0,
    });

RecitationDraft draft(String id, {DateTime? date, int extra = 5, Evaluation e = Evaluation.excellent, String studentId = 's1', int points = 0}) =>
    RecitationDraft(
      id: id,
      student: student(studentId, points: points),
      date: date ?? DateTime.now(),
      type: RecitationType.surah,
      surahNumber: 67,
      evaluation: e,
      extraPoints: extra,
    );

void main() {
  final settings = EvaluationSettings.defaults();

  group('RecitationRepository.submit', () {
    test('writes the record and updates the student atomically', () async {
      final db = FakeFirebaseFirestore();
      await seedStudent(db, 's1', points: 100);
      final c = await makeContainer(db);
      final repo = c.read(recitationRepositoryProvider);

      final outcome = await repo.submit(draft('r1'), teacher: maleTeacher, settings: settings);
      expect(outcome, SubmitOutcome.synced);

      final r = (await db.collection('recitations').doc('r1').get()).data()!;
      expect(r['evaluationPoints'], 40);
      expect(r['extraPoints'], 5);
      expect(r['totalPoints'], 45);
      expect(r['teacherId'], 'tm1');
      expect(r['departmentId'], 'male');
      expect(r['surahNumber'], 67);
      expect(r['partNumber'], isNull);

      final s = (await db.collection('students').doc('s1').get()).data()!;
      expect(s['totalPoints'], 145);
      expect(s['recitationCount'], 1);
      expect(s['lastRecitationLabel'], 'سورة الملك');
      expect(s['lastEvaluation'], 'excellent');
      expect(s['lastAppliedRecitationId'], 'r1');
      expect(c.read(pendingSyncStoreProvider).pending, isEmpty);
    });

    test('back-dated recitation does not replace the latest one', () async {
      final db = FakeFirebaseFirestore();
      await seedStudent(db, 's1');
      final c = await makeContainer(db);
      final repo = c.read(recitationRepositoryProvider);
      final today = DateTime.now();
      await repo.submit(draft('r1', date: today), teacher: maleTeacher, settings: settings);
      final latest = (await db.collection('students').doc('s1').get()).data()!;
      final updated = student('s1').copyWith(
        lastRecitationDate: (latest['lastRecitationDate'] as Timestamp).toDate(),
        totalPoints: 45,
      );
      await repo.submit(
        RecitationDraft(
          id: 'r0',
          student: updated,
          date: today.subtract(const Duration(days: 3)),
          type: RecitationType.juz,
          partNumber: 30,
          evaluation: Evaluation.veryGood,
          extraPoints: 0,
        ),
        teacher: maleTeacher,
        settings: settings,
      );
      final s = (await db.collection('students').doc('s1').get()).data()!;
      expect(s['lastRecitationId'], 'r1');
      expect(s['totalPoints'], 70);
      expect(s['recitationCount'], 2);
    });

    test('validation rejects foreign students, other departments and bad input', () {
      final now = DateTime(2026, 11, 7, 10);
      String? v(RecitationDraft d) => RecitationRepository.validate(d, teacher: maleTeacher, settings: settings, now: now);
      final ok = draft('x', date: now);
      expect(v(ok), isNull);
      expect(v(RecitationDraft(id: 'x', student: student('s', teacherId: 'tm2'), date: now, type: RecitationType.surah, surahNumber: 1, evaluation: Evaluation.excellent, extraPoints: 0)), isNotNull);
      expect(v(RecitationDraft(id: 'x', student: student('s', dep: Department.female), date: now, type: RecitationType.surah, surahNumber: 1, evaluation: Evaluation.excellent, extraPoints: 0)), isNotNull);
      expect(v(RecitationDraft(id: 'x', student: student('s'), date: now, type: RecitationType.juz, evaluation: Evaluation.excellent, extraPoints: 0)), 'يرجى اختيار الجزء');
      expect(v(RecitationDraft(id: 'x', student: student('s'), date: now, type: RecitationType.surah, surahNumber: 115, evaluation: Evaluation.excellent, extraPoints: 0)), 'يرجى اختيار السورة');
      expect(v(draft('x', date: now, extra: 101)), isNotNull);
      expect(v(draft('x', date: now.add(const Duration(days: 1)))), 'لا يمكن تسجيل تسميع بتاريخ مستقبلي');
    });

    test('submit throws an Arabic AppFailure for invalid drafts and writes nothing', () async {
      final db = FakeFirebaseFirestore();
      await seedStudent(db, 's1');
      final c = await makeContainer(db);
      await expectLater(
        c.read(recitationRepositoryProvider).submit(draft('bad', extra: 500), teacher: maleTeacher, settings: settings),
        throwsA(isA<AppFailure>()),
      );
      expect((await db.collection('recitations').get()).docs, isEmpty);
    });

    test('offline: write is queued, tracked, and cleared once acknowledged', () async {
      final fake = FakeFirebaseFirestore();
      final mock = MockFirestore();
      final batch = MockBatch();
      final ack = Completer<void>();
      when(() => mock.collection(any())).thenAnswer((i) => fake.collection(i.positionalArguments.first as String));
      when(mock.batch).thenReturn(batch);
      when(() => batch.commit()).thenAnswer((_) => ack.future);

      final c = await makeContainer(mock);
      final repo = RecitationRepository(mock, c.read(pendingSyncStoreProvider.notifier), ackTimeout: const Duration(milliseconds: 50));
      final outcome = await repo.submit(draft('q1'), teacher: maleTeacher, settings: settings);
      expect(outcome, SubmitOutcome.queued);
      expect(c.read(pendingSyncStoreProvider).pending.single.id, 'q1');

      ack.complete();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(c.read(pendingSyncStoreProvider).pending, isEmpty);
      expect(c.read(pendingSyncStoreProvider).failed, isEmpty);
    });

    test('offline: a write rejected later is reported as failed', () async {
      final fake = FakeFirebaseFirestore();
      final mock = MockFirestore();
      final batch = MockBatch();
      final ack = Completer<void>();
      when(() => mock.collection(any())).thenAnswer((i) => fake.collection(i.positionalArguments.first as String));
      when(mock.batch).thenReturn(batch);
      when(() => batch.commit()).thenAnswer((_) => ack.future);

      final c = await makeContainer(mock);
      final repo = RecitationRepository(mock, c.read(pendingSyncStoreProvider.notifier), ackTimeout: const Duration(milliseconds: 50));
      await repo.submit(draft('q2'), teacher: maleTeacher, settings: settings);
      ack.completeError(FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final sync = c.read(pendingSyncStoreProvider);
      expect(sync.pending, isEmpty);
      expect(sync.failed.single.id, 'q2');
      expect(sync.failed.single.error, 'ليست لديك صلاحية لتنفيذ هذا الإجراء');
    });

    test('pending queue survives an app restart', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c1 = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
      await c1.read(pendingSyncStoreProvider.notifier).markPending('p1', 'طالب — سورة الملك');
      c1.dispose();
      final c2 = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
      addTearDown(c2.dispose);
      expect(c2.read(pendingSyncStoreProvider).pending.single.title, 'طالب — سورة الملك');
    });
  });

  group('RecitationRepository queries', () {
    test('history only returns the requested department', () async {
      final db = FakeFirebaseFirestore();
      final base = {
        'studentName': 'x', 'teacherId': 'tm1', 'teacherName': 'x', 'recitationType': 'surah', 'surahNumber': 1,
        'evaluation': 'excellent', 'evaluationPoints': 40, 'extraPoints': 0, 'totalPoints': 40,
      };
      await db.collection('recitations').doc('a').set({...base, 'studentId': 's1', 'departmentId': 'male', 'recitationDate': Timestamp.fromDate(DateTime(2026, 11, 1))});
      await db.collection('recitations').doc('b').set({...base, 'studentId': 's1', 'departmentId': 'male', 'recitationDate': Timestamp.fromDate(DateTime(2026, 11, 3))});
      await db.collection('recitations').doc('c').set({...base, 'studentId': 's1', 'departmentId': 'female', 'recitationDate': Timestamp.fromDate(DateTime(2026, 11, 2))});
      final c = await makeContainer(db);
      final list = await c.read(recitationRepositoryProvider).watchStudentHistory(studentId: 's1', department: Department.male).first;
      expect(list.map((r) => r.id), ['b', 'a']);
    });
  });

  group('StudentRepository', () {
    test('add, transfer and delete keep teacher counters consistent', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('teachers').doc('tm1').set({'displayName': 'محمد', 'departmentId': 'male', 'studentCount': 0});
      await db.collection('teachers').doc('tm2').set({'displayName': 'أحمد', 'departmentId': 'male', 'studentCount': 0});
      final repo = StudentRepository(db);

      final id = await repo.addStudent(fullName: '  عمر سعيد ', teacher: teacherDoc);
      var s = await repo.watchStudent(id).first;
      expect(s!.fullName, 'عمر سعيد');
      expect(s.totalPoints, 0);
      expect((await db.collection('teachers').doc('tm1').get()).get('studentCount'), 1);

      await repo.transferStudent(student: s, newTeacher: teacherDoc2);
      s = await repo.watchStudent(id).first;
      expect(s!.teacherId, 'tm2');
      expect(s.teacherName, 'أحمد يوسف');
      expect((await db.collection('teachers').doc('tm1').get()).get('studentCount'), 0);
      expect((await db.collection('teachers').doc('tm2').get()).get('studentCount'), 1);

      await expectLater(repo.transferStudent(student: s, newTeacher: teacherDoc2), throwsA(isA<AppFailure>()));

      await repo.deleteStudent(s);
      expect(await repo.watchStudent(id).first, isNull);
      expect((await db.collection('teachers').doc('tm2').get()).get('studentCount'), 0);
    });

    test('teacher students query is scoped by department and teacher', () async {
      final db = FakeFirebaseFirestore();
      await seedStudent(db, 'a');
      await seedStudent(db, 'b', teacherId: 'tm2');
      await seedStudent(db, 'c', teacherId: 'tm1', dep: 'female');
      final list = await StudentRepository(db).watchTeacherStudents(teacherId: 'tm1', department: Department.male).first;
      expect(list.map((s) => s.id), ['a']);
    });

    test('department leaderboard is ordered and never mixes departments', () async {
      final db = FakeFirebaseFirestore();
      await seedStudent(db, 'a', points: 10);
      await seedStudent(db, 'b', points: 90, teacherId: 'tm2');
      await seedStudent(db, 'c', points: 500, dep: 'female');
      final list = await StudentRepository(db).watchDepartmentLeaderboard(Department.male).first;
      expect(list.map((s) => s.id), ['b', 'a']);
    });
  });
}
