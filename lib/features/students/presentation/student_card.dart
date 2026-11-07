import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../domain/student.dart';

/// Student card shown on the teacher dashboard.
class StudentCard extends StatelessWidget {
  const StudentCard({super.key, required this.student, this.onRecord, this.onProfile, this.showTeacher = false});
  final Student student;
  final VoidCallback? onRecord;
  final VoidCallback? onProfile;
  final bool showTeacher;

  @override
  Widget build(BuildContext context) {
    final s = student;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onProfile,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  NameAvatar(s.fullName),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                        if (showTeacher)
                          Text(s.teacherName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: muted)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.goldSoft, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Text(Fmt.number(s.totalPoints), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.emeraldDeep)),
                        const Text('مجموع النقاط', style: TextStyle(fontSize: 10, color: AppColors.inkSoft)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _Info(icon: Icons.menu_book_rounded, label: 'آخر تسميع', value: s.lastRecitationLabel ?? 'لا يوجد')),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Info(icon: Icons.event_rounded, label: 'تاريخ آخر تسميع', value: Fmt.relative(s.lastRecitationDate)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                      onPressed: onRecord,
                      icon: const Icon(Icons.add_task_rounded, size: 20),
                      label: const Text('تسجيل تسميع'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                      onPressed: onProfile,
                      icon: const Icon(Icons.person_outline_rounded, size: 20),
                      label: const Text('الملف الشخصي'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.emerald.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.emeraldLight),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
                  Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      );
}
