import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../data/pending_sync_store.dart';

/// Arabic synchronization status: offline, pending uploads, or rejected writes.
class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider).value ?? true;
    final sync = ref.watch(pendingSyncStoreProvider);

    if (sync.failed.isNotEmpty) {
      return _Bar(
        color: AppColors.danger,
        icon: Icons.sync_problem_rounded,
        text: 'تعذر حفظ ${Fmt.digits(sync.failed.length)} من التسميعات — اضغط للتفاصيل',
        onTap: () => _showFailed(context, ref),
      );
    }
    if (!online) {
      return _Bar(
        color: AppColors.warning,
        icon: Icons.cloud_off_rounded,
        text: sync.pending.isEmpty
            ? 'أنت غير متصل — يمكنك متابعة العمل وسيتم الحفظ تلقائياً'
            : 'غير متصل — ${Fmt.digits(sync.pending.length)} تسميع بانتظار المزامنة',
      );
    }
    if (sync.pending.isNotEmpty) {
      return _Bar(
        color: AppColors.info,
        icon: Icons.cloud_upload_rounded,
        text: 'جارٍ مزامنة ${Fmt.digits(sync.pending.length)} تسميع...',
        progress: true,
      );
    }
    return const SizedBox.shrink();
  }

  void _showFailed(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Consumer(builder: (ctx, ref, _) {
        final failed = ref.watch(pendingSyncStoreProvider).failed;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text('تسميعات لم تُحفظ', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 4),
              const Text('رفض الخادم هذه العمليات (مثلاً بسبب تغيير الصلاحيات أو قيم التقييم). يرجى تسجيلها مجدداً.'),
              const SizedBox(height: 8),
              for (final f in failed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.error_outline, color: AppColors.danger),
                  title: Text(f.title),
                  subtitle: Text(f.error ?? ''),
                  trailing: IconButton(
                    tooltip: 'إخفاء',
                    icon: const Icon(Icons.close),
                    onPressed: () => ref.read(pendingSyncStoreProvider.notifier).dismissFailed(f.id),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.color, required this.icon, required this.text, this.onTap, this.progress = false});
  final Color color;
  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final bool progress;

  @override
  Widget build(BuildContext context) => Material(
        color: color.withValues(alpha: 0.12),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                if (progress)
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: color))
                else
                  Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13))),
              ],
            ),
          ),
        ),
      );
}
