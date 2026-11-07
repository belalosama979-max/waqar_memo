import 'package:intl/intl.dart';

/// Arabic-friendly formatting helpers.
abstract final class Fmt {
  static const _arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  /// Converts western digits to Arabic-Indic digits.
  static String digits(Object value) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (final unit in s.codeUnits) {
      if (unit >= 48 && unit <= 57) {
        buffer.write(_arabicDigits[unit - 48]);
      } else {
        buffer.writeCharCode(unit);
      }
    }
    return buffer.toString();
  }

  /// Converts Arabic-Indic / Persian digits typed by the user to western digits.
  static String normalizeDigits(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(48 + rune - 0x0660);
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(48 + rune - 0x06F0);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  static String points(int value) => '${digits(NumberFormat.decimalPattern('en').format(value))} نقطة';

  static String number(int value) => digits(NumberFormat.decimalPattern('en').format(value));

  static String date(DateTime? d) {
    if (d == null) return '—';
    return digits(DateFormat('yyyy/MM/dd').format(d));
  }

  static String dateLong(DateTime? d) {
    if (d == null) return '—';
    return DateFormat('EEEE d MMMM y', 'ar').format(d);
  }

  static String dateTime(DateTime? d) {
    if (d == null) return '—';
    return DateFormat('d MMMM y - h:mm a', 'ar').format(d);
  }

  static String relative(DateTime? d, {DateTime? now}) {
    if (d == null) return 'لم يسمّع بعد';
    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'أمس';
    if (diff == 2) return 'قبل يومين';
    if (diff > 2 && diff <= 10) return 'قبل ${digits(diff)} أيام';
    if (diff < 0) return date(d);
    return date(d);
  }

  /// Normalizes Arabic text for searching (removes diacritics, unifies alef/yaa/taa marbuta).
  static String searchKey(String input) {
    var s = input.trim().toLowerCase();
    s = s.replaceAll(RegExp('[ً-ْٰـ]'), '');
    s = s.replaceAll(RegExp('[إأآٱ]'), 'ا');
    s = s.replaceAll('ى', 'ي');
    s = s.replaceAll('ة', 'ه');
    s = s.replaceAll('ؤ', 'و');
    s = s.replaceAll('ئ', 'ي');
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s;
  }
}
