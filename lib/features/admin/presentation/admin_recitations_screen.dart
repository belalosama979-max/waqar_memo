import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../router/routes.dart';
import '../../auth/domain/enums.dart';
import '../../exports/export_service.dart';
import '../../recitations/data/recitation_repository.dart';
import '../../recitations/domain/recitation.dart';

/// All recitations with cursor pagination and Excel export.
class AdminRecitationsScreen extends ConsumerStatefulWidget {
  const AdminRecitationsScreen({super.key});

  @override
  ConsumerState<AdminRecitationsScreen> createState() => _AdminRecitationsScreenState();
}

class _AdminRecitationsScreenState extends ConsumerState<AdminRecitationsScreen> {
  Department? _dep;
  final _items = <Recitation>[];
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _items.clear();
      _cursor = null;
      _hasMore = true;
      _error = null;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final page = await ref.read(recitationRepositoryProvider).fetchPage(department: _dep, startAfter: _cursor);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _cursor = page.cursor;
        _hasMore = page.hasMore;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _exporting = true);
    try {
      // Export everything matching the filter (paged fetch).
      final repo = ref.read(recitationRepositoryProvider);
      final all = <Recitation>[];
      DocumentSnapshot<Map<String, dynamic>>? cursor;
      var more = true;
      while (more && all.length < 20000) {
        final p = await repo.fetchPage(department: _dep, startAfter: cursor, pageSize: 500);
        all.addAll(p.items);
        cursor = p.cursor;
        more = p.hasMore;
      }
      final svc = ref.read(exportServiceProvider);
      await svc.shareFile(
        svc.recitationsExcel(all),
        'سجل-التسميع.xlsx',
        mime: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    } catch (e) {
      if (mounted) showAppSnack(context, AppFailure.from(e).message, error: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل التسميع'),
        actions: [
          IconButton(
            tooltip: 'تصدير Excel',
            onPressed: _exporting ? null : _exportExcel,
            icon: _exporting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.table_chart_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<Department?>(
              segments: [
                const ButtonSegment(value: null, label: Text('الكل')),
                for (final d in Department.values) ButtonSegment(value: d, label: Text(d.label)),
              ],
              selected: {_dep},
              onSelectionChanged: (s) {
                _dep = s.first;
                _reload();
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reload,
              child: _error != null && _items.isEmpty
                  ? ListView(children: [ErrorView(error: _error!, onRetry: _reload)])
                  : _items.isEmpty && !_loading
                      ? ListView(children: const [EmptyState(icon: Icons.menu_book_rounded, title: 'لا يوجد تسميع مسجل بعد')])
                      : NotificationListener<ScrollNotification>(
                          onNotification: (n) {
                            if (n.metrics.pixels > n.metrics.maxScrollExtent - 300) _loadMore();
                            return false;
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: _items.length + 1,
                            itemBuilder: (_, i) {
                              if (i == _items.length) {
                                return Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Center(
                                    child: _loading
                                        ? const CircularProgressIndicator()
                                        : _hasMore
                                            ? OutlinedButton(onPressed: _loadMore, child: const Text('تحميل المزيد'))
                                            : const Text('نهاية السجل', style: TextStyle(color: AppColors.inkSoft)),
                                  ),
                                );
                              }
                              final r = _items[i];
                              return MaxWidth(
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    onTap: () => context.push(Routes.student(r.studentId)),
                                    leading: CircleAvatar(
                                      backgroundColor: r.evaluation.color.withValues(alpha: 0.12),
                                      child: Icon(r.evaluation.icon, color: r.evaluation.color),
                                    ),
                                    title: Text('${r.studentName} — ${r.portionLabel}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                    subtitle: Text('${r.evaluation.label} • ${r.teacherName} • ${Fmt.date(r.recitationDate)}'),
                                    trailing: Text('+${Fmt.digits(r.totalPoints)}', style: TextStyle(color: r.evaluation.color, fontWeight: FontWeight.w800)),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
