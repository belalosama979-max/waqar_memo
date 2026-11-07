import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/common.dart';
import '../../../router/routes.dart';
import '../../auth/application/session_providers.dart';
import '../../settings/data/settings_repository.dart';
import '../../teacher/presentation/teacher_more_screen.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final app = ref.watch(appSettingsProvider).value ?? const AppSettings();
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: MaxWidth(
        maxWidth: 680,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: NameAvatar(user?.displayName ?? ''),
                title: Text(user?.displayName ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(user?.email ?? 'المشرف العام', textDirection: TextDirection.ltr, textAlign: TextAlign.end),
              ),
            ),
            const SectionTitle('إعدادات النظام'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.tune_rounded, color: AppColors.emerald),
                    title: const Text('نقاط التقييم'),
                    subtitle: const Text('تعديل قيم ممتاز جداً، ممتاز، جيد جداً...'),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () => context.push(Routes.evaluationSettings),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.campaign_rounded, color: AppColors.emerald),
                    title: const Text('الإعلانات والإشعارات'),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () => context.push(Routes.announcements),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.mosque_rounded, color: AppColors.emerald),
                    title: const Text('اسم الجهة'),
                    subtitle: Text(app.academyName),
                    trailing: const Icon(Icons.edit_rounded),
                    onTap: () => _editGeneral(context, ref, app),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.flag_rounded, color: AppColors.emerald),
                    title: const Text('تنبيه الإنجاز كل'),
                    subtitle: Text(Fmt.points(app.milestoneStep)),
                    trailing: const Icon(Icons.edit_rounded),
                    onTap: () => _editGeneral(context, ref, app),
                  ),
                ],
              ),
            ),
            const SectionTitle('الحساب'),
            const AccountSection(),
            const SizedBox(height: 28),
            const Center(child: BrandMark(size: 56)),
            const Center(child: Text('الوقار — الإصدار ١٫٠٫٠', style: TextStyle(color: AppColors.inkSoft, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  Future<void> _editGeneral(BuildContext context, WidgetRef ref, AppSettings app) async {
    final name = TextEditingController(text: app.academyName);
    final step = TextEditingController(text: app.milestoneStep.toString());
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('الإعدادات العامة'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                validator: (v) => Validators.requiredText(v, field: 'اسم الجهة'),
                decoration: const InputDecoration(labelText: 'اسم الجهة / الحلقات'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: step,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9٠-٩]'))],
                validator: (v) {
                  final n = Validators.parseIntOrZero(v);
                  return n < 50 || n > 100000 ? 'أدخل قيمة بين ٥٠ و ١٠٠٠٠٠' : null;
                },
                decoration: const InputDecoration(labelText: 'تنبيه المعلم عند كل (نقطة)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (saved == true) {
      try {
        await ref.read(settingsRepositoryProvider).saveAppSettings(
              academyName: name.text,
              milestoneStep: Validators.parseIntOrZero(step.text),
            );
        if (context.mounted) showAppSnack(context, 'تم الحفظ', success: true);
      } on AppFailure catch (e) {
        if (context.mounted) showAppSnack(context, e.message, error: true);
      }
    }
    name.dispose();
    step.dispose();
  }
}
