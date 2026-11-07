import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common.dart';
import '../../recitations/domain/evaluation.dart';
import '../../recitations/domain/evaluation_settings.dart';
import '../../settings/data/settings_repository.dart';

class EvaluationSettingsScreen extends ConsumerStatefulWidget {
  const EvaluationSettingsScreen({super.key});

  @override
  ConsumerState<EvaluationSettingsScreen> createState() => _EvaluationSettingsScreenState();
}

class _EvaluationSettingsScreenState extends ConsumerState<EvaluationSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = {for (final e in Evaluation.values) e: TextEditingController()};
  final _maxExtra = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _maxExtra.dispose();
    super.dispose();
  }

  void _fill(EvaluationSettings s) {
    for (final e in Evaluation.values) {
      _controllers[e]!.text = s.pointsFor(e).toString();
    }
    _maxExtra.text = s.maxExtraPoints.toString();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await confirmDialog(
      context,
      title: 'حفظ قيم التقييم',
      message: 'ستُطبق القيم الجديدة على التسميعات القادمة فقط، ولن تتغير نقاط السجلات السابقة.',
      confirmLabel: 'حفظ',
    );
    if (!ok) return;
    setState(() => _saving = true);
    try {
      await ref.read(settingsRepositoryProvider).saveEvaluationSettings(
            EvaluationSettings(
              points: {for (final e in Evaluation.values) e: Validators.parseIntOrZero(_controllers[e]!.text)},
              maxExtraPoints: Validators.parseIntOrZero(_maxExtra.text),
            ),
          );
      if (!mounted) return;
      showAppSnack(context, 'تم حفظ قيم التقييم', success: true);
      context.pop();
    } on AppFailure catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(evaluationSettingsProvider);
    if (!_loaded && settings.hasValue) {
      _fill(settings.value!);
      _loaded = true;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('نقاط التقييم'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _fill(EvaluationSettings.defaults())),
            child: const Text('القيم الافتراضية'),
          ),
        ],
      ),
      body: !_loaded
          ? AsyncBody(value: settings, data: (_) => const SizedBox())
          : Form(
              key: _formKey,
              child: MaxWidth(
                maxWidth: 640,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final e in Evaluation.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          key: Key('eval_${e.name}'),
                          controller: _controllers[e],
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9٠-٩]'))],
                          validator: Validators.evaluationPoints,
                          decoration: InputDecoration(
                            labelText: e.label,
                            prefixIcon: Icon(e.icon, color: e.color),
                            suffixText: 'نقطة',
                            helperText: 'الافتراضي: ${Fmt.digits(e.defaultPoints)}',
                          ),
                        ),
                      ),
                    const Divider(height: 24),
                    TextFormField(
                      controller: _maxExtra,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9٠-٩]'))],
                      validator: Validators.evaluationPoints,
                      decoration: const InputDecoration(
                        labelText: 'الحد الأقصى للكمية الإضافية في الجلسة',
                        prefixIcon: Icon(Icons.add_circle_outline_rounded, color: AppColors.gold),
                        suffixText: 'نقطة',
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('eval_save'),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
                          : const Text('حفظ'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
