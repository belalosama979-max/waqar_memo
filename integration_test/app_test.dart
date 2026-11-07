// End-to-end test on a real Android emulator against the local Firebase
// Emulator Suite (seeded with functions/scripts/seed-emulator.js).
//
//   flutter test integration_test/app_test.dart \
//     --dart-define=USE_FIREBASE_EMULATOR=true -d emulator-5554
import 'package:alwaqar/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Future<void> settle(WidgetTester t, {int seconds = 2}) async {
  for (var i = 0; i < seconds * 10; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> waitFor(WidgetTester t, Finder f, {int seconds = 30}) async {
  for (var i = 0; i < seconds * 10; i++) {
    await t.pump(const Duration(milliseconds: 100));
    if (f.evaluate().isNotEmpty) return;
  }
  final visible = t.widgetList<Text>(find.byType(Text)).map((w) => w.data).whereType<String>().join(' | ');
  throw TestFailure('Timed out waiting for $f. On screen: $visible');
}

/// Hides the keyboard, scrolls [key] into view if needed, then taps it.
Future<void> tapKey(WidgetTester t, Key key) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await settle(t, seconds: 1);
  final f = find.byKey(key);
  if (f.evaluate().isEmpty || !t.getRect(f).overlaps(t.getRect(find.byType(MaterialApp).first))) {
    await t.scrollUntilVisible(f, 120, scrollable: find.byType(Scrollable).first);
  } else {
    await t.ensureVisible(f);
  }
  await settle(t, seconds: 1);
  await t.tap(f);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('teacher journey: onboarding → login → first password change → record recitation → logout', (t) async {
    app.main();
    await waitFor(t, find.text('نظامٌ متكامل لإدارة التسميع'));

    // Onboarding (3 pages)
    for (var i = 0; i < 3; i++) {
      await t.tap(find.byKey(const Key('onboarding_next')));
      await settle(t);
    }
    await waitFor(t, find.byKey(const Key('welcome_login')));
    await t.tap(find.byKey(const Key('welcome_login')));
    await settle(t);

    // Teacher login with the seeded temporary password (محمد123)
    await waitFor(t, find.byKey(const Key('login_teacher_dropdown')));
    await t.tap(find.byKey(const Key('login_teacher_dropdown')));
    await settle(t);
    await t.tap(find.text('محمد عبدالله').last);
    await settle(t);
    await t.enterText(find.byKey(const Key('login_teacher_password')), 'محمد123');
    await tapKey(t, const Key('login_teacher_submit'));

    // Forced first-login password change
    await waitFor(t, find.byKey(const Key('cp_new')));
    await t.enterText(find.byKey(const Key('cp_current')), 'محمد123');
    await t.enterText(find.byKey(const Key('cp_new')), 'Waqar2026x');
    await t.enterText(find.byKey(const Key('cp_confirm')), 'Waqar2026x');
    await tapKey(t, const Key('cp_submit'));

    // Teacher dashboard with own students only
    await waitFor(t, find.byKey(const Key('teacher_search')), seconds: 40);
    await waitFor(t, find.text('عبدالرحمن خالد'));
    expect(find.text('عائشة أحمد'), findsNothing, reason: 'female department student must not be visible');

    // Record a recitation
    await t.tap(find.text('تسجيل تسميع').first);
    await waitFor(t, find.byKey(const Key('rec_portion')));
    await t.tap(find.byKey(const Key('rec_portion')));
    await settle(t);
    await t.tap(find.byKey(const Key('portion_1')));
    await settle(t);
    await tapKey(t, const Key('rec_eval_excellentPlus'));
    await settle(t, seconds: 1);
    await t.scrollUntilVisible(find.byKey(const Key('rec_extra')), 150, scrollable: find.byType(Scrollable).first);
    await t.enterText(find.byKey(const Key('rec_extra')), '10');
    await settle(t, seconds: 1);
    await tapKey(t, const Key('rec_submit'));
    await waitFor(t, find.text('تم تسجيل التسميع بنجاح ✓'));

    // Leaderboard tab
    await t.tap(find.text('الصدارة'));
    await settle(t, seconds: 3);
    expect(find.text('لوحة الصدارة'), findsOneWidget);

    // Logout
    await t.tap(find.text('المزيد'));
    await settle(t);
    await t.tap(find.byKey(const Key('logout_tile')));
    await settle(t);
    await t.tap(find.text('خروج').last);
    await waitFor(t, find.byKey(const Key('welcome_login')));
  });
}
