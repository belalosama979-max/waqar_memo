import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/firebase/json_converters.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/domain/enums.dart';
import '../../teachers/domain/teacher.dart';
import '../domain/student.dart';

final studentRepositoryProvider = Provider<StudentRepository>(
  (ref) => StudentRepository(ref.watch(firestoreProvider)),
);

/// A page of students for paginated admin lists.
class StudentPage {
  const StudentPage(this.students, this.cursor, {required this.hasMore});
  final List<Student> students;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
}

class StudentRepository {
  StudentRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection(Col.students);

  List<Student> _map(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map((d) => Student.fromJson(docToJson(d))).toList();

  /// Students assigned to one teacher. The department filter is required by
  /// the security rules (queries must be provably within the caller's department).
  Stream<List<Student>> watchTeacherStudents({required String teacherId, required Department department}) {
    return _col
        .where('departmentId', isEqualTo: department.id)
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map(_map);
  }

  /// All students of a department ordered by points (leaderboard).
  Stream<List<Student>> watchDepartmentLeaderboard(Department department, {int limit = 200}) {
    return _col
        .where('departmentId', isEqualTo: department.id)
        .orderBy('totalPoints', descending: true)
        .limit(limit)
        .snapshots()
        .map(_map);
  }

  /// Teacher leaderboard: the teacher's own students ordered by points.
  Stream<List<Student>> watchTeacherLeaderboard({required String teacherId, required Department department}) {
    return _col
        .where('departmentId', isEqualTo: department.id)
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('totalPoints', descending: true)
        .snapshots()
        .map(_map);
  }

  /// Admin: every student, optionally limited to one department.
  Stream<List<Student>> watchAllStudents({Department? department}) {
    Query<Map<String, dynamic>> q = _col;
    if (department != null) q = q.where('departmentId', isEqualTo: department.id);
    return q.snapshots().map(_map);
  }

  /// Admin: paginated fetch ordered by name.
  Future<StudentPage> fetchPage({
    Department? department,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int pageSize = 30,
  }) async {
    Query<Map<String, dynamic>> q = _col;
    if (department != null) q = q.where('departmentId', isEqualTo: department.id);
    q = q.orderBy('searchName').limit(pageSize);
    if (startAfter != null) q = q.startAfterDocument(startAfter);
    final snap = await q.get();
    return StudentPage(
      _map(snap),
      snap.docs.isEmpty ? startAfter : snap.docs.last,
      hasMore: snap.docs.length == pageSize,
    );
  }

  Stream<Student?> watchStudent(String id) =>
      _col.doc(id).snapshots().map((d) => d.exists ? Student.fromJson(docToJson(d)) : null);

  Future<String> addStudent({
    required String fullName,
    required Teacher teacher,
    String? guardianPhone,
    String? notes,
  }) async {
    try {
      final doc = _col.doc();
      final batch = _db.batch();
      batch.set(doc, {
        'fullName': fullName.trim(),
        'searchName': Fmt.searchKey(fullName),
        'teacherId': teacher.id,
        'teacherName': teacher.displayName,
        'departmentId': teacher.departmentId.id,
        'totalPoints': 0,
        'recitationCount': 0,
        'guardianPhone': guardianPhone?.trim(),
        'notes': notes?.trim(),
        'joinedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.update(_db.collection(Col.teachers).doc(teacher.id), {'studentCount': FieldValue.increment(1)});
      await batch.commit();
      return doc.id;
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<void> updateStudent({
    required String id,
    required String fullName,
    String? guardianPhone,
    String? notes,
  }) async {
    try {
      await _col.doc(id).update({
        'fullName': fullName.trim(),
        'searchName': Fmt.searchKey(fullName),
        'guardianPhone': guardianPhone?.trim(),
        'notes': notes?.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  /// Moves a student to another teacher (and that teacher's department).
  /// Past recitations keep the teacher snapshot they were recorded with.
  Future<void> transferStudent({required Student student, required Teacher newTeacher}) async {
    if (student.teacherId == newTeacher.id) {
      throw const AppFailure('الطالب مسجل لدى هذا المعلم بالفعل');
    }
    try {
      final batch = _db.batch();
      batch.update(_col.doc(student.id), {
        'teacherId': newTeacher.id,
        'teacherName': newTeacher.displayName,
        'departmentId': newTeacher.departmentId.id,
        'previousTeacherIds': FieldValue.arrayUnion([student.teacherId]),
        'transferredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.update(_db.collection(Col.teachers).doc(student.teacherId), {'studentCount': FieldValue.increment(-1)});
      batch.update(_db.collection(Col.teachers).doc(newTeacher.id), {'studentCount': FieldValue.increment(1)});
      await batch.commit();
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  /// Deletes the student profile. Recitation history is retained for audit.
  Future<void> deleteStudent(Student student) async {
    try {
      final batch = _db.batch();
      batch.delete(_col.doc(student.id));
      batch.update(_db.collection(Col.teachers).doc(student.teacherId), {'studentCount': FieldValue.increment(-1)});
      await batch.commit();
    } catch (e) {
      throw AppFailure.from(e);
    }
  }
}
