import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../auth/application/session_providers.dart';
import '../data/notifications_repository.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      body: user == null
          ? const LoadingView()
          : AsyncBody<List<AppNotification>>(
              value: ref.watch(notificationsProvider(user)),
              data: (list) => list.isEmpty
                  ? const EmptyState(icon: Icons.notifications_none_rounded, title: 'لا توجد إشعارات حالياً')
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => MaxWidth(maxWidth: 760, child: NotificationTile(n: list[i])),
                    ),
            ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.n, this.onDelete});
  final AppNotification n;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final icon = switch (n.type) {
      'milestone' => Icons.emoji_events_rounded,
      'system' => Icons.info_rounded,
      _ => Icons.campaign_rounded,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(backgroundColor: AppColors.gold.withValues(alpha: 0.15), child: Icon(icon, color: AppColors.gold)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(n.body, style: const TextStyle(height: 1.6)),
                  const SizedBox(height: 6),
                  Text(
                    '${Fmt.dateTime(n.createdAt)} • ${n.audienceLabel}',
                    style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(tooltip: 'حذف', onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger)),
          ],
        ),
      ),
    );
  }
}
