import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common.dart';
import '../../auth/application/session_providers.dart';
import '../../notifications/data/notifications_repository.dart';
import '../../notifications/presentation/notifications_screen.dart';

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  String _audience = 'all';
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    setState(() => _sending = true);
    try {
      await ref.read(notificationsRepositoryProvider).sendAnnouncement(
            title: _title.text,
            body: _body.text,
            audience: _audience,
            adminId: user.id,
          );
      _title.clear();
      _body.clear();
      if (mounted) showAppSnack(context, 'تم إرسال الإعلان', success: true);
    } on AppFailure catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('الإعلانات')),
      body: MaxWidth(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('إعلان جديد', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _title,
                        maxLength: 80,
                        validator: (v) => Validators.requiredText(v, field: 'العنوان'),
                        decoration: const InputDecoration(labelText: 'العنوان'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _body,
                        maxLines: 4,
                        maxLength: 500,
                        validator: (v) => Validators.requiredText(v, field: 'نص الإعلان'),
                        decoration: const InputDecoration(labelText: 'نص الإعلان'),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _audience,
                        decoration: const InputDecoration(labelText: 'إرسال إلى'),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('جميع المعلمين')),
                          DropdownMenuItem(value: 'dept_male', child: Text('معلمو قسم الذكور')),
                          DropdownMenuItem(value: 'dept_female', child: Text('معلمات قسم الإناث')),
                        ],
                        onChanged: (v) => setState(() => _audience = v ?? 'all'),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _sending ? null : _send,
                        icon: const Icon(Icons.send_rounded),
                        label: Text(_sending ? 'جارٍ الإرسال...' : 'إرسال'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SectionTitle('الإعلانات السابقة'),
            if (user != null)
              AsyncBody<List<AppNotification>>(
                value: ref.watch(notificationsProvider(user)),
                data: (list) => list.isEmpty
                    ? const EmptyState(title: 'لا توجد إعلانات بعد', icon: Icons.campaign_rounded)
                    : Column(
                        children: [
                          for (final n in list)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: NotificationTile(
                                n: n,
                                onDelete: () async {
                                  final ok = await confirmDialog(context, title: 'حذف الإعلان', message: 'هل تريد حذف هذا الإعلان؟', destructive: true, confirmLabel: 'حذف');
                                  if (!ok) return;
                                  try {
                                    await ref.read(notificationsRepositoryProvider).delete(n.id);
                                  } on AppFailure catch (e) {
                                    if (context.mounted) showAppSnack(context, e.message, error: true);
                                  }
                                },
                              ),
                            ),
                        ],
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
