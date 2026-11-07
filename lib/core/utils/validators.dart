import 'formatters.dart';

/// Form validators returning Arabic error messages (null = valid).
abstract final class Validators {
  static String? requiredText(String? v, {String field = 'هذا الحقل'}) {
    if (v == null || v.trim().isEmpty) return '$field مطلوب';
    return null;
  }

  static String? personName(String? v) {
    final base = requiredText(v, field: 'الاسم');
    if (base != null) return base;
    final t = v!.trim();
    if (t.length < 2) return 'الاسم قصير جداً';
    if (t.length > 60) return 'الاسم طويل جداً';
    if (RegExp(r'[0-9٠-٩<>{}\[\]\\/]').hasMatch(t)) return 'الاسم يحتوي على رموز غير مسموحة';
    return null;
  }

  static String? email(String? v) {
    final base = requiredText(v, field: 'البريد الإلكتروني');
    if (base != null) return base;
    final ok = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$').hasMatch(v!.trim());
    return ok ? null : 'صيغة البريد الإلكتروني غير صحيحة';
  }

  static String? loginPassword(String? v) {
    if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
    return null;
  }

  /// Strong password policy for permanent passwords.
  static String? newPassword(String? v) {
    if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
    if (v.length < 8) return 'يجب ألا تقل كلمة المرور عن ٨ أحرف';
    if (!RegExp(r'[0-9٠-٩]').hasMatch(v)) return 'يجب أن تحتوي كلمة المرور على رقم واحد على الأقل';
    if (!RegExp(r'[^0-9٠-٩\s]').hasMatch(v)) return 'يجب أن تحتوي كلمة المرور على حروف';
    if (RegExp(r'^(.)\1+$').hasMatch(v)) return 'كلمة المرور ضعيفة جداً';
    return null;
  }

  static String? confirmPassword(String? v, String original) {
    if (v == null || v.isEmpty) return 'يرجى تأكيد كلمة المرور';
    if (v != original) return 'كلمتا المرور غير متطابقتين';
    return null;
  }

  /// Extra points: optional, whole number between 0 and [max].
  static String? extraPoints(String? v, {required int max}) {
    if (v == null || v.trim().isEmpty) return null;
    final parsed = int.tryParse(Fmt.normalizeDigits(v.trim()));
    if (parsed == null) return 'أدخل رقماً صحيحاً';
    if (parsed < 0) return 'لا يمكن أن تكون الكمية سالبة';
    if (parsed > max) return 'الحد الأقصى للكمية الإضافية ${Fmt.digits(max)}';
    return null;
  }

  static String? evaluationPoints(String? v) {
    if (v == null || v.trim().isEmpty) return 'القيمة مطلوبة';
    final parsed = int.tryParse(Fmt.normalizeDigits(v.trim()));
    if (parsed == null) return 'أدخل رقماً صحيحاً';
    if (parsed < 0 || parsed > 1000) return 'القيمة يجب أن تكون بين ٠ و ١٠٠٠';
    return null;
  }

  static int parseIntOrZero(String? v) => int.tryParse(Fmt.normalizeDigits((v ?? '').trim())) ?? 0;
}
