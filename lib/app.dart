import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/connectivity_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/session_providers.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/notifications/data/notifications_repository.dart';
import 'features/notifications/data/push_service.dart';
import 'features/recitations/data/recitation_repository.dart';
import 'router/app_router.dart';

/// Raises a phone alert for new notifications while the app is running.
final _notificationAlertsProvider = Provider<void>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || !user.active || user.mustChangePassword) return;
  ref.listen(notificationsProvider(user), (_, next) {
    final list = next.value;
    if (list != null) ref.read(pushServiceProvider).alertNew(user.id, list);
  });
});

class AlwaqarApp extends ConsumerWidget {
  const AlwaqarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    ref.watch(_notificationAlertsProvider);

    // Session side effects: push registration and offline-queue reconciliation.
    ref.listen(currentUserProvider, (prev, next) {
      final before = prev?.value;
      final user = next.value;
      if (user != null && !user.active) {
        // Deactivated by the admin: end the session immediately.
        ref.read(authRepositoryProvider).signOut();
        return;
      }
      if (user != null && before?.id != user.id) {
        ref.read(pushServiceProvider).registerUser();
        ref.read(recitationRepositoryProvider).reconcilePending();
      }
    });
    ref.listen(isOnlineProvider, (prev, next) {
      if (prev?.value == false && next.value == true) {
        ref.read(recitationRepositoryProvider).reconcilePending();
      }
    });

    return MaterialApp.router(
      title: 'الوقار',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.light(),
      themeMode: ThemeMode.light,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          // Respect user font scaling but keep layouts sane.
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.textScalerOf(context).clamp(minScaleFactor: 0.85, maxScaleFactor: 1.3),
          ),
          child: child!,
        ),
      ),
    );
  }
}
