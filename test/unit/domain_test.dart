import 'package:alwaqar/core/constants/quran_data.dart';
import 'package:alwaqar/core/utils/formatters.dart';
import 'package:alwaqar/core/utils/validators.dart';
import 'package:alwaqar/features/recitations/domain/evaluation.dart';
import 'package:alwaqar/features/recitations/domain/evaluation_settings.dart';
import 'package:alwaqar/features/recitations/domain/points_calculator.dart';
import 'package:alwaqar/features/recitations/domain/recitation.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;

void main() {
  group('Evaluation defaults', () {
    test('match the specification', () {
      expect(Evaluation.excellentPlus.defaultPoints, 60);
      expect(Evaluation.excellent.defaultPoints, 40);
      expect(Evaluation.veryGood.defaultPoints, 25);
      expect(Evaluation.notRecited.defaultPoints, 0);
      expect(Evaluation.repeat.defaultPoints, 10);
    });

    test('Arabic labels', () {
      expect(Evaluation.values.map((e) => e.label), ['ممتاز جداً', 'ممتاز', 'جيد جداً', 'لم يسمع', 'رجع في التسميع']);
    });
  });

  group('PointsCalculator', () {
    final defaults = EvaluationSettings.defaults();

    test('total = evaluation points + extra points', () {
      for (final e in Evaluation.values) {
        final r = PointsCalculator.calculate(evaluation: e, extraPoints: 7, settings: defaults);
        expect(r.evaluationPoints, e.defaultPoints);
        expect(r.extraPoints, 7);
        expect(r.total, e.defaultPoints + 7);
      }
    });

    test('uses admin-modified values', () {
      final custom = defaults.copyWith(points: {...defaults.points, Evaluation.excellent: 45});
      expect(PointsCalculator.calculate(evaluation: Evaluation.excellent, extraPoints: 0, settings: custom).total, 45);
    });

    test('no evaluation yet → only extra counted', () {
      expect(PointsCalculator.calculate(evaluation: null, extraPoints: 3, settings: defaults).total, 3);
    });

    test('rejects negative or excessive extra points', () {
      expect(() => PointsCalculator.calculate(evaluation: Evaluation.excellent, extraPoints: -1, settings: defaults), throwsArgumentError);
      expect(() => PointsCalculator.calculate(evaluation: Evaluation.excellent, extraPoints: 101, settings: defaults), throwsArgumentError);
      expect(PointsCalculator.calculate(evaluation: Evaluation.excellent, extraPoints: 100, settings: defaults).total, 140);
    });
  });

  group('EvaluationSettings', () {
    test('fromMap falls back to defaults for missing values', () {
      final s = EvaluationSettings.fromMap({'points': {'excellent': 50}});
      expect(s.pointsFor(Evaluation.excellent), 50);
      expect(s.pointsFor(Evaluation.excellentPlus), 60);
      expect(s.maxExtraPoints, 100);
      expect(EvaluationSettings.fromMap(null).pointsFor(Evaluation.repeat), 10);
    });

    test('round-trips through toMap', () {
      final s = EvaluationSettings.fromMap(EvaluationSettings.defaults().copyWith(maxExtraPoints: 30).toMap());
      expect(s.maxExtraPoints, 30);
      expect(s.points, EvaluationSettings.defaults().points);
    });
  });

  group('QuranData', () {
    test('114 surahs in mushaf order', () {
      expect(QuranData.surahs.length, 114);
      expect(QuranData.surahName(1), 'الفاتحة');
      expect(QuranData.surahName(2), 'البقرة');
      expect(QuranData.surahName(18), 'الكهف');
      expect(QuranData.surahName(36), 'يس');
      expect(QuranData.surahName(67), 'الملك');
      expect(QuranData.surahName(78), 'النبأ');
      expect(QuranData.surahName(112), 'الإخلاص');
      expect(QuranData.surahName(114), 'الناس');
      expect(QuranData.surahs.toSet().length, 114, reason: 'names must be unique');
    });

    test('30 ajzaa', () {
      expect(QuranData.juzOrdinals.length, 30);
      expect(QuranData.juzOpenings.length, 30);
      expect(QuranData.juzName(1), 'الجزء الأول');
      expect(QuranData.juzName(30), 'الجزء الثلاثون');
      expect(QuranData.juzOpening(30), 'عم');
    });

    test('out of range throws', () {
      expect(() => QuranData.surahName(0), throwsRangeError);
      expect(() => QuranData.surahName(115), throwsRangeError);
      expect(() => QuranData.juzName(31), throwsRangeError);
    });

    test('portion labels', () {
      expect(Recitation.describePortion(RecitationType.surah, surahNumber: 67), 'سورة الملك');
      expect(Recitation.describePortion(RecitationType.juz, partNumber: 29), 'الجزء التاسع والعشرون');
      expect(Recitation.describePortion(RecitationType.surah), 'سورة');
    });
  });

  group('Validators', () {
    test('extra points', () {
      expect(Validators.extraPoints('', max: 100), isNull);
      expect(Validators.extraPoints('15', max: 100), isNull);
      expect(Validators.extraPoints('١٥', max: 100), isNull, reason: 'Arabic-Indic digits accepted');
      expect(Validators.extraPoints('-1', max: 100), isNotNull);
      expect(Validators.extraPoints('abc', max: 100), isNotNull);
      expect(Validators.extraPoints('101', max: 100), contains('الحد الأقصى'));
    });

    test('new password policy', () {
      expect(Validators.newPassword('short1'), isNotNull);
      expect(Validators.newPassword('abcdefgh'), isNotNull);
      expect(Validators.newPassword('12345678'), isNotNull);
      expect(Validators.newPassword('محمد2026سر'), isNull);
      expect(Validators.newPassword('Salam2026'), isNull);
    });

    test('confirm password', () {
      expect(Validators.confirmPassword('a', 'b'), 'كلمتا المرور غير متطابقتين');
      expect(Validators.confirmPassword('a', 'a'), isNull);
    });

    test('names', () {
      expect(Validators.personName(''), isNotNull);
      expect(Validators.personName('ع'), isNotNull);
      expect(Validators.personName('عمر123'), isNotNull);
      expect(Validators.personName('عمر سعيد'), isNull);
    });

    test('email', () {
      expect(Validators.email('admin@alwaqar.test'), isNull);
      expect(Validators.email('admin@'), isNotNull);
    });
  });

  group('Fmt', () {
    test('Arabic-Indic digits', () {
      expect(Fmt.digits(2026), '٢٠٢٦');
      expect(Fmt.normalizeDigits('٣٤۵'), '345');
      expect(Fmt.number(12500), '١٢,٥٠٠');
    });

    test('search key normalizes Arabic variants', () {
      expect(Fmt.searchKey('أحمد'), Fmt.searchKey('احمد'));
      expect(Fmt.searchKey('فاطمة'), Fmt.searchKey('فاطمه'));
      expect(Fmt.searchKey('مُحَمَّد'), 'محمد');
      expect(Fmt.searchKey('هدى'), Fmt.searchKey('هدي'));
    });

    test('relative dates', () {
      final now = DateTime(2026, 11, 7, 15);
      expect(Fmt.relative(DateTime(2026, 11, 7, 9), now: now), 'اليوم');
      expect(Fmt.relative(DateTime(2026, 11, 6), now: now), 'أمس');
      expect(Fmt.relative(DateTime(2026, 11, 2), now: now), 'قبل ٥ أيام');
      expect(Fmt.relative(null, now: now), 'لم يسمّع بعد');
    });
  });
}
