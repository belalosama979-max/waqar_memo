import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/common.dart';
import '../../../router/routes.dart';
import '../../auth/application/session_providers.dart';
import '../../students/application/student_providers.dart';
import '../../students/presentation/student_card.dart';

class TeacherHomeScreen extends ConsumerStatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  ConsumerState<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends ConsumerState<TeacherHomeScreen> {
  final _search = TextEditingController();
  StudentSort _sort = StudentSort.points;
  StudentFilter _filter = StudentFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final students = ref.watch(myStudentsProvider);
    final all = students.value ?? const [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recitedToday = all.where((s) => s.lastRecitationDate != null && !s.lastRecitationDate!.isBefore(today)).length;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: BrandHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('السلام عليكم', style: TextStyle(color: AppColors.goldLight.withValues(alpha: 0.95))),
                          Text(
                            user?.displayName ?? '',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                          Text(user?.departmentId?.label ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.75))),
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    _HeaderStat(label: 'طلابي', value: Fmt.number(all.length)),
                    _HeaderStat(label: 'سمّعوا اليوم', value: Fmt.number(recitedToday)),
                    _HeaderStat(label: 'مجموع النقاط', value: Fmt.number(all.fold(0, (a, s) => a + s.totalPoints))),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: MaxWidth(
            maxWidth: 1200,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Column(
                children: [
                  TextField(
                    key: const Key('teacher_search'),
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن طالب...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'مسح',
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => setState(_search.clear),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final f in StudentFilter.values)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: FilterChip(
                              label: Text(f.label),
                              selected: _filter == f,
                              onSelected: (_) => setState(() => _filter = f),
                            ),
                          ),
                        const SizedBox(width: 4),
                        PopupMenuButton<StudentSort>(
                          tooltip: 'الترتيب',
                          initialValue: _sort,
                          onSelected: (s) => setState(() => _sort = s),
                          itemBuilder: (_) => [for (final s in StudentSort.values) PopupMenuItem(value: s, child: Text(s.label))],
                          child: Chip(avatar: const Icon(Icons.sort_rounded, size: 18), label: Text('ترتيب: ${_sort.label}')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ...switch (students) {
          AsyncValue(:final value?) => _list(value),
          AsyncValue(:final error?) => [SliverFillRemaining(child: ErrorView(error: error, onRetry: () => ref.invalidate(myStudentsProvider)))],
          _ => [const SliverFillRemaining(child: LoadingView(message: 'جارٍ تحميل الطلاب...'))],
        },
      ],
    );
  }

  List<Widget> _list(List<dynamic> raw) {
    final students = applyStudentQuery(
      raw.cast(),
      search: _search.text,
      sort: _sort,
      filter: _filter,
      normalize: Fmt.searchKey,
    );
    if (raw.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.groups_rounded,
            title: 'لا يوجد طلاب مسجلون لديك بعد',
            message: 'تضيف الإدارة الطلاب وتسندهم إليك، وسيظهرون هنا.',
          ),
        ),
      ];
    }
    if (students.isEmpty) {
      return const [
        SliverFillRemaining(hasScrollBody: false, child: EmptyState(icon: Icons.search_off_rounded, title: 'لا توجد نتائج مطابقة')),
      ];
    }
    final cols = Breakpoints.gridColumns(context);
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        sliver: SliverToBoxAdapter(
          child: MaxWidth(
            maxWidth: 1200,
            child: LayoutBuilder(builder: (context, c) {
              final w = (c.maxWidth - (cols - 1) * 12) / cols;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final s in students)
                    SizedBox(
                      width: w,
                      child: StudentCard(
                        key: ValueKey(s.id),
                        student: s,
                        onRecord: () => context.push(Routes.recordRecitation(s.id)),
                        onProfile: () => context.push(Routes.student(s.id)),
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    ];
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          margin: const EdgeInsetsDirectional.only(end: 8),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              FittedBox(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
              Text(label, style: TextStyle(color: AppColors.goldLight.withValues(alpha: 0.95), fontSize: 12)),
            ],
          ),
        ),
      );
}
