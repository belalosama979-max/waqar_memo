import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/firebase/json_converters.dart';
import '../../auth/domain/enums.dart';
import '../domain/teacher.dart';

final teacherRepositoryProvider = Provider<TeacherRepository>(
  (ref) => TeacherRepository(ref.watch(firestoreProvider), ref.watch(functionsProvider)),
);

/// Result of creating a teacher account. The temporary password is shown to the
/// admin exactly once so it can be handed to the teacher.
typedef CreatedTeacher = ({String id, String temporaryPassword});

/// Teacher management. Account operations go through Cloud Functions because
/// they require the Admin SDK (creating auth users, custom claims, disabling).
class TeacherRepository {
  TeacherRepository(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  Stream<List<Teacher>> watchTeachers({Department? department}) {
    Query<Map<String, dynamic>> q = _db.collection(Col.teachers);
    if (department != null) q = q.where('departmentId', isEqualTo: department.id);
    return q.snapshots().map((s) {
      final list = s.docs.map((d) => Teacher.fromJson(docToJson(d))).toList();
      list.sort((a, b) => a.displayName.compareTo(b.displayName));
      return list;
    });
  }

  Stream<Teacher?> watchTeacher(String id) => _db
      .collection(Col.teachers)
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Teacher.fromJson(docToJson(d)) : null);

  Future<T> _call<T>(String name, Map<String, dynamic> data) async {
    try {
      final result = await _functions.httpsCallable(name).call<Map<String, dynamic>>(data);
      return result.data as T;
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<CreatedTeacher> createTeacher({
    required String fullName,
    required Department department,
    String? phone,
  }) async {
    final data = await _call<Map<String, dynamic>>('createTeacher', {
      'fullName': fullName.trim(),
      'departmentId': department.id,
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
    });
    return (id: data['id'] as String, temporaryPassword: data['temporaryPassword'] as String);
  }

  Future<void> updateTeacher({
    required String teacherId,
    required String fullName,
    required Department department,
    String? phone,
  }) =>
      _call<Map<String, dynamic>>('updateTeacher', {
        'teacherId': teacherId,
        'fullName': fullName.trim(),
        'departmentId': department.id,
        'phone': phone?.trim() ?? '',
      });

  Future<void> setActive({required String teacherId, required bool active}) =>
      _call<Map<String, dynamic>>('setTeacherActive', {'teacherId': teacherId, 'active': active});

  /// Resets to the initial convention password and forces a change on next login.
  Future<String> resetPassword(String teacherId) async {
    final data = await _call<Map<String, dynamic>>('resetTeacherPassword', {'teacherId': teacherId});
    return data['temporaryPassword'] as String;
  }

  Future<void> deleteTeacher(String teacherId) =>
      _call<Map<String, dynamic>>('deleteTeacher', {'teacherId': teacherId});
}
