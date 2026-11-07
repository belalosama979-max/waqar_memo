import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common.dart';
import '../../auth/application/session_providers.dart';
import '../../settings/data/settings_repository.dart';
import '../../students/application/student_providers.dart';
import '../../students/domain/student.dart';
import '../data/recitation_repository.dart';
import '../domain/evaluation.dart';
import '../domain/evaluation_settings.dart';
import '../domain/points_calculator.dart';
import '../domain/recitation.dart';
import 'portion_picker.dart';

class RecordRecitationScreen extends ConsumerStatefulWidget {
  const RecordRecitationScreen({super.key, required this.studentId});
  final String studentId;

  @override
  ConsumerState<RecordRecitationScreen> createState() => _RecordRecitationScreenState();
}

class _RecordRecitationScreenState extends ConsumerState<RecordRecitationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _extra = TextEditingController();

  /// One id per form: retries and double taps can never create duplicates.
  final String _draftId = const Uuid().v4();

  late String _studentId = widget.studentId;
  DateTime _date = DateTime.now();
  RecitationType _type = RecitationType.surah;
  int? _part;
  int? _surah;
  Evaluation? _evaluation;
  bool _submitting = false;
  bool _done = false;

  @override
  void dispose() {
    _extra.dispose();
    super.dispose();
  }

  int get _extraValue => Validators.parseIntOrZero(_extra.text);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      helpText: 'تاريخ التسميع',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickPortion() async {
    final n = await showPortionPicker(context, _type, selected: _type == RecitationType.juz ? _part : _surah);
    if (n == null) return;
    setState(() => _type == RecitationType.juz ? _part = n : _surah = n);
  }

  Future<void> _submit(Student student, EvaluationSettings settings) async {
    if (_submitting || _done) return; // duplicate submission guard
    final valid = _formKey.currentState!.validate();
    if (_type == RecitationType.juz && _part == null || _type == RecitationType.surah && _surah == null) {
      showAppSnack(context, _type == RecitationType.juz ? 'يرجى اختيار الجزء' : 'يرجى اختيار السورة', error: true);
      return;
    }
    if (_evaluation == null) {
      showAppSnack(context, 'يرجى اختيار التقييم', error: true);
      return;
    }
    if (!valid) return;
    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      showAppSnack(context, 'انتهت الجلسة، يرجى تسجيل الدخول مجدداً', error: true);
      return;
    }

    setState(() => _submitting = true);
    HapticFeedback.mediumImpact();
    try {
      final outcome = await ref.read(recitationRepositoryProvider).submit(
            RecitationDraft(
              id: _draftId,
              student: student,
              date: _date,
              type: _type,
              partNumber: _part,
              surahNumber: _surah,
              evaluation: _evaluation!,
              extraPoints: _extraValue,
            ),
            teacher: user,
            settings: settings,
          );
      _done = true;
      if (!mounted) return;
      showAppSnack(
        context,
        outcome == SubmitOutcome.synced
            ? 'تم تسجيل التسميع بنجاح ✓'
            : 'تم حفظ التسميع على الجهاز، وستتم مزامنته تلقائياً عند عودة الاتصال',
        success: true,
      );
      context.pop();
    } on AppFailure catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep the session alive while the form is open (used on submit).
    ref.watch(currentUserProvider);
    final settingsAsync = ref.watch(evaluationSettingsProvider);
    final studentsAsync = ref.watch(myStudentsProvider);
    final settings = settingsAsync.value ?? EvaluationSettings.defaults();

    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل تسميع')),
      body: AsyncBody(
        value: studentsAsync,
        data: (students) {
          final student = students.where((s) => s.id == _studentId).firstOrNull;
          if (student == null) {
            return const EmptyState(icon: Icons.person_off_rounded, title: 'الطالب غير موجود أو لم يعد مسنداً إليك');
          }
          final extraError = Validators.extraPoints(_extra.text, max: settings.maxExtraPoints);
          final pts = PointsCalculator.calculate(
            evaluation: _evaluation,
            extraPoints: extraError == null ? _extraValue : 0,
            settings: settings,
          );
          return Form(
            key: _formKey,
            child: MaxWidth(
              maxWidth: 720,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                children: [
                  _Label('الطالب'),
                  DropdownButtonFormField<String>(
                    key: const Key('rec_student'),
                    initialValue: student.id,
                    isExpanded: true,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.person_rounded)),
                    items: [
                      for (final s in (students.toList()..sort((a, b) => a.fullName.compareTo(b.fullName))))
                        DropdownMenuItem(value: s.id, child: Text(s.fullName)),
                    ],
                    onChanged: (v) => setState(() => _studentId = v ?? _studentId),
                  ),
                  _Label('التاريخ'),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.event_rounded)),
                      child: Text(Fmt.dateLong(_date)),
                    ),
                  ),
                  _Label('نوع التسميع'),
                  SegmentedButton<RecitationType>(
                    segments: const [
                      ButtonSegment(value: RecitationType.surah, label: Text('سورة'), icon: Icon(Icons.auto_stories_rounded)),
                      ButtonSegment(value: RecitationType.juz, label: Text('جزء'), icon: Icon(Icons.library_books_rounded)),
                    ],
                    selected: {_type},
                    onSelectionChanged: (s) => setState(() => _type = s.first),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    key: const Key('rec_portion'),
                    borderRadius: BorderRadius.circular(16),
                    onTap: _pickPortion,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: _type == RecitationType.juz ? 'الجزء' : 'السورة',
                        prefixIcon: const Icon(Icons.menu_book_rounded),
                        suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                      child: Text(
                        (_type == RecitationType.juz ? _part : _surah) == null
                            ? (_type == RecitationType.juz ? 'اختر من ٣٠ جزءاً' : 'اختر من ١١٤ سورة')
                            : Recitation.describePortion(_type, partNumber: _part, surahNumber: _surah),
                      ),
                    ),
                  ),
                  _Label('التقييم'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final e in Evaluation.values)
                        ChoiceChip(
                          key: Key('rec_eval_${e.name}'),
                          avatar: Icon(e.icon, size: 18, color: _evaluation == e ? Colors.white : e.color),
                          label: Text('${e.label} (${Fmt.digits(settings.pointsFor(e))})'),
                          selected: _evaluation == e,
                          selectedColor: e.color,
                          labelStyle: TextStyle(color: _evaluation == e ? Colors.white : null, fontWeight: FontWeight.w700),
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _evaluation = e),
                        ),
                    ],
                  ),
                  _Label('كمية إضافية'),
                  TextFormField(
                    key: const Key('rec_extra'),
                    controller: _extra,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9٠-٩]')), LengthLimitingTextInputFormatter(4)],
                    onChanged: (_) => setState(() {}),
                    validator: (v) => Validators.extraPoints(v, max: settings.maxExtraPoints),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      hintText: '٠',
                      helperText: 'نقاط إضافية يدخلها المعلم (الحد الأقصى ${Fmt.digits(settings.maxExtraPoints)})',
                      prefixIcon: const Icon(Icons.add_circle_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _PointsSummary(points: pts, evaluation: _evaluation),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: studentsAsync.value?.where((s) => s.id == _studentId).firstOrNull == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  key: const Key('rec_submit'),
                  onPressed: _submitting || settingsAsync.isLoading
                      ? null
                      : () => _submit(studentsAsync.value!.firstWhere((s) => s.id == _studentId), settings),
                  icon: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4))
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(_submitting ? 'جارٍ الحفظ...' : 'حفظ التسميع'),
                ),
              ),
            ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.emeraldDeep)),
      );
}

class _PointsSummary extends StatelessWidget {
  const _PointsSummary({required this.points, required this.evaluation});
  final SessionPoints points;
  final Evaluation? evaluation;

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('rec_summary'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            _cell('نقاط التقييم', points.evaluationPoints),
            const Text('+', style: TextStyle(color: AppColors.goldLight, fontSize: 24, fontWeight: FontWeight.w800)),
            _cell('كمية إضافية', points.extraPoints),
            const Text('=', style: TextStyle(color: AppColors.goldLight, fontSize: 24, fontWeight: FontWeight.w800)),
            _cell('مجموع الجلسة', points.total, highlight: true),
          ],
        ),
      );

  Widget _cell(String label, int value, {bool highlight = false}) => Expanded(
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Text(
                Fmt.number(value),
                key: ValueKey(value),
                style: TextStyle(
                  color: highlight ? AppColors.goldLight : Colors.white,
                  fontSize: highlight ? 28 : 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
          ],
        ),
      );
}
