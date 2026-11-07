import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/brand.dart';
import '../core/widgets/common.dart';
import '../features/recitations/presentation/sync_status_banner.dart';

class ShellDestination {
  const ShellDestination(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const teacherDestinations = [
  ShellDestination('طلابي', Icons.groups_outlined, Icons.groups_rounded),
  ShellDestination('الصدارة', Icons.emoji_events_outlined, Icons.emoji_events_rounded),
  ShellDestination('الإحصائيات', Icons.insights_outlined, Icons.insights_rounded),
  ShellDestination('المزيد', Icons.menu_rounded, Icons.menu_open_rounded),
];

const adminDestinations = [
  ShellDestination('الرئيسية', Icons.dashboard_outlined, Icons.dashboard_rounded),
  ShellDestination('المعلمون', Icons.badge_outlined, Icons.badge_rounded),
  ShellDestination('الطلاب', Icons.groups_outlined, Icons.groups_rounded),
  ShellDestination('التسميع', Icons.menu_book_outlined, Icons.menu_book_rounded),
  ShellDestination('الإعدادات', Icons.settings_outlined, Icons.settings_rounded),
];

/// Bottom navigation on phones, navigation rail on tablets.
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({super.key, required this.shell, required this.destinations});
  final StatefulNavigationShell shell;
  final List<ShellDestination> destinations;

  void _go(int i) => shell.goBranch(i, initialLocation: i == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final body = Column(children: [const SyncStatusBanner(), Expanded(child: shell)]);
    if (Breakpoints.isTablet(context)) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                selectedIndex: shell.currentIndex,
                onDestinationSelected: _go,
                labelType: NavigationRailLabelType.all,
                indicatorColor: AppColors.gold.withValues(alpha: 0.25),
                leading: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: BrandMark(size: 52)),
                destinations: [
                  for (final d in destinations)
                    NavigationRailDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: Text(d.label)),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(bottom: false, child: body),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _go,
        destinations: [
          for (final d in destinations) NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label),
        ],
      ),
    );
  }
}
