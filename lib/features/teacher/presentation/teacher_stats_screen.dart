import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../analytics/domain/analytics.dart';
import '../../analytics/presentation/charts.dart';
import '../../auth/application/session_providers.dart';
import '../../recitations/data/recitation_repository.dart';
import '../../recitations/domain/recitation.dart';
import '../../students/application/student_providers.dart';

final _teacherRecentProvider = StreamProvider<List<Recitation>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || user.departmentId == null) return Stream.value(const []);
  final now = DateTime.now();
  return ref.watch(recitationRepositoryProvider).watchRecent(
        department: user.departmentId,
        teacherId: user.id,
        since: DateTime(now.year, now.month - 5),
      );
});

class TeacherStatsScreen extends ConsumerWidget {
  const TeacherStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final recent = ref.watch(_teacherRecentProvider);
    final students = ref.watch(myStudentsProvider).value ?? const [];
    final dept = user?.departmentId == null ? null : ref.watch(departmentLeaderboardProvider(user!.departmentId!)).value;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('الإحصائيات')),
      body: AsyncBody<List<Recitation>>(
        value: recent,
        data: (list) {
          final weekStart = Analytics.weekStart(now);
          final thisWeek = list.where((r) => r.recitationDate != null && !r.recitationDate!.isBefore(weekStart)).toList();
          final weekPoints = thisWeek.fold(0, (a, r) => a + r.totalPoints);
          final top = Analytics.topStudents(students, count: 5);
          final teachers = dept == null ? const <TeacherScore>[] : Analytics.topTeachers(dept, count: 100);
          final myRank = teachers.indexWhere((t) => t.teacherId == user?.id);
          final cols = Breakpoints.isTablet(context) ? 4 : 2;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              MaxWidth(
                maxWidth: 1100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GridView.count(
                      crossAxisCount: cols,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.2,
                      children: [
                        StatTile(label: 'الطلاب المسندون', value: Fmt.number(students.length), icon: Icons.groups_rounded),
                        StatTile(label: 'تسميع هذا الأسبوع', value: Fmt.number(thisWeek.length), icon: Icons.menu_book_rounded, color: AppColors.emeraldLight),
                        StatTile(label: 'نقاط هذا الأسبوع', value: Fmt.number(weekPoints), icon: Icons.stars_rounded, color: AppColors.gold),
                        StatTile(
                          label: 'ترتيبك في القسم',
                          value: myRank < 0 ? '—' : '${Fmt.digits(myRank + 1)} من ${Fmt.digits(teachers.length)}',
                          icon: Icons.leaderboard_rounded,
                          color: AppColors.info,
                        ),
                      ],
                    ),
                    const SectionTitle('التقدم الأسبوعي'),
                    ChartCard(
                      title: 'عدد مرات التسميع لكل أسبوع',
                      child: ActivityBarChart(
                        points: Analytics.weekly(list, now: now),
                        label: (d) => Fmt.digits(DateFormat('d/M').format(d)),
                      ),
                    ),
                    const SectionTitle('النشاط اليومي'),
                    ChartCard(
                      title: 'آخر ١٤ يوماً',
                      child: ActivityBarChart(points: Analytics.daily(list, now: now), label: (d) => Fmt.digits(d.day)),
                    ),
                    const SectionTitle('أداء الطلاب'),
                    ChartCard(title: 'توزيع التقييمات (آخر ٦ أشهر)', child: EvaluationPieChart(breakdown: Analytics.evaluationBreakdown(list))),
                    const SectionTitle('أفضل طلابي'),
                    if (top.isEmpty)
                      const EmptyState(title: 'لا يوجد طلاب بعد')
                    else
                      Card(
                        child: Column(
                          children: [
                            for (var i = 0; i < top.length; i++)
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: i == 0 ? AppColors.gold : AppColors.emerald.withValues(alpha: 0.1),
                                  child: Text(Fmt.digits(i + 1), style: TextStyle(color: i == 0 ? Colors.white : AppColors.emerald, fontWeight: FontWeight.w800)),
                                ),
                                title: Text(top[i].fullName),
                                trailing: Text(Fmt.points(top[i].totalPoints), style: const TextStyle(fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
