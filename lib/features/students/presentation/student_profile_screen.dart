import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/common.dart';
import '../../../router/routes.dart';
import '../../analytics/domain/analytics.dart';
import '../../analytics/presentation/charts.dart';
import '../../auth/application/session_providers.dart';
import '../../exports/export_service.dart';
import '../../recitations/data/recitation_repository.dart';
import '../../recitations/domain/recitation.dart';
import '../application/student_providers.dart';
import '../domain/student.dart';

class StudentProfileScreen extends ConsumerStatefulWidget {
  const StudentProfileScreen({super.key, required this.studentId});
  final String studentId;

  @override
  ConsumerState<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends ConsumerState<StudentProfileScreen> {
  int _limit = 30;
  bool _exporting = false;

  Future<void> _export(Student s, {required bool print}) async {
    setState(() => _exporting = true);
    try {
      final history = await ref
          .read(recitationRepositoryProvider)
          .watchStudentHistory(studentId: s.id, department: s.departmentId, limit: 2000)
          .first;
      final svc = ref.read(exportServiceProvider);
      final bytes = await svc.studentReportPdf(s, history);
      final name = 'تقرير-${s.fullName}.pdf';
      if (print) {
        await svc.printPdf(bytes, name);
      } else {
        await svc.shareFile(bytes, name, mime: 'application/pdf');
      }
    } catch (e) {
      if (mounted) showAppSnack(context, AppFailure.from(e).message, error: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _delete(Recitation r) async {
    final ok = await confirmDialog(
      context,
      title: 'حذف التسميع',
      message: 'سيتم حذف «${r.portionLabel}» بتاريخ ${Fmt.date(r.recitationDate)} وخصم ${Fmt.number(r.totalPoints)} نقطة من مجموع الطالب. هل تريد المتابعة؟',
      confirmLabel: 'حذف',
      destructive: true,
    );
    if (!ok) return;
    try {
      await ref.read(recitationRepositoryProvider).deleteRecitation(r);
      if (mounted) showAppSnack(context, 'تم حذف التسميع', success: true);
    } on AppFailure catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final studentAsync = ref.watch(studentProvider(widget.studentId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        actions: [
          if (studentAsync.value != null)
            PopupMenuButton<String>(
              tooltip: 'تصدير',
              icon: _exporting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.ios_share_rounded),
              enabled: !_exporting,
              onSelected: (v) => _export(studentAsync.value!, print: v == 'print'),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'share', child: ListTile(leading: Icon(Icons.picture_as_pdf_rounded), title: Text('مشاركة تقرير PDF'))),
                PopupMenuItem(value: 'print', child: ListTile(leading: Icon(Icons.print_rounded), title: Text('طباعة التقرير'))),
              ],
            ),
        ],
      ),
      body: AsyncBody<Student?>(
        value: studentAsync,
        data: (student) {
          if (student == null) return const EmptyState(icon: Icons.person_off_rounded, title: 'الطالب غير موجود');
          final historyAsync = ref.watch(studentHistoryProvider((studentId: student.id, department: student.departmentId, limit: _limit)));
          final history = historyAsync.value ?? const <Recitation>[];
          final canRecord = user != null && user.isTeacher && user.teacherKey == student.teacherId;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Header(student: student)),
              SliverToBoxAdapter(
                child: MaxWidth(
                  maxWidth: 1000,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (canRecord)
                          FilledButton.icon(
                            onPressed: () => context.push(Routes.recordRecitation(student.id)),
                            icon: const Icon(Icons.add_task_rounded),
                            label: const Text('تسجيل تسميع جديد'),
                          ),
                        const SectionTitle('تقدم النقاط'),
                        ChartCard(title: 'النقاط التراكمية', child: PointsLineChart(points: Analytics.cumulativePoints(history))),
                        const SectionTitle('إحصاءات التقييم'),
                        ChartCard(title: 'توزيع التقييمات', child: EvaluationPieChart(breakdown: Analytics.evaluationBreakdown(history))),
                        SectionTitle('سجل التسميع', trailing: Text(Fmt.digits(student.recitationCount))),
                      ],
                    ),
                  ),
                ),
              ),
              if (historyAsync.isLoading && history.isEmpty)
                const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(24), child: LoadingView()))
              else if (historyAsync.hasError && history.isEmpty)
                SliverToBoxAdapter(child: ErrorView(error: historyAsync.error!))
              else if (history.isEmpty)
                const SliverToBoxAdapter(child: EmptyState(icon: Icons.history_rounded, title: 'لا يوجد تسميع مسجل بعد'))
              else
                SliverList.builder(
                  itemCount: history.length,
                  itemBuilder: (_, i) => MaxWidth(
                    maxWidth: 1000,
                    child: _TimelineTile(
                      r: history[i],
                      first: i == 0,
                      last: i == history.length - 1,
                      onDelete: user?.isAdmin == true ? () => _delete(history[i]) : null,
                    ),
                  ),
                ),
              if (history.length >= _limit)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: OutlinedButton(onPressed: () => setState(() => _limit += 30), child: const Text('عرض المزيد')),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.student});
  final Student student;

  @override
  Widget build(BuildContext context) {
    final s = student;
    return BrandHeader(
      child: Column(
        children: [
          NameAvatar(s.fullName, radius: 36, color: AppColors.goldLight),
          const SizedBox(height: 8),
          Text(s.fullName, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          Text('${s.departmentId.label} • ${s.teacherName}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill('مجموع النقاط', Fmt.number(s.totalPoints)),
              _pill('مرات التسميع', Fmt.number(s.recitationCount)),
              _pill('آخر تسميع', s.lastRecitationLabel ?? '—'),
              _pill('تاريخ آخر تسميع', Fmt.date(s.lastRecitationDate)),
            ],
          ),
          if ((s.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(s.notes!, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _pill(String label, String value) => Container(
        constraints: const BoxConstraints(minWidth: 130),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            Text(label, style: const TextStyle(color: AppColors.goldLight, fontSize: 11)),
          ],
        ),
      );
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.r, required this.first, required this.last, this.onDelete});
  final Recitation r;
  final bool first;
  final bool last;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final color = r.evaluation.color;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(width: 16),
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Expanded(child: Container(width: 2, color: first ? Colors.transparent : AppColors.gold.withValues(alpha: 0.4))),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                ),
                Expanded(child: Container(width: 2, color: last ? Colors.transparent : AppColors.gold.withValues(alpha: 0.4))),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 16, 6),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(r.evaluation.icon, color: color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.portionLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(
                              '${r.evaluation.label} • ${Fmt.date(r.recitationDate)} • ${r.teacherName}',
                              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                            if (r.extraPoints > 0)
                              Text(
                                'نقاط التقييم ${Fmt.digits(r.evaluationPoints)} + كمية إضافية ${Fmt.digits(r.extraPoints)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
                              ),
                            if (r.pendingSync)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Row(children: [
                                  Icon(Icons.cloud_upload_outlined, size: 14, color: AppColors.info),
                                  SizedBox(width: 4),
                                  Text('بانتظار المزامنة', style: TextStyle(fontSize: 11, color: AppColors.info)),
                                ]),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                        child: Text('+${Fmt.digits(r.totalPoints)}', style: TextStyle(color: color, fontWeight: FontWeight.w800)),
                      ),
                      if (onDelete != null)
                        IconButton(tooltip: 'حذف', onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
