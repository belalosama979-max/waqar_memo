import 'package:alwaqar/core/errors/app_failure.dart';
import 'package:alwaqar/features/auth/domain/enums.dart';
import 'package:alwaqar/features/teachers/data/teacher_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;

/// Records created / rolled-back logins instead of calling Firebase Auth.
class FakeLogins {
  final created = <String, String>{}; // uid -> password
  final rolledBack = <String>[];
  var released = 0;
  var _n = 0;

  Future<CreatedLogin> call(String email, String password) async {
    final uid = 'auth${_n++}';
    created[uid] = password;
    return (
      uid: uid,
      release: () async => released++,
      rollback: () async => rolledBack.add(uid),
    );
  }
}

void main() {
  late FakeFirebaseFirestore db;
  late FakeLogins logins;
  late TeacherRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    logins = FakeLogins();
    repo = TeacherRepository(db, logins.call);
  });

  test('initial password convention: first name + 123 (min 6 chars)', () {
    expect(TeacherRepository.initialPassword('محمد عبدالله'), 'محمد123');
    expect(TeacherRepository.initialPassword('  خالد   محمود '), 'خالد123');
    expect(TeacherRepository.initialPassword('مي أحمد'), 'مي1234');
  });

  test('create: identity, public directory and a temporary-password login', () async {
    final created = await repo.createTeacher(fullName: ' محمد  عبدالله ', department: Department.male, phone: '0599');
    expect(created.temporaryPassword, 'محمد123');
    expect(logins.created.values.single, 'محمد123');
    expect(logins.released, 1);

    final t = (await db.collection('teachers').doc(created.id).get()).data()!;
    expect(t['displayName'], 'محمد عبدالله');
    expect(t['departmentId'], 'male');
    expect(t['studentCount'], 0);
    final uid = t['authUid'] as String;

    final dir = (await db.collection('login_directory').doc(created.id).get()).data()!;
    expect(dir['active'], true);
    expect(dir['authEmail'], endsWith('@teachers.alwaqar.app'));

    final login = (await db.collection('users').doc(uid).get()).data()!;
    expect(login['role'], 'teacher');
    expect(login['teacherId'], created.id);
    expect(login['mustChangePassword'], true);
    expect(login.toString().contains('محمد123'), isFalse, reason: 'passwords are never stored');
  });

  test('invalid names are rejected in Arabic before any login is created', () async {
    await expectLater(repo.createTeacher(fullName: 'ع', department: Department.male), throwsA(isA<AppFailure>()));
    expect(logins.created, isEmpty);
  });

  test('reset issues a new login for the same teacher and retires the old one', () async {
    final created = await repo.createTeacher(fullName: 'فاطمة علي', department: Department.female);
    final oldUid = (await db.collection('teachers').doc(created.id).get()).get('authUid') as String;
    final oldEmail = (await db.collection('login_directory').doc(created.id).get()).get('authEmail');

    final pwd = await repo.resetPassword(created.id);
    expect(pwd, 'فاطمة123');

    final t = (await db.collection('teachers').doc(created.id).get()).data()!;
    final newUid = t['authUid'] as String;
    expect(newUid, isNot(oldUid));
    expect((await db.collection('users').doc(oldUid).get()).get('active'), false);
    final fresh = (await db.collection('users').doc(newUid).get()).data()!;
    expect(fresh['teacherId'], created.id, reason: 'same teacher identity');
    expect(fresh['mustChangePassword'], true);
    expect((await db.collection('login_directory').doc(created.id).get()).get('authEmail'), isNot(oldEmail));
  });

  test('deactivate turns off every login; reactivate only the current one', () async {
    final created = await repo.createTeacher(fullName: 'أحمد يوسف', department: Department.male);
    final oldUid = (await db.collection('teachers').doc(created.id).get()).get('authUid') as String;
    await repo.resetPassword(created.id);
    final currentUid = (await db.collection('teachers').doc(created.id).get()).get('authUid') as String;

    await repo.setActive(teacherId: created.id, active: false);
    expect((await db.collection('users').doc(currentUid).get()).get('active'), false);
    expect((await db.collection('login_directory').doc(created.id).get()).get('active'), false);

    await repo.setActive(teacherId: created.id, active: true);
    expect((await db.collection('users').doc(currentUid).get()).get('active'), true);
    expect((await db.collection('users').doc(oldUid).get()).get('active'), false);
  });

  test('department change and deletion are blocked while students are assigned', () async {
    final created = await repo.createTeacher(fullName: 'سالم ناصر', department: Department.male);
    await db.collection('teachers').doc(created.id).update({'studentCount': 1});
    await db.collection('students').doc('s1').set({'fullName': 'طالب', 'teacherId': created.id, 'departmentId': 'male'});

    await expectLater(
      repo.updateTeacher(teacherId: created.id, fullName: 'سالم ناصر', department: Department.female),
      throwsA(isA<AppFailure>().having((e) => e.message, 'message', contains('انقل'))),
    );
    await expectLater(repo.deleteTeacher(created.id), throwsA(isA<AppFailure>()));

    // Rename is allowed and updates the denormalized name on students.
    await repo.updateTeacher(teacherId: created.id, fullName: 'سالم ناصر العلي', department: Department.male);
    expect((await db.collection('students').doc('s1').get()).get('teacherName'), 'سالم ناصر العلي');
  });

  test('delete removes identity and directory, retires logins', () async {
    final created = await repo.createTeacher(fullName: 'زيد عمر', department: Department.male);
    final uid = (await db.collection('teachers').doc(created.id).get()).get('authUid') as String;
    await repo.deleteTeacher(created.id);
    expect((await db.collection('teachers').doc(created.id).get()).exists, isFalse);
    expect((await db.collection('login_directory').doc(created.id).get()).exists, isFalse);
    expect((await db.collection('users').doc(uid).get()).get('active'), false);
  });
}
