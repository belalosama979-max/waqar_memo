import 'package:alwaqar/core/firebase/firebase_providers.dart';
import 'package:alwaqar/core/theme/app_theme.dart';
import 'package:alwaqar/features/auth/application/session_providers.dart';
import 'package:alwaqar/features/auth/domain/app_user.dart';
import 'package:alwaqar/features/auth/presentation/login_screen.dart';
import 'package:alwaqar/features/leaderboard/presentation/leaderboard_screen.dart';
import 'package:alwaqar/features/onboarding/data/onboarding_repository.dart';
import 'package:alwaqar/features/onboarding/presentation/onboarding_screen.dart';
import 'package:alwaqar/features/recitations/domain/evaluation_settings.dart';
import 'package:alwaqar/features/recitations/presentation/record_recitation_screen.dart';
import 'package:alwaqar/features/settings/data/settings_repository.dart';
import 'package:alwaqar/features/students/application/student_providers.dart';
import 'package:alwaqar/features/students/domain/student.dart';
import 'package:alwaqar/features/teacher/presentation/teacher_home_screen.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

class MockFunctions extends Mock implements FirebaseFunctions {}

/// Pumps [routes] inside an Arabic RTL app with the given overrides.
Future<void> pumpApp(
  WidgetTester tester, {
  required List<RouteBase> routes,
  String initial = '/',
  List overrides = const [],
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(initialLocation: initial, routes: routes);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      functionsProvider.overrideWithValue(MockFunctions()),
      ...overrides.cast(),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> scrollTo(WidgetTester tester, Key key) async {
  await tester.scrollUntilVisible(find.byKey(key), 150, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

void debugDumpTexts(WidgetTester tester) {
  // ignore: avoid_print
  print(tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).where((d) => d != null).join(' | '));
}

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  testWidgets('onboarding: 3 pages, next/start, completion is saved', (tester) async {
    late ProviderContainer container;
    await pumpApp(tester, routes: [
      GoRoute(
        path: '/',
        builder: (context, _) {
          container = ProviderScope.containerOf(context);
          return const OnboardingScreen();
        },
      ),
      GoRoute(path: '/welcome', builder: (_, _) => const Scaffold(body: Text('شاشة الترحيب'))),
    ]);

    expect(find.text('نظامٌ متكامل لإدارة التسميع'), findsOneWidget);
    expect(find.text('تخطي'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding_next')));
    await tester.pumpAndSettle();
    expect(find.text('متابعة دقيقة وتقييم عادل'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding_next')));
    await tester.pumpAndSettle();
    expect(find.text('لوحات صدارة وإنجازات'), findsOneWidget);
    expect(find.text('ابدأ الآن'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding_next')));
    await tester.pumpAndSettle();
    expect(find.text('شاشة الترحيب'), findsOneWidget);
    expect(container.read(onboardingDoneProvider), isTrue);
  });

  group('recitation form', () {
    Future<FakeFirebaseFirestore> pumpForm(WidgetTester tester, {Size size = const Size(390, 844)}) async {
      final db = FakeFirebaseFirestore();
      await db.collection('students').doc('s1').set({
        'fullName': 'عمر سعيد', 'teacherId': 'tm1', 'teacherName': 'محمد عبدالله', 'departmentId': 'male',
        'totalPoints': 100, 'recitationCount': 2,
      });
      final s1 = student('s1', name: 'عمر سعيد', points: 100, count: 2);
      await pumpApp(
        tester,
        size: size,
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: Center(child: TextButton(onPressed: () => context.push('/record/s1'), child: const Text('افتح'))),
            ),
          ),
          GoRoute(path: '/record/:id', builder: (_, s) => RecordRecitationScreen(studentId: s.pathParameters['id']!)),
        ],
        overrides: [
          firestoreProvider.overrideWithValue(db),
          currentUserProvider.overrideWith((ref) => Stream<AppUser?>.value(maleTeacher)),
          myStudentsProvider.overrideWith((ref) => Stream<List<Student>>.value([s1])),
          evaluationSettingsProvider.overrideWith((ref) => Stream.value(EvaluationSettings.defaults())),
        ],
      );
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();
      return db;
    }

    testWidgets('live points calculation and successful submission', (tester) async {
      final db = await pumpForm(tester);
      expect(find.text('تسجيل تسميع'), findsOneWidget);
      expect(find.text('عمر سعيد'), findsWidgets);

      // Choose juz 1 from the full list of 30
      await tester.tap(find.text('جزء'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('rec_portion')));
      await tester.pumpAndSettle();
      expect(find.text('اختر الجزء'), findsOneWidget);
      await tester.tap(find.byKey(const Key('portion_1')));
      await tester.pumpAndSettle();
      expect(find.text('الجزء الأول'), findsOneWidget);

      await tester.tap(find.byKey(const Key('rec_eval_excellentPlus')));
      await tester.pumpAndSettle();
      await scrollTo(tester, const Key('rec_extra'));
      await tester.enterText(find.byKey(const Key('rec_extra')), '15');
      await tester.pumpAndSettle();

      await scrollTo(tester, const Key('rec_summary'));
      final summary = find.byKey(const Key('rec_summary'));
      expect(find.descendant(of: summary, matching: find.text('٦٠')), findsOneWidget);
      expect(find.descendant(of: summary, matching: find.text('١٥')), findsOneWidget);
      expect(find.descendant(of: summary, matching: find.text('٧٥')), findsOneWidget);

      await tester.tap(find.byKey(const Key('rec_submit')));
      await tester.pumpAndSettle();

      final recs = await db.collection('recitations').get();
      expect(recs.docs, hasLength(1));
      final r = recs.docs.single.data();
      expect(r['recitationType'], 'juz');
      expect(r['partNumber'], 1);
      expect(r['evaluation'], 'excellentPlus');
      expect(r['totalPoints'], 75);
      expect((await db.collection('students').doc('s1').get()).get('totalPoints'), 175);
      expect(find.text('افتح'), findsOneWidget, reason: 'form closes after saving');
    });

    testWidgets('validation: portion and evaluation are required, extra is bounded', (tester) async {
      final db = await pumpForm(tester);
      await tester.tap(find.byKey(const Key('rec_submit')));
      await tester.pump();
      expect(find.text('يرجى اختيار السورة'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byKey(const Key('rec_portion')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('portion_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('rec_submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('يرجى اختيار التقييم'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await scrollTo(tester, const Key('rec_extra'));
      await tester.enterText(find.byKey(const Key('rec_extra')), '500');
      await tester.pumpAndSettle();
      expect(find.text('الحد الأقصى للكمية الإضافية ١٠٠'), findsOneWidget);
      expect((await db.collection('recitations').get()).docs, isEmpty);
    });

    testWidgets('lists all 114 surahs with search', (tester) async {
      await pumpForm(tester);
      await tester.tap(find.byKey(const Key('rec_portion')));
      await tester.pumpAndSettle();
      expect(find.text('اختر السورة'), findsOneWidget);
      expect(find.text('سورة الفاتحة'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'الناس');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('portion_114')), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, '114');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('portion_114')), findsOneWidget);
    });
  });

  group('teacher dashboard', () {
    final students = [
      student('1', name: 'أحمد علي', points: 120, last: DateTime.now()),
      student('2', name: 'عمر سعيد', points: 300),
      student('3', name: 'يوسف إبراهيم', points: 40, last: DateTime(2026, 1, 1)),
    ];

    for (final size in [const Size(360, 740), const Size(1024, 768), const Size(1366, 1024)]) {
      testWidgets('cards, search and filters render without overflow at ${size.width.toInt()}w', (tester) async {
        await pumpApp(
          tester,
          size: size,
          routes: [GoRoute(path: '/', builder: (_, _) => const Scaffold(body: TeacherHomeScreen()))],
          overrides: [
            currentUserProvider.overrideWith((ref) => Stream<AppUser?>.value(maleTeacher)),
            myStudentsProvider.overrideWith((ref) => Stream<List<Student>>.value(students)),
          ],
        );
        expect(find.text('محمد عبدالله'), findsOneWidget);
        expect(find.text('تسجيل تسميع'), findsNWidgets(3));
        expect(find.text('الملف الشخصي'), findsNWidgets(3));
        expect(find.text('مجموع النقاط'), findsWidgets);

        await tester.enterText(find.byKey(const Key('teacher_search')), 'احمد');
        await tester.pumpAndSettle();
        expect(find.text('أحمد علي'), findsOneWidget);
        expect(find.text('عمر سعيد'), findsNothing);

        await tester.enterText(find.byKey(const Key('teacher_search')), '');
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.widgetWithText(FilterChip, 'لم يسمّع بعد'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilterChip, 'لم يسمّع بعد'));
        await tester.pumpAndSettle();
        expect(find.text('عمر سعيد'), findsOneWidget);
        expect(find.text('أحمد علي'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('empty state in Arabic', (tester) async {
      await pumpApp(
        tester,
        routes: [GoRoute(path: '/', builder: (_, _) => const Scaffold(body: TeacherHomeScreen()))],
        overrides: [
          currentUserProvider.overrideWith((ref) => Stream<AppUser?>.value(maleTeacher)),
          myStudentsProvider.overrideWith((ref) => Stream<List<Student>>.value(const [])),
        ],
      );
      expect(find.text('لا يوجد طلاب مسجلون لديك بعد'), findsOneWidget);
    });
  });

  testWidgets('leaderboard: podium + separate teacher/department tabs', (tester) async {
    final db = FakeFirebaseFirestore();
    Future<void> add(String id, String name, String teacher, String dep, int pts) => db.collection('students').doc(id).set({
          'fullName': name, 'teacherId': teacher, 'teacherName': teacher == 'tm1' ? 'محمد عبدالله' : 'أحمد يوسف',
          'departmentId': dep, 'totalPoints': pts, 'recitationCount': 1,
        });
    await add('a', 'عبدالرحمن', 'tm1', 'male', 500);
    await add('b', 'عمر', 'tm1', 'male', 300);
    await add('c', 'أنس', 'tm2', 'male', 400);
    await add('d', 'بلال', 'tm2', 'male', 100);
    await add('e', 'عائشة', 'tf1', 'female', 900);

    await pumpApp(
      tester,
      routes: [GoRoute(path: '/', builder: (_, _) => const LeaderboardScreen())],
      overrides: [
        firestoreProvider.overrideWithValue(db),
        currentUserProvider.overrideWith((ref) => Stream<AppUser?>.value(maleTeacher)),
      ],
    );
    // Teacher tab: only own students
    expect(find.text('عبدالرحمن'), findsOneWidget);
    expect(find.text('عمر'), findsOneWidget);
    expect(find.text('أنس'), findsNothing);

    await tester.tap(find.text('قسم الذكور'));
    await tester.pumpAndSettle();
    expect(find.text('أنس'), findsOneWidget);
    expect(find.text('بلال'), findsOneWidget);
    expect(find.text('عائشة'), findsNothing, reason: 'departments are never mixed');
    expect(find.text('٥٠٠'), findsOneWidget);
  });

  testWidgets('login: department switch lists that department only; password required', (tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('login_directory').doc('tm1').set({'displayName': 'محمد عبدالله', 'departmentId': 'male', 'authEmail': 'a@t', 'active': true});
    await db.collection('login_directory').doc('tf1').set({'displayName': 'فاطمة علي', 'departmentId': 'female', 'authEmail': 'b@t', 'active': true});
    await db.collection('login_directory').doc('tx').set({'displayName': 'موقوف', 'departmentId': 'male', 'authEmail': 'c@t', 'active': false});

    await pumpApp(
      tester,
      routes: [GoRoute(path: '/', builder: (_, _) => const LoginScreen())],
      overrides: [
        firestoreProvider.overrideWithValue(db),
        firebaseAuthProvider.overrideWithValue(MockFirebaseAuth()),
      ],
    );
    await tester.tap(find.byKey(const Key('login_teacher_dropdown')));
    await tester.pumpAndSettle();
    expect(find.text('محمد عبدالله'), findsWidgets);
    expect(find.text('فاطمة علي'), findsNothing);
    expect(find.text('موقوف'), findsNothing, reason: 'inactive teachers are hidden');
    await tester.tap(find.text('محمد عبدالله').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('login_teacher_submit')));
    await tester.pumpAndSettle();
    expect(find.text('كلمة المرور مطلوبة'), findsOneWidget);

    await tester.tap(find.text('قسم الإناث'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('login_teacher_dropdown')));
    await tester.pumpAndSettle();
    expect(find.text('فاطمة علي'), findsWidgets);
    expect(find.text('محمد عبدالله'), findsNothing);
  });
}
