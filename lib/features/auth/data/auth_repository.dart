import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/firebase/json_converters.dart';
import '../../teachers/domain/teacher.dart';
import '../domain/app_user.dart';
import '../domain/enums.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
    ref.watch(secureStorageProvider),
  ),
);

class AuthRepository {
  AuthRepository(this._auth, this._db, this._secure);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FlutterSecureStorage _secure;

  static const _kLastTeacherId = 'last_teacher_id';
  static const _kLastDepartment = 'last_department';

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  /// Live profile of the signed-in user, or null when signed out.
  Stream<AppUser?> watchProfile(String uid) {
    return _db.collection(Col.users).doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromJson(docToJson(doc));
    });
  }

  /// Teachers available on the login screen for one department.
  Stream<List<LoginDirectoryEntry>> watchLoginDirectory(Department department) {
    return _db
        .collection(Col.loginDirectory)
        .where('departmentId', isEqualTo: department.id)
        .where('active', isEqualTo: true)
        .snapshots()
        .map((s) {
      final list = s.docs.map((d) => LoginDirectoryEntry.fromJson(docToJson(d))).toList();
      list.sort((a, b) => a.displayName.compareTo(b.displayName));
      return list;
    });
  }

  Future<void> signInAdmin({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      await _verifyRole(UserRole.admin);
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<void> signInTeacher({required LoginDirectoryEntry teacher, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: teacher.authEmail, password: password);
      await _verifyRole(UserRole.teacher);
      await _secure.write(key: _kLastTeacherId, value: teacher.id);
      await _secure.write(key: _kLastDepartment, value: teacher.departmentId.id);
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  /// Ensures the signed-in account's profile has the expected role and is
  /// active; signs out otherwise. (Rules enforce the same on the server.)
  Future<void> _verifyRole(UserRole expected) async {
    final user = _auth.currentUser;
    if (user == null) throw const AppFailure('تعذر تسجيل الدخول');
    final profile = (await _db.collection(Col.users).doc(user.uid).get()).data();
    if (profile == null || profile['active'] != true) {
      await _auth.signOut();
      throw const AppFailure('تم إيقاف هذا الحساب، يرجى التواصل مع الإدارة', code: 'user-disabled');
    }
    final role = UserRole.tryParse(profile['role']);
    if (role != expected) {
      await _auth.signOut();
      throw AppFailure(
        expected == UserRole.admin ? 'هذا الحساب ليس حساب إدارة' : 'هذا الحساب ليس حساب معلم',
        code: 'wrong-role',
      );
    }
  }

  Future<({String? teacherId, Department? department})> lastTeacherLogin() async {
    try {
      final id = await _secure.read(key: _kLastTeacherId);
      final dep = await _secure.read(key: _kLastDepartment);
      return (teacherId: id, department: Department.tryParse(dep));
    } catch (_) {
      return (teacherId: null, department: null);
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Changes the password after re-authenticating and clears the first-login flag.
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw const AppFailure('انتهت الجلسة، يرجى تسجيل الدخول مجدداً');
    if (currentPassword == newPassword) {
      throw const AppFailure('كلمة المرور الجديدة يجب أن تختلف عن الحالية');
    }
    try {
      final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      // Clear the first-login flag (the rules only allow true -> false on
      // one's own profile). The router then leaves the forced-change screen.
      final profileRef = _db.collection(Col.users).doc(user.uid);
      final mustChange = (await profileRef.get()).data()?['mustChangePassword'] == true;
      await profileRef.update({
        if (mustChange) 'mustChangePassword': false,
        'passwordChangedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw const AppFailure('كلمة المرور الحالية غير صحيحة', code: 'wrong-password');
      }
      throw AppFailure.from(e);
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  /// Whether the one-time admin setup has been done (public document).
  Stream<bool> watchAdminBootstrapped() => _db
      .collection(Col.appSettings)
      .doc('bootstrap')
      .snapshots()
      .map((d) => d.exists);

  /// First-run setup: creates the very first admin account. The security rules
  /// allow this only while `app_settings/bootstrap` does not exist.
  Future<void> createFirstAdmin({required String displayName, required String email, required String password}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      final uid = cred.user!.uid;
      final b = _db.batch();
      b.set(_db.collection(Col.users).doc(uid), {
        'role': 'admin',
        'displayName': displayName.trim(),
        'departmentId': null,
        'active': true,
        'mustChangePassword': false,
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      b.set(_db.collection(Col.appSettings).doc('bootstrap'), {
        'adminUid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      try {
        await b.commit();
      } catch (e) {
        // Setup already done by someone else (or rejected): remove the login.
        await cred.user?.delete();
        if (e is FirebaseException && e.code == 'permission-denied') {
          throw const AppFailure('تم إعداد حساب الإدارة مسبقاً', code: 'already-exists');
        }
        rethrow;
      }
      // Now an admin: seed reference data (rules check admin status before a
      // batch, so this cannot be part of the batch above).
      final seed = _db.batch();
      seed.set(_db.collection(Col.departments).doc('male'), {'name': 'قسم الذكور'});
      seed.set(_db.collection(Col.departments).doc('female'), {'name': 'قسم الإناث'});
      seed.set(_db.collection(Col.evaluationSettings).doc('default'), {
        'points': {'excellentPlus': 60, 'excellent': 40, 'veryGood': 25, 'notRecited': 0, 'repeat': 10},
        'maxExtraPoints': 100,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await seed.commit();
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.setLanguageCode('ar');
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      throw AppFailure.from(e);
    }
  }
}
