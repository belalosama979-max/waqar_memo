import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// A user-facing failure carrying an Arabic message.
class AppFailure implements Exception {
  const AppFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AppFailure($code): $message';

  /// Maps any thrown object to an [AppFailure] with an Arabic message.
  factory AppFailure.from(Object error) {
    if (error is AppFailure) return error;
    if (kDebugMode) debugPrint('[AppFailure] ${error.runtimeType}: $error');
    if (error is FirebaseAuthException) return AppFailure(_auth(error.code), code: error.code);
    if (error is FirebaseFunctionsException) {
      // Functions throw HttpsError with an Arabic message we control.
      final msg = error.message;
      if (msg != null && _containsArabic(msg)) return AppFailure(msg, code: error.code);
      return AppFailure(_generic(error.code), code: error.code);
    }
    if (error is FirebaseException) return AppFailure(_generic(error.code), code: error.code);
    if (error is SocketException) return const AppFailure('لا يوجد اتصال بالإنترنت', code: 'network');
    if (error is TimeoutException) return const AppFailure('انتهت مهلة الاتصال، حاول مرة أخرى', code: 'timeout');
    if (error is FormatException) return const AppFailure('البيانات المدخلة غير صالحة', code: 'format');
    return const AppFailure('حدث خطأ غير متوقع، حاول مرة أخرى', code: 'unknown');
  }

  static bool _containsArabic(String s) => RegExp('[؀-ۿ]').hasMatch(s);

  static String _auth(String code) => switch (code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' ||
        'invalid-email' =>
          'بيانات الدخول غير صحيحة',
        'user-disabled' => 'تم إيقاف هذا الحساب، يرجى التواصل مع الإدارة',
        'too-many-requests' => 'محاولات كثيرة، يرجى الانتظار قليلاً ثم المحاولة مجدداً',
        'network-request-failed' => 'تعذر الاتصال بالخادم، تحقق من الإنترنت',
        'weak-password' => 'كلمة المرور ضعيفة',
        'requires-recent-login' => 'يرجى تسجيل الدخول مجدداً لإتمام العملية',
        'email-already-in-use' => 'هذا البريد مستخدم مسبقاً',
        'operation-not-allowed' => 'طريقة الدخول غير مفعلة في الخادم',
        _ => 'تعذر تسجيل الدخول، حاول مرة أخرى',
      };

  static String _generic(String code) => switch (code) {
        'permission-denied' => 'ليست لديك صلاحية لتنفيذ هذا الإجراء',
        'unauthenticated' => 'انتهت الجلسة، يرجى تسجيل الدخول مجدداً',
        'unavailable' => 'الخادم غير متاح حالياً، سيتم المحاولة لاحقاً',
        'not-found' => 'العنصر المطلوب غير موجود',
        'already-exists' => 'هذا العنصر موجود مسبقاً',
        'failed-precondition' => 'لا يمكن تنفيذ العملية في الحالة الحالية',
        'invalid-argument' => 'البيانات المدخلة غير صالحة',
        'deadline-exceeded' => 'انتهت مهلة الاتصال، حاول مرة أخرى',
        'resource-exhausted' => 'تم تجاوز الحد المسموح، حاول لاحقاً',
        'cancelled' => 'تم إلغاء العملية',
        _ => 'حدث خطأ غير متوقع، حاول مرة أخرى',
      };
}
