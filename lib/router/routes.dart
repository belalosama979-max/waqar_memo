/// Route paths.
abstract final class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const welcome = '/welcome';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const changePassword = '/change-password';
  static const firstLogin = '/first-login';
  static const configMissing = '/config-missing';

  // Teacher shell
  static const teacherHome = '/teacher';
  static const teacherLeaderboard = '/teacher/leaderboard';
  static const teacherStats = '/teacher/stats';
  static const teacherMore = '/teacher/more';

  // Admin shell
  static const adminHome = '/admin';
  static const adminTeachers = '/admin/teachers';
  static const adminStudents = '/admin/students';
  static const adminRecitations = '/admin/recitations';
  static const adminSettings = '/admin/settings';

  // Shared full-screen routes
  static String student(String id) => '/student/$id';
  static String recordRecitation(String studentId) => '/record/$studentId';
  static const notifications = '/notifications';
  static const evaluationSettings = '/admin/settings/evaluation';
  static const announcements = '/admin/settings/announcements';
  static String departmentLeaderboard(String dep) => '/leaderboard/$dep';
}
