import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/firebase/firebase_config.dart';
import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/admin/presentation/admin_recitations_screen.dart';
import '../features/admin/presentation/admin_settings_screen.dart';
import '../features/admin/presentation/admin_students_screen.dart';
import '../features/admin/presentation/admin_teachers_screen.dart';
import '../features/admin/presentation/announcements_screen.dart';
import '../features/admin/presentation/evaluation_settings_screen.dart';
import '../features/auth/application/session_providers.dart';
import '../features/auth/domain/app_user.dart';
import '../features/auth/domain/enums.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/password_screens.dart';
import '../features/leaderboard/presentation/leaderboard_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/onboarding/data/onboarding_repository.dart';
import '../features/onboarding/presentation/config_missing_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/onboarding/presentation/splash_screen.dart';
import '../features/onboarding/presentation/welcome_screen.dart';
import '../features/recitations/presentation/record_recitation_screen.dart';
import '../features/students/presentation/student_profile_screen.dart';
import '../features/teacher/presentation/teacher_home_screen.dart';
import '../features/teacher/presentation/teacher_more_screen.dart';
import '../features/teacher/presentation/teacher_stats_screen.dart';
import 'adaptive_shell.dart';
import 'routes.dart';

class SplashDone extends Notifier<bool> {
  @override
  bool build() => false;
  void finish() => state = true;
}

final splashDoneProvider = NotifierProvider<SplashDone, bool>(SplashDone.new);

/// True once we know whether someone is signed in (and their profile loaded).
final sessionResolvedProvider = Provider<bool>((ref) {
  final auth = ref.watch(authStateProvider);
  if (!auth.hasValue && !auth.hasError) return false;
  if (auth.value == null) return true;
  final profile = ref.watch(currentUserProvider);
  return profile.hasValue || profile.hasError;
});

String homeFor(AppUser user) => user.isAdmin ? Routes.adminHome : Routes.teacherHome;

/// Where the splash should go next.
final initialLocationProvider = Provider<String>((ref) {
  if (!FirebaseConfig.isConfigured) return Routes.configMissing;
  final user = ref.watch(currentUserProvider).value;
  if (user != null && user.active) {
    return user.mustChangePassword ? Routes.firstLogin : homeFor(user);
  }
  return ref.watch(onboardingDoneProvider) ? Routes.welcome : Routes.onboarding;
});

const _publicRoutes = {Routes.onboarding, Routes.welcome, Routes.login, Routes.forgotPassword};

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(currentUserProvider, (_, _) => refresh.value++);
  ref.listen(authStateProvider, (_, _) => refresh.value++);
  ref.listen(splashDoneProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  String? redirect(BuildContext context, GoRouterState state) {
    final loc = state.matchedLocation;
    if (!ref.read(splashDoneProvider)) return loc == Routes.splash ? null : Routes.splash;
    if (!FirebaseConfig.isConfigured) return loc == Routes.configMissing ? null : Routes.configMissing;

    final authUser = ref.read(authStateProvider).value;
    final profileState = ref.read(currentUserProvider);
    final user = profileState.value;

    if (authUser != null && profileState.isLoading && !profileState.hasValue) return null; // wait

    if (user == null || !user.active) {
      if (_publicRoutes.contains(loc)) return null;
      return ref.read(onboardingDoneProvider) ? Routes.welcome : Routes.onboarding;
    }
    if (user.mustChangePassword) return loc == Routes.firstLogin ? null : Routes.firstLogin;
    if (_publicRoutes.contains(loc) || loc == Routes.firstLogin || loc == Routes.splash || loc == Routes.configMissing) {
      return homeFor(user);
    }
    if (user.role == UserRole.admin && loc.startsWith('/teacher')) return Routes.adminHome;
    if (user.role == UserRole.teacher && loc.startsWith('/admin')) return Routes.teacherHome;
    return null;
  }

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: redirect,
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.configMissing, builder: (_, _) => const ConfigMissingScreen()),
      GoRoute(path: Routes.onboarding, builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: Routes.welcome, builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.forgotPassword, builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(path: Routes.firstLogin, builder: (_, _) => const ChangePasswordScreen(forced: true)),
      GoRoute(path: Routes.changePassword, builder: (_, _) => const ChangePasswordScreen()),
      GoRoute(path: Routes.notifications, builder: (_, _) => const NotificationsScreen()),
      GoRoute(
        path: '/student/:id',
        builder: (_, s) => StudentProfileScreen(studentId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/record/:studentId',
        builder: (_, s) => RecordRecitationScreen(studentId: s.pathParameters['studentId']!),
      ),
      GoRoute(
        path: '/leaderboard/:dep',
        builder: (_, s) => LeaderboardScreen(
          initialDepartment: Department.tryParse(s.pathParameters['dep']) ?? Department.male,
          adminMode: true,
        ),
      ),
      GoRoute(path: Routes.evaluationSettings, builder: (_, _) => const EvaluationSettingsScreen()),
      GoRoute(path: Routes.announcements, builder: (_, _) => const AnnouncementsScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AdaptiveShell(shell: shell, destinations: teacherDestinations),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: Routes.teacherHome, builder: (_, _) => const TeacherHomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.teacherLeaderboard, builder: (_, _) => const LeaderboardScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.teacherStats, builder: (_, _) => const TeacherStatsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.teacherMore, builder: (_, _) => const TeacherMoreScreen())]),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AdaptiveShell(shell: shell, destinations: adminDestinations),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: Routes.adminHome, builder: (_, _) => const AdminDashboardScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.adminTeachers, builder: (_, _) => const AdminTeachersScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.adminStudents, builder: (_, _) => const AdminStudentsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.adminRecitations, builder: (_, _) => const AdminRecitationsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.adminSettings, builder: (_, _) => const AdminSettingsScreen())]),
        ],
      ),
    ],
    errorBuilder: (_, _) => const Scaffold(body: Center(child: Text('الصفحة غير موجودة'))),
  );
});
