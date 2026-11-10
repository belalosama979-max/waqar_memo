import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../router/routes.dart';
import '../../analytics/domain/analytics.dart';
import '../../auth/application/session_providers.dart';
import '../../auth/domain/enums.dart';
import '../../exports/export_service.dart';
import '../../students/application/student_providers.dart';
import '../../students/data/student_repository.dart';
import '../../students/domain/student.dart';

final _teacherLeaderboardProvider = StreamProvider.family<List<Student>, ({String teacherId, Department dep})>(
  (ref, k) => ref.watch(studentRepositoryProvider).watchTeacherLeaderboard(teacherId: k.teacherId, department: k.dep),
);

/// Teacher view: two tabs (my students / my department).
/// Admin view ([adminMode]): one department at a time, never mixed.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key, this.initialDepartment = Department.male, this.adminMode = false});
  final Department initialDepartment;
  final bool adminMode;

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  late Department _adminDep = widget.initialDepartment;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const LoadingView();

    if (widget.adminMode || user.isAdmin) {
      final list = ref.watch(departmentLeaderboardProvider(_adminDep));
      return Scaffold(
        appBar: AppBar(title: const Text('لوحة الصدارة'), actions: [_ExportButton(title: 'ترتيب ${_adminDep.label}', list: list.value)]),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: SegmentedButton<Department>(
                segments: [for (final d in Department.values) ButtonSegment(value: d, label: Text(d.label))],
                selected: {_adminDep},
                onSelectionChanged: (s) => setState(() => _adminDep = s.first),
              ),
            ),
            Expanded(child: _Board(value: list, showTeacher: true)),
          ],
        ),
      );
    }

    final dep = user.departmentId!;
    final mine = ref.watch(_teacherLeaderboardProvider((teacherId: user.teacherKey, dep: dep)));
    final department = ref.watch(departmentLeaderboardProvider(dep));
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة الصدارة'),
          actions: [
            Builder(builder: (context) {
              final tab = DefaultTabController.of(context);
              return AnimatedBuilder(
                animation: tab,
                builder: (_, _) => _ExportButton(
                  title: tab.index == 0 ? 'ترتيب طلاب ${user.displayName}' : 'ترتيب ${dep.label}',
                  list: tab.index == 0 ? mine.value : department.value,
                ),
              );
            }),
          ],
          bottom: TabBar(tabs: [const Tab(text: 'طلابي'), Tab(text: dep.label)]),
        ),
        body: TabBarView(
          children: [
            _Board(value: mine, showTeacher: false),
            _Board(value: department, showTeacher: true, highlightTeacherId: user.teacherKey),
          ],
        ),
      ),
    );
  }
}

class _ExportButton extends ConsumerStatefulWidget {
  const _ExportButton({required this.title, required this.list});
  final String title;
  final List<Student>? list;

  @override
  ConsumerState<_ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends ConsumerState<_ExportButton> {
  bool _busy = false;

  Future<void> _run(String action) async {
    final list = widget.list;
    if (list == null || list.isEmpty) {
      showAppSnack(context, 'لا توجد بيانات للتصدير');
      return;
    }
    setState(() => _busy = true);
    try {
      final svc = ref.read(exportServiceProvider);
      switch (action) {
        case 'pdf':
          await svc.shareFile(await svc.leaderboardPdf(title: widget.title, students: list), '${widget.title}.pdf', mime: 'application/pdf');
        case 'print':
          await svc.printPdf(await svc.leaderboardPdf(title: widget.title, students: list), widget.title);
        case 'excel':
          await svc.shareFile(
            svc.leaderboardExcel(list),
            '${widget.title}.xlsx',
            mime: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          );
      }
    } catch (e) {
      if (mounted) showAppSnack(context, AppFailure.from(e).message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        tooltip: 'تصدير',
        enabled: !_busy,
        icon: _busy
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.ios_share_rounded),
        onSelected: _run,
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'pdf', child: ListTile(leading: Icon(Icons.picture_as_pdf_rounded), title: Text('مشاركة PDF'))),
          PopupMenuItem(value: 'excel', child: ListTile(leading: Icon(Icons.table_chart_rounded), title: Text('تصدير Excel'))),
          PopupMenuItem(value: 'print', child: ListTile(leading: Icon(Icons.print_rounded), title: Text('طباعة'))),
        ],
      );
}

class _Board extends StatelessWidget {
  const _Board({required this.value, required this.showTeacher, this.highlightTeacherId});
  final AsyncValue<List<Student>> value;
  final bool showTeacher;
  final String? highlightTeacherId;

  @override
  Widget build(BuildContext context) => AsyncBody<List<Student>>(
        value: value,
        data: (raw) {
          if (raw.isEmpty) {
            return const EmptyState(icon: Icons.emoji_events_rounded, title: 'لا يوجد طلاب في الترتيب بعد');
          }
          final sorted = [...raw]..sort(Analytics.compareByRank);
          final ranks = Analytics.ranks(sorted);
          final rest = sorted.length > 3 ? sorted.sublist(3) : <Student>[];
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              MaxWidth(maxWidth: 700, child: Podium(top: sorted.take(3).toList())),
              for (var i = 0; i < rest.length; i++)
                MaxWidth(
                  maxWidth: 900,
                  child: _RankRow(
                    rank: ranks[i + 3],
                    s: rest[i],
                    showTeacher: showTeacher,
                    highlight: highlightTeacherId != null && rest[i].teacherId == highlightTeacherId,
                  ),
                ),
            ],
          );
        },
      );
}

/// Top-three podium.
class Podium extends StatelessWidget {
  const Podium({super.key, required this.top});
  final List<Student> top;

  @override
  Widget build(BuildContext context) {
    Widget slot(int index, double height, Color medal) {
      if (index >= top.length) return const Expanded(child: SizedBox());
      final s = top[index];
      return Expanded(
        child: GestureDetector(
          onTap: () => context.push(Routes.student(s.id)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (index == 0) const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 34),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: medal, width: 3)),
                child: NameAvatar(s.fullName, radius: index == 0 ? 32 : 26),
              ),
              const SizedBox(height: 6),
              Text(s.fullName, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              Text(s.teacherName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
              const SizedBox(height: 6),
              Container(
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [medal, medal.withValues(alpha: 0.65)],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(Fmt.digits(index + 1), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                    Text(Fmt.number(s.totalPoints), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    const Text('نقطة', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        // Visual order right-to-left: 1st in the middle, 2nd at the start, 3rd at the end.
        children: [slot(1, 110, AppColors.silver), slot(0, 145, AppColors.gold), slot(2, 85, AppColors.bronze)],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.rank, required this.s, required this.showTeacher, this.highlight = false});
  final int rank;
  final Student s;
  final bool showTeacher;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Card(
          color: highlight ? AppColors.goldSoft : null,
          child: ListTile(
            onTap: () => context.push(Routes.student(s.id)),
            leading: SizedBox(
              width: 36,
              child: Center(child: Text(Fmt.digits(rank), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.emerald))),
            ),
            title: Text(s.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              [
                if (showTeacher) s.teacherName,
                s.lastRecitationLabel ?? 'لم يسمّع بعد',
                if (s.lastRecitationDate != null) Fmt.date(s.lastRecitationDate),
              ].join(' • '),
              maxLines: 2,
            ),
            trailing: Text(Fmt.number(s.totalPoints), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.emeraldDeep)),
          ),
        ),
      );
}
