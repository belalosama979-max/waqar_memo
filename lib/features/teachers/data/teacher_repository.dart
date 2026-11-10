import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/firebase/firebase_config.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/firebase/json_converters.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../auth/domain/enums.dart';
import '../domain/teacher.dart';

/// A freshly created Firebase Auth login. Call [release] once its profile is
/// saved, or [rollback] to delete the login if saving failed.
typedef CreatedLogin = ({String uid, Future<void> Function() release, Future<void> Function() rollback});

/// Creates a Firebase Auth login for [email] / [password].
typedef LoginCreator = Future<CreatedLogin> Function(String email, String password);

final loginCreatorProvider = Provider<LoginCreator>((ref) => SecondaryAppLoginCreator().call);

final teacherRepositoryProvider = Provider<TeacherRepository>(
  (ref) => TeacherRepository(ref.watch(firestoreProvider), ref.watch(loginCreatorProvider)),
);

/// Result of creating a teacher account. The temporary password is shown to the
/// admin exactly once so it can be handed to the teacher.
typedef CreatedTeacher = ({String id, String temporaryPassword});

/// Creates teacher logins through a *secondary* FirebaseApp, so the admin's own
/// session on the default app is never replaced (no server needed).
class SecondaryAppLoginCreator {
  static const _appName = 'alwaqar-account-ops';
  static bool _emulatorConfigured = false;

  Future<FirebaseAuth> _auth() async {
    final existing = Firebase.apps.where((a) => a.name == _appName).firstOrNull;
    final app = existing ?? await Firebase.initializeApp(name: _appName, options: Firebase.app().options);
    final auth = FirebaseAuth.instanceFor(app: app);
    if (FirebaseConfig.useEmulator && !_emulatorConfigured) {
      await auth.useAuthEmulator(FirebaseConfig.emulatorHost, 9099, automaticHostMapping: false);
      _emulatorConfigured = true;
    }
    return auth;
  }

  Future<CreatedLogin> call(String email, String password) async {
    final auth = await _auth();
    final cred = await auth.createUserWithEmailAndPassword(email: email, password: password);
    final user = cred.user!;
    return (
      uid: user.uid,
      release: () => auth.signOut(),
      rollback: () async {
        try {
          await user.delete();
        } finally {
          await auth.signOut();
        }
      },
    );
  }
}

/// Teacher management, done entirely from the admin app (Firebase free plan).
///
/// Data model: `teachers/{teacherId}` is the teacher's permanent identity
/// (students and recitations point at it); `users/{authUid}` is a login linked
/// to it via `teacherId`. A password reset creates a new login for the same
/// teacher and retires the old one, so history is never touched.
class TeacherRepository {
  TeacherRepository(this._db, this._createLogin);

  final FirebaseFirestore _db;
  final LoginCreator _createLogin;

  static const authEmailDomain = 'teachers.alwaqar.app';

  CollectionReference<Map<String, dynamic>> get _teachers => _db.collection(Col.teachers);
  CollectionReference<Map<String, dynamic>> get _directory => _db.collection(Col.loginDirectory);
  CollectionReference<Map<String, dynamic>> get _users => _db.collection(Col.users);

  /// Initial password convention: first Arabic name + "123" (e.g. محمد123).
  /// Firebase requires 6+ characters, so very short names get "1234".
  static String initialPassword(String fullName) {
    final first = fullName.trim().split(RegExp(r'\s+')).first;
    final p = '${first}123';
    return p.length >= 6 ? p : '${first}1234';
  }

  static String _newAuthEmail() {
    final r = Random.secure();
    final id = List.generate(12, (_) => r.nextInt(16).toRadixString(16)).join();
    return 't.$id@$authEmailDomain';
  }

  static String _cleanName(String name) {
    final error = Validators.personName(name);
    if (error != null) throw AppFailure(error, code: 'invalid-argument');
    return name.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  Stream<List<Teacher>> watchTeachers({Department? department}) {
    Query<Map<String, dynamic>> q = _teachers;
    if (department != null) q = q.where('departmentId', isEqualTo: department.id);
    return q.snapshots().map((s) {
      final list = s.docs.map((d) => Teacher.fromJson(docToJson(d))).toList();
      list.sort((a, b) => a.displayName.compareTo(b.displayName));
      return list;
    });
  }

  Stream<Teacher?> watchTeacher(String id) =>
      _teachers.doc(id).snapshots().map((d) => d.exists ? Teacher.fromJson(docToJson(d)) : null);

  Future<DocumentSnapshot<Map<String, dynamic>>> _getTeacher(String id) async {
    final snap = await _teachers.doc(id).get();
    if (!snap.exists) throw const AppFailure('المعلم غير موجود', code: 'not-found');
    return snap;
  }

  Future<List<DocumentReference<Map<String, dynamic>>>> _loginsOf(String teacherId) async {
    final s = await _users.where('teacherId', isEqualTo: teacherId).get();
    return s.docs.map((d) => d.reference).toList();
  }

  void _setLoginProfile(WriteBatch b, String uid, {required String teacherId, required String name, required Department dep, required String email}) {
    b.set(_users.doc(uid), {
      'role': 'teacher',
      'displayName': name,
      'departmentId': dep.id,
      'teacherId': teacherId,
      'active': true,
      'mustChangePassword': true,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<CreatedTeacher> createTeacher({required String fullName, required Department department, String? phone}) async {
    final name = _cleanName(fullName);
    final password = initialPassword(name);
    final email = _newAuthEmail();
    final teacherRef = _teachers.doc();
    try {
      final login = await _createLogin(email, password);
      final b = _db.batch();
      b.set(teacherRef, {
        'displayName': name,
        'departmentId': department.id,
        'active': true,
        'studentCount': 0,
        'phone': (phone ?? '').trim().isEmpty ? null : phone!.trim(),
        'authUid': login.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      b.set(_directory.doc(teacherRef.id), {'displayName': name, 'departmentId': department.id, 'authEmail': email, 'active': true});
      _setLoginProfile(b, login.uid, teacherId: teacherRef.id, name: name, dep: department, email: email);
      try {
        await b.commit();
      } catch (_) {
        await login.rollback();
        rethrow;
      }
      await login.release();
      return (id: teacherRef.id, temporaryPassword: password);
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<void> updateTeacher({required String teacherId, required String fullName, required Department department, String? phone}) async {
    final name = _cleanName(fullName);
    try {
      final snap = await _getTeacher(teacherId);
      final depChanged = snap.get('departmentId') != department.id;
      if (depChanged && ((snap.data()?['studentCount'] as num?) ?? 0) > 0) {
        throw const AppFailure('لا يمكن تغيير قسم معلم لديه طلاب؛ انقل طلابه أولاً', code: 'failed-precondition');
      }
      final b = _db.batch();
      b.update(snap.reference, {
        'displayName': name,
        'departmentId': department.id,
        'phone': (phone ?? '').trim().isEmpty ? null : phone!.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      b.update(_directory.doc(teacherId), {'displayName': name, 'departmentId': department.id});
      for (final login in await _loginsOf(teacherId)) {
        b.update(login, {'displayName': name, 'departmentId': department.id});
      }
      await b.commit();

      // Keep the denormalized name on current students in sync.
      if (snap.get('displayName') != name) {
        final students = await _db.collection(Col.students).where('teacherId', isEqualTo: teacherId).get();
        for (var i = 0; i < students.docs.length; i += 400) {
          final sb = _db.batch();
          for (final d in students.docs.skip(i).take(400)) {
            sb.update(d.reference, {'teacherName': name, 'searchName': Fmt.searchKey(d.get('fullName') as String)});
          }
          await sb.commit();
        }
      }
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  /// Deactivated teachers can still sign in to Firebase Auth, but the security
  /// rules deny them everything and the app signs them out immediately.
  Future<void> setActive({required String teacherId, required bool active}) async {
    try {
      final snap = await _getTeacher(teacherId);
      final b = _db.batch();
      b.update(snap.reference, {'active': active, 'updatedAt': FieldValue.serverTimestamp()});
      b.update(_directory.doc(teacherId), {'active': active});
      final currentUid = snap.data()?['authUid'] as String?;
      for (final login in await _loginsOf(teacherId)) {
        // Only the current login is re-activated; retired logins stay off.
        if (active && login.id != currentUid) continue;
        b.update(login, {'active': active});
      }
      await b.commit();
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  /// Issues a new temporary login (first name + 123) for the same teacher and
  /// retires the previous one. Students and history are unaffected.
  Future<String> resetPassword(String teacherId) async {
    try {
      final snap = await _getTeacher(teacherId);
      final name = snap.get('displayName') as String;
      final dep = Department.tryParse(snap.get('departmentId'))!;
      final password = initialPassword(name);
      final email = _newAuthEmail();
      final login = await _createLogin(email, password);
      final b = _db.batch();
      for (final old in await _loginsOf(teacherId)) {
        b.update(old, {'active': false, 'replacedAt': FieldValue.serverTimestamp()});
      }
      _setLoginProfile(b, login.uid, teacherId: teacherId, name: name, dep: dep, email: email);
      b.update(snap.reference, {'authUid': login.uid, 'updatedAt': FieldValue.serverTimestamp()});
      b.update(_directory.doc(teacherId), {'authEmail': email});
      try {
        await b.commit();
      } catch (_) {
        await login.rollback();
        rethrow;
      }
      await login.release();
      return password;
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  /// Only possible when no students are assigned. Logins are retired, and
  /// recitation history keeps the teacher's name.
  Future<void> deleteTeacher(String teacherId) async {
    try {
      final snap = await _getTeacher(teacherId);
      final assigned = await _db.collection(Col.students).where('teacherId', isEqualTo: teacherId).count().get();
      if ((assigned.count ?? 0) > 0 || ((snap.data()?['studentCount'] as num?) ?? 0) > 0) {
        throw const AppFailure('لا يمكن حذف معلم لديه طلاب؛ انقل طلابه أولاً', code: 'failed-precondition');
      }
      final b = _db.batch();
      for (final login in await _loginsOf(teacherId)) {
        b.update(login, {'active': false, 'replacedAt': FieldValue.serverTimestamp()});
      }
      b.delete(_directory.doc(teacherId));
      b.delete(snap.reference);
      await b.commit();
    } catch (e) {
      throw AppFailure.from(e);
    }
  }
}
