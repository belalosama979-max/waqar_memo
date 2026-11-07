import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../recitations/domain/evaluation.dart';
import '../domain/analytics.dart';

/// Bar chart of recitation counts per bucket (interactive tooltips).
class ActivityBarChart extends StatelessWidget {
  const ActivityBarChart({super.key, required this.points, required this.label, this.height = 220});
  final List<ActivityPoint> points;
  final String Function(DateTime) label;
  final double height;

  @override
  Widget build(BuildContext context) {
    final maxY = points.fold<int>(0, (m, p) => math.max(m, p.count));
    final every = points.length > 10 ? 2 : 1;
    return SizedBox(
      height: height,
      child: Directionality(
        // Charts read chronologically left-to-right; labels stay Arabic.
        textDirection: TextDirection.ltr,
        child: BarChart(
          BarChartData(
            maxY: (maxY == 0 ? 4 : maxY * 1.25).toDouble(),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: AppColors.inkSoft.withValues(alpha: 0.08), strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppColors.emeraldDeep,
                getTooltipItem: (group, _, rod, _) {
                  final p = points[group.x];
                  return BarTooltipItem(
                    '${label(p.start)}\n${Fmt.digits(p.count)} تسميع • ${Fmt.number(p.points)} نقطة',
                    const TextStyle(color: Colors.white, fontFamily: 'Tajawal', fontSize: 12),
                    textDirection: TextDirection.rtl,
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (v, meta) => v % 1 != 0
                      ? const SizedBox.shrink()
                      : SideTitleWidget(meta: meta, child: Text(Fmt.digits(v.toInt()), style: const TextStyle(fontSize: 10))),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (v, meta) {
                    final i = v.toInt();
                    if (i < 0 || i >= points.length || i % every != 0) return const SizedBox.shrink();
                    return SideTitleWidget(meta: meta, child: Text(label(points[i].start), style: const TextStyle(fontSize: 9)));
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < points.length; i++)
                BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: points[i].count.toDouble(),
                    width: points.length > 10 ? 10 : 18,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    gradient: const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [AppColors.emerald, AppColors.emeraldLight],
                    ),
                  ),
                ]),
            ],
          ),
        ),
      ),
    );
  }
}

/// Donut of evaluation distribution with legend.
class EvaluationPieChart extends StatefulWidget {
  const EvaluationPieChart({super.key, required this.breakdown});
  final Map<Evaluation, int> breakdown;

  @override
  State<EvaluationPieChart> createState() => _EvaluationPieChartState();
}

class _EvaluationPieChartState extends State<EvaluationPieChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.breakdown.values.fold(0, (a, b) => a + b);
    if (total == 0) {
      return const SizedBox(height: 120, child: Center(child: Text('لا توجد بيانات كافية بعد')));
    }
    final entries = widget.breakdown.entries.where((e) => e.value > 0).toList();
    return Row(
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 34,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (event, resp) => setState(() {
                  _touched = (!event.isInterestedForInteractions || resp?.touchedSection == null)
                      ? -1
                      : resp!.touchedSection!.touchedSectionIndex;
                }),
              ),
              sections: [
                for (var i = 0; i < entries.length; i++)
                  PieChartSectionData(
                    value: entries[i].value.toDouble(),
                    color: entries[i].key.color,
                    radius: i == _touched ? 46 : 38,
                    title: '${Fmt.digits((entries[i].value * 100 / total).round())}٪',
                    titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'Tajawal'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final e in Evaluation.values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: e.color, borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 8),
                      Expanded(child: Text(e.label, style: const TextStyle(fontSize: 13))),
                      Text(Fmt.digits(widget.breakdown[e] ?? 0), style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Line chart of cumulative points.
class PointsLineChart extends StatelessWidget {
  const PointsLineChart({super.key, required this.points, this.height = 200});
  final List<ActivityPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return SizedBox(height: 100, child: Center(child: Text(points.isEmpty ? 'لا يوجد تسميع بعد' : 'يظهر الرسم بعد تسميعين على الأقل')));
    }
    final maxY = points.last.points.toDouble();
    return SizedBox(
      height: height,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY == 0 ? 10 : maxY * 1.15,
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: AppColors.inkSoft.withValues(alpha: 0.08), strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              bottomTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (v, meta) =>
                      SideTitleWidget(meta: meta, child: Text(Fmt.digits(v.toInt()), style: const TextStyle(fontSize: 10))),
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppColors.emeraldDeep,
                getTooltipItems: (spots) => [
                  for (final s in spots)
                    LineTooltipItem(
                      '${Fmt.date(points[s.x.toInt()].start)}\n${Fmt.number(s.y.toInt())} نقطة',
                      const TextStyle(color: Colors.white, fontFamily: 'Tajawal', fontSize: 12),
                    ),
                ],
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].points.toDouble())],
                isCurved: true,
                preventCurveOverShooting: true,
                color: AppColors.gold,
                barWidth: 3,
                dotData: FlDotData(show: points.length < 25),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.gold.withValues(alpha: 0.35), AppColors.gold.withValues(alpha: 0)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card wrapper for charts.
class ChartCard extends StatelessWidget {
  const ChartCard({super.key, required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)), ?trailing]),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      );
}
