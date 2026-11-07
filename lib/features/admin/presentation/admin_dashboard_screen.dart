import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/common.dart';
import '../../../router/routes.dart';
import '../../analytics/domain/analytics.dart';
import '../../analytics/presentation/charts.dart';
import '../../auth/application/session_providers.dart';
import '../../auth/domain/enums.dart';
import '../../recitations/data/recitation_repository.dart';
import '../../recitations/domain/recitation.dart';
import '../../settings/data/settings_repository.dart';
import '../../students/application/student_providers.dart';
import '../../teachers/data/teacher_repository.dart';
import '../../teachers/domain/teacher.dart';

final adminTeachersProvider = StreamProvider.family<List<Teacher>, Department?>(
  (ref, d) => ref.watch(teacherRepositoryProvider).watchTeachers(department: d),
);

final _recitationCountProvider = FutureProvider.family<int, Department?>(
  (ref, d) => ref.watch(recitationRepositoryProvider).countAll(department: d),
);

final _adminRecentProvider = StreamProvider.family<List<Recitation>, Department>((ref, d) {
  final now = DateTime.now();
  return ref.watch(recitationRepositoryProvider).watchRecent(department: d, since: DateTime(now.year, now.month - 5));
});

enum _Range { daily, weekly, monthly }

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  Department _dep = Department.male;
  _Range _range = _Range.daily;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final academy = ref.watch(appSettingsProvider).value?.academyName ?? 'حلقات الوقار';
    final teachers = ref.watch(adminTeachersProvider(null)).value ?? const [];
    final students = ref.watch(allStudentsProvider(null)).value ?? const [];
    final totalRecitations = ref.watch(_recitationCountProvider(null));
    final recent = ref.watch(_adminRecentProvider(_dep));
    final depStudents = students.where((s) => s.departmentId == _dep).toList();
    final now = DateTime.now();
    final cols = Breakpoints.isTablet(context) ? 4 : 2;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_recitationCountProvider),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          BrandHeader(
            child: Row(
              children: [
                const BrandMark(size: 54, onDark: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(academy, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      Text('مرحباً ${user?.displayName ?? ''} — لوحة الإدارة', style: TextStyle(color: AppColors.goldLight.withValues(alpha: 0.95))),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'الإشعارات',
                  color: Colors.white,
                  onPressed: () => context.push(Routes.notifications),
                  icon: const Icon(Icons.notifications_rounded),
                ),
              ],
            ),
          ),
          MaxWidth(
            maxWidth: 1200,
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                      StatTile(label: 'إجمالي المعلمين', value: Fmt.number(teachers.length), icon: Icons.badge_rounded),
                      StatTile(label: 'إجمالي الطلاب', value: Fmt.number(students.length), icon: Icons.groups_rounded, color: AppColors.emeraldLight),
                      StatTile(
                        label: 'إجمالي التسميع',
                        value: totalRecitations.when(data: Fmt.number, loading: () => '…', error: (_, _) => '—'),
                        icon: Icons.menu_book_rounded,
                        color: AppColors.gold,
                      ),
                      StatTile(
                        label: 'مجموع النقاط',
                        value: Fmt.number(students.fold(0, (a, s) => a + s.totalPoints)),
                        icon: Icons.stars_rounded,
                        color: AppColors.info,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<Department>(
                    segments: [for (final d in Department.values) ButtonSegment(value: d, label: Text(d.label))],
                    selected: {_dep},
                    onSelectionChanged: (s) => setState(() => _dep = s.first),
                  ),
                  const SectionTitle('النشاط'),
                  ChartCard(
                    title: switch (_range) {
                      _Range.daily => 'النشاط اليومي (١٤ يوماً)',
                      _Range.weekly => 'النشاط الأسبوعي (٨ أسابيع)',
                      _Range.monthly => 'النشاط الشهري (٦ أشهر)',
                    },
                    trailing: PopupMenuButton<_Range>(
                      tooltip: 'المدة',
                      initialValue: _range,
                      onSelected: (r) => setState(() => _range = r),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: _Range.daily, child: Text('يومي')),
                        PopupMenuItem(value: _Range.weekly, child: Text('أسبوعي')),
                        PopupMenuItem(value: _Range.monthly, child: Text('شهري')),
                      ],
                      child: const Icon(Icons.tune_rounded),
                    ),
                    child: AsyncBody<List<Recitation>>(
                      value: recent,
                      data: (list) => switch (_range) {
                        _Range.daily => ActivityBarChart(points: Analytics.daily(list, now: now), label: (d) => Fmt.digits(d.day)),
                        _Range.weekly => ActivityBarChart(
                            points: Analytics.weekly(list, now: now),
                            label: (d) => Fmt.digits(DateFormat('d/M').format(d)),
                          ),
                        _Range.monthly => ActivityBarChart(
                            points: Analytics.monthly(list, now: now),
                            label: (d) => DateFormat('MMM', 'ar').format(d),
                          ),
                      },
                    ),
                  ),
                  const SectionTitle('توزيع التقييمات'),
                  ChartCard(
                    title: 'آخر ٦ أشهر — ${_dep.label}',
                    child: EvaluationPieChart(breakdown: Analytics.evaluationBreakdown(recent.value ?? const [])),
                  ),
                  SectionTitle(
                    'أفضل الطلاب — ${_dep.label}',
                    trailing: TextButton(
                      onPressed: () => context.push(Routes.departmentLeaderboard(_dep.id)),
                      child: const Text('لوحة الصدارة'),
                    ),
                  ),
                  _TopList(
                    items: [
                      for (final s in Analytics.topStudents(depStudents))
                        (title: s.fullName, subtitle: s.teacherName, value: s.totalPoints, onTap: () => context.push(Routes.student(s.id))),
                    ],
                  ),
                  SectionTitle('أفضل المعلمين — ${_dep.label}'),
                  _TopList(
                    items: [
                      for (final t in Analytics.topTeachers(depStudents))
                        (title: t.teacherName, subtitle: '${Fmt.digits(t.students)} طالب', value: t.points, onTap: null),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopList extends StatelessWidget {
  const _TopList({required this.items});
  final List<({String title, String subtitle, int value, VoidCallback? onTap})> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد بيانات بعد', textAlign: TextAlign.center)));
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            ListTile(
              onTap: items[i].onTap,
              leading: CircleAvatar(
                backgroundColor: [AppColors.gold, AppColors.silver, AppColors.bronze].elementAtOrNull(i) ?? AppColors.emerald.withValues(alpha: 0.1),
                child: Text(Fmt.digits(i + 1), style: TextStyle(color: i < 3 ? Colors.white : AppColors.emerald, fontWeight: FontWeight.w800)),
              ),
              title: Text(items[i].title, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(items[i].subtitle),
              trailing: Text(Fmt.points(items[i].value), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.emeraldDeep)),
            ),
        ],
      ),
    );
  }
}
