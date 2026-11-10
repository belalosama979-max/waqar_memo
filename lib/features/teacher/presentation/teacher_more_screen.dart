import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/common.dart';
import '../../../router/routes.dart';
import '../../auth/application/session_providers.dart';
import '../../auth/data/auth_repository.dart';

/// Account menu shared by teachers (and reused by admins in settings).
class AccountSection extends ConsumerWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.notifications_rounded, color: AppColors.emerald),
                title: const Text('الإشعارات'),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => context.push(Routes.notifications),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.password_rounded, color: AppColors.emerald),
                title: const Text('تغيير كلمة المرور'),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => context.push(Routes.changePassword),
              ),
              const Divider(height: 1),
              ListTile(
                key: const Key('logout_tile'),
                leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
                title: const Text('تسجيل الخروج', style: TextStyle(color: AppColors.danger)),
                onTap: () async {
                  final ok = await confirmDialog(context, title: 'تسجيل الخروج', message: 'هل تريد تسجيل الخروج من حسابك؟', confirmLabel: 'خروج');
                  if (!ok) return;
                  await ref.read(authRepositoryProvider).signOut();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TeacherMoreScreen extends ConsumerWidget {
  const TeacherMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: MaxWidth(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    NameAvatar(user?.displayName ?? '', radius: 30),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.displayName ?? '', style: Theme.of(context).textTheme.titleLarge),
                          Text('${user?.role.label ?? ''} • ${user?.departmentId?.label ?? ''}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const AccountSection(),
            const SizedBox(height: 32),
            const Center(child: BrandMark(size: 56)),
            const Center(child: Text('الوقار — الإصدار ١٫٠٫٠', style: TextStyle(color: AppColors.inkSoft, fontSize: 12))),
          ],
        ),
      ),
    );
  }
}
