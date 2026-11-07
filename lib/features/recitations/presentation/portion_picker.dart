import 'package:flutter/material.dart';

import '../../../core/constants/quran_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../domain/evaluation.dart';

/// Bottom sheet listing all 30 ajzaa or all 114 surahs (in mushaf order) with search.
Future<int?> showPortionPicker(BuildContext context, RecitationType type, {int? selected}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => _PortionList(type: type, selected: selected, scroll: scroll),
    ),
  );
}

class _PortionList extends StatefulWidget {
  const _PortionList({required this.type, required this.selected, required this.scroll});
  final RecitationType type;
  final int? selected;
  final ScrollController scroll;

  @override
  State<_PortionList> createState() => _PortionListState();
}

class _PortionListState extends State<_PortionList> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final isJuz = widget.type == RecitationType.juz;
    final count = isJuz ? QuranData.juzCount : QuranData.surahCount;
    final q = Fmt.searchKey(Fmt.normalizeDigits(_q));
    final items = [
      for (var n = 1; n <= count; n++)
        if (q.isEmpty ||
            n.toString() == q ||
            Fmt.searchKey(isJuz ? '${QuranData.juzName(n)} ${QuranData.juzOpening(n)}' : QuranData.surahName(n)).contains(q))
          n,
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            children: [
              Text(isJuz ? 'اختر الجزء' : 'اختر السورة', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(
                  hintText: isJuz ? 'ابحث برقم الجزء أو اسمه' : 'ابحث باسم السورة أو رقمها',
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('لا توجد نتائج'))
              : ListView.builder(
                  controller: widget.scroll,
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final n = items[i];
                    final sel = n == widget.selected;
                    return ListTile(
                      key: Key('portion_$n'),
                      selected: sel,
                      selectedTileColor: AppColors.gold.withValues(alpha: 0.12),
                      leading: CircleAvatar(
                        backgroundColor: sel ? AppColors.gold : AppColors.emerald.withValues(alpha: 0.08),
                        child: Text(Fmt.digits(n), style: TextStyle(color: sel ? Colors.white : AppColors.emerald, fontWeight: FontWeight.w800)),
                      ),
                      title: Text(isJuz ? QuranData.juzName(n) : 'سورة ${QuranData.surahName(n)}'),
                      subtitle: isJuz ? Text('يبدأ بـ «${QuranData.juzOpening(n)}»') : null,
                      trailing: sel ? const Icon(Icons.check_circle_rounded, color: AppColors.gold) : null,
                      onTap: () => Navigator.pop(ctx, n),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
