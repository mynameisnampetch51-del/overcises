import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:overcise/core/theme/app_colors.dart';
import 'package:overcise/features/auth/application/auth_controller.dart';
import 'package:overcise/features/auth/data/auth_repository.dart';
import 'package:overcise/features/leaderboard/ranking.dart';
import 'package:overcise/features/progress/progress.dart';
import 'package:overcise/features/quests/quest.dart';
import 'package:overcise/features/splash/splash_screen.dart';
import 'package:overcise/features/workout/camera_view.dart';
import 'package:overcise/features/workout/exercise.dart';
import 'package:overcise/main.dart';

Future<void> passSplash(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(SplashScreen.minimumTime);
  await tester.pumpAndSettle();
}

/// A repository that still remembers a logged-in user.
class ReturningUserRepository extends FakeAuthRepository {
  @override
  Future<AppUser?> currentUser() async =>
      const AppUser(name: 'Nok', email: 'nok@example.com');
}

Future<void> openApp(
  WidgetTester tester, {
  // A phone-sized screen unless a test asks for another.
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      // Tests have no camera.
      overrides: [
        cameraViewProvider.overrideWithValue(
          () => const CameraMessage('test camera'),
        ),
      ],
      child: const OverciseApp(),
    ),
  );
  await passSplash(tester);
}

Future<void> logIn(WidgetTester tester, String email, String password) async {
  await tester.enterText(find.byKey(const Key('email')), email);
  await tester.enterText(find.byKey(const Key('password')), password);
  final button = find.widgetWithText(FilledButton, 'Log in');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
  // The fake repository answers after 600 ms.
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String text) async {
  final target = find.text(text);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> passSeconds(WidgetTester tester, int seconds) async {
  for (var i = 0; i < seconds; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

Future<void> openSitUp(WidgetTester tester) async {
  await openApp(tester);
  await logIn(tester, 'demo@overcise.app', '123456');
  await tapText(tester, 'Start workout →');
  final start = find.byKey(const Key('start-sit-up'));
  await tester.ensureVisible(start);
  await tester.pumpAndSettle();
  await tester.tap(start);
  await tester.pumpAndSettle();
  await tapText(tester, 'Allow camera and continue');
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

Future<void> logOut(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Log out'));
  await tester.pumpAndSettle();
}

Future<void> openSignUp(WidgetTester tester) async {
  await openApp(tester);
  final link = find.widgetWithText(TextButton, 'Sign up');
  await tester.ensureVisible(link);
  await tester.tap(link);
  await tester.pumpAndSettle();
}

Future<void> signUp(
  WidgetTester tester, {
  String name = 'Mali',
  String email = 'mali@example.com',
  String password = 'secret1',
  String? confirm,
}) async {
  await tester.enterText(find.byKey(const Key('name')), name);
  await tester.enterText(find.byKey(const Key('email')), email);
  await tester.enterText(find.byKey(const Key('password')), password);
  await tester.enterText(find.byKey(const Key('confirm')), confirm ?? password);
  final button = find.widgetWithText(FilledButton, 'Create account');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pumpAndSettle();
}

/// Starts the demo sit-up workout and counts for 4 seconds.
Future<void> startCounting(WidgetTester tester) async {
  await openSitUp(tester);
  await tapText(tester, 'Start counting');
  await passSeconds(tester, 4);
}

Future<void> systemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final target = find.byKey(Key(key));
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

const leaveQuestion = 'Leave this workout?';

/// Taps "Keep going" in the question without letting any time pass.
/// (A Quest is also titled "Keep going", hence the button type.)
Future<void> keepGoing(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(TextButton, 'Keep going'));
  await tester.pump();
}

void main() {
  testWidgets('empty form shows validation errors', (tester) async {
    await openApp(tester);
    await logIn(tester, '', '');

    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('bad email and short password are rejected', (tester) async {
    await openApp(tester);
    await logIn(tester, 'demo', '123');

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('At least 6 characters'), findsOneWidget);
  });

  testWidgets('wrong password shows the error banner', (tester) async {
    await openApp(tester);
    await logIn(tester, 'demo@overcise.app', 'wrong-pass');

    expect(find.text('Wrong email or password'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('demo account logs in, and log out returns', (tester) async {
    await openApp(tester);
    await logIn(tester, 'demo@overcise.app', '123456');

    expect(find.text('Hi, Demo'), findsOneWidget);

    await logOut(tester);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('sign up rejects empty and mismatched input', (tester) async {
    await openSignUp(tester);
    await signUp(tester, name: '', confirm: 'different');

    expect(find.text('Enter your name'), findsOneWidget);
    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('an existing email shows an error, cleared on leaving', (
    tester,
  ) async {
    await openSignUp(tester);
    await signUp(tester, email: 'demo@overcise.app');
    expect(find.text('This email already has an account'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('This email already has an account'), findsNothing);
  });

  testWidgets('a new account is signed in and can log in again', (
    tester,
  ) async {
    await openSignUp(tester);
    await signUp(tester);
    expect(find.text('Hi, Mali'), findsOneWidget);

    await logOut(tester);
    await logIn(tester, 'mali@example.com', 'secret1');
    expect(find.text('Hi, Mali'), findsOneWidget);
  });

  testWidgets('splash shows first, then the login screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OverciseApp()));
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);

    await passSplash(tester);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('splash sends a returning user to Home', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(ReturningUserRepository()),
        ],
        child: const OverciseApp(),
      ),
    );
    await passSplash(tester);

    expect(find.text('Hi, Nok'), findsOneWidget);
  });

  testWidgets('Home shows the demo Points and Level', (tester) async {
    await openApp(tester);
    await logIn(tester, 'demo@overcise.app', '123456');

    expect(find.text('340'), findsOneWidget);
    expect(find.text('Level 3'), findsOneWidget);
    expect(find.text('40 / 300 XP', findRichText: true), findsOneWidget);
  });

  testWidgets('tabs, Level and Start workout open their screens', (
    tester,
  ) async {
    await openApp(tester);
    await logIn(tester, 'demo@overcise.app', '123456');

    await openTab(tester, 'Quests');
    expect(find.text('Daily Quests'), findsOneWidget);
    await openTab(tester, 'Ranking');
    expect(find.text('Monthly Ranking'), findsOneWidget);
    await openTab(tester, 'Home');

    await tapText(tester, 'See progress and bonus →');
    expect(find.text('My level'), findsOneWidget);
    expect(find.textContaining('+120 Points'), findsOneWidget);
    await tapText(tester, 'Back');

    await tapText(tester, 'Start workout →');
    expect(find.text("Choose today's exercise"), findsOneWidget);
    await tapText(tester, 'Back');
    expect(find.text('Ready to move?'), findsOneWidget);
  });

  testWidgets('each exercise has its own Guide leading to the workout', (
    tester,
  ) async {
    await openApp(tester);
    await logIn(tester, 'demo@overcise.app', '123456');
    await tapText(tester, 'Start workout →');

    for (final exercise in Exercise.values) {
      final howTo = find.byKey(Key('howto-${exercise.slug}'));
      await tester.ensureVisible(howTo);
      await tester.pumpAndSettle();
      await tester.tap(howTo);
      await tester.pumpAndSettle();
      expect(find.text(exercise.steps.first), findsOneWidget);
      expect(find.text(exercise.cameraTip), findsOneWidget);

      await tapText(tester, 'Try it! →');
      expect(find.text('Your permission'), findsOneWidget);
      await tapText(tester, 'Back');
      await tapText(tester, 'Back');
      expect(find.text("Choose today's exercise"), findsOneWidget);
    }
  });

  testWidgets('Start goes straight to the workout', (tester) async {
    await openApp(tester);
    await logIn(tester, 'demo@overcise.app', '123456');
    await tapText(tester, 'Start workout →');

    final start = find.byKey(const Key('start-sit-up'));
    await tester.ensureVisible(start);
    await tester.pumpAndSettle();
    await tester.tap(start);
    await tester.pumpAndSettle();

    expect(find.text('Your permission'), findsOneWidget);
    await tapText(tester, 'Allow camera and continue');
    expect(find.text('Sit-up'), findsOneWidget);
    expect(find.textContaining('reps are simulated'), findsOneWidget);
  });

  testWidgets('redeeming spends Points and adds a coupon', (tester) async {
    await openApp(tester);
    await logIn(tester, 'demo@overcise.app', '123456');
    await openTab(tester, 'Rewards');
    expect(find.text('340 Points'), findsOneWidget);
    expect(find.text('My coupons · 0'), findsOneWidget);

    await tapText(tester, 'Redeem 220');
    await tapText(tester, 'Redeem');

    expect(find.text('120 Points'), findsOneWidget);
    expect(find.text('My coupons · 1'), findsOneWidget);
    expect(find.text('DEMO-20-001'), findsOneWidget);
    // 120 left: enough for 10%, not for another 20%.
    expect(find.text('100 more Points needed'), findsOneWidget);
  });

  testWidgets('cancelling keeps the Points', (tester) async {
    await openApp(tester);
    await logIn(tester, 'demo@overcise.app', '123456');
    await openTab(tester, 'Rewards');

    await tapText(tester, 'Redeem 100');
    await tapText(tester, 'Cancel');

    expect(find.text('340 Points'), findsOneWidget);
    expect(find.text('My coupons · 0'), findsOneWidget);
  });

  test('spending Points does not lower the Ranking', () {
    const before = UserProgress(earnedPoints: 340, monthPoints: 340);
    final after = before.withCoupon(
      const Coupon(percent: 20, cost: 220, code: 'x'),
    );

    expect(after.balance, 120);
    expect(rankFor(after.monthPoints).place, rankFor(before.monthPoints).place);
  });

  test('a new account is outside the top 20', () {
    final rank = rankFor(0);

    expect(rank.place, 26);
    expect(rank.pointsToRewardZone, 115);
  });

  // Any layout overflow fails these tests.
  for (final (name, size) in const [
    ('small phone', Size(360, 640)),
    ('phone on its side', Size(844, 390)),
    ('tablet', Size(768, 1024)),
    ('desktop', Size(1440, 900)),
  ]) {
    testWidgets('every page lays out on a $name', (tester) async {
      await openApp(tester, size: size);
      final signUpLink = find.widgetWithText(TextButton, 'Sign up');
      await tester.ensureVisible(signUpLink);
      await tester.tap(signUpLink);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await logIn(tester, 'demo@overcise.app', '123456');

      final rail = size.width >= 600 && size.height >= 500;
      expect(find.byType(NavigationRail), rail ? findsOneWidget : findsNothing);
      expect(find.byType(NavigationBar), rail ? findsNothing : findsOneWidget);
      expect(find.byTooltip('Log out'), findsOneWidget);

      final nav = find.byType(rail ? NavigationRail : NavigationBar);
      for (final tab in ['Quests', 'Ranking', 'Rewards', 'Home']) {
        // A narrow rail also shows labels, so match inside the navigation.
        await tester.tap(
          rail && size.width >= 1100 || !rail
              ? find.descendant(of: nav, matching: find.text(tab)).first
              : find.descendant(of: nav, matching: find.text(tab)),
        );
        await tester.pumpAndSettle();
      }

      await tapText(tester, 'See progress and bonus →');
      await tapText(tester, 'Back');
      await tapText(tester, 'Start workout →');
      final howTo = find.byKey(const Key('howto-sit-up'));
      await tester.ensureVisible(howTo);
      await tester.pumpAndSettle();
      await tester.tap(howTo);
      await tester.pumpAndSettle();
      await tapText(tester, 'Try it! →');
      await tapText(tester, 'Allow camera and continue');
      await tapText(tester, 'Start counting');
      await passSeconds(tester, 6);
      await tapText(tester, 'Finish and see result');
      expect(find.text('+3'), findsOneWidget);
    });
  }

  testWidgets('a finished workout adds Points, XP and a summary', (
    tester,
  ) async {
    await openSitUp(tester);
    await tapText(tester, 'Start counting');
    await passSeconds(tester, 20);
    await tapText(tester, 'Finish and see result');

    expect(find.text('+10'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('0:20'), findsOneWidget);
    // 3.8 MET x 60 kg x 20 s.
    expect(find.text('1.3 kcal'), findsOneWidget);

    await tapText(tester, 'Back to Home');
    expect(find.text('350'), findsOneWidget);
    expect(find.text('50 / 300 XP', findRichText: true), findsOneWidget);
    expect(find.text('10 / 200 Points', findRichText: true), findsOneWidget);
  });

  testWidgets('pause and leaving the tab stop the count', (tester) async {
    await openSitUp(tester);
    await tapText(tester, 'Start counting');
    await passSeconds(tester, 4);
    await tapText(tester, 'Pause');
    await passSeconds(tester, 10);
    expect(find.text('0:04'), findsOneWidget);

    await tapText(tester, 'Resume');
    await openTab(tester, 'Rewards');
    await passSeconds(tester, 10);
    await openTab(tester, 'Home');

    expect(find.text('0:04'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
  });

  test('the daily cap limits Points but not XP', () {
    const start = UserProgress(todayPoints: 195);
    final (next, result) = start.withWorkout(
      exercise: Exercise.jumpingJack,
      reps: 20,
      seconds: 40,
    );

    expect(result.points, 5);
    expect(result.capped, isTrue);
    expect(next.todayPoints, 200);
    expect(next.xp, 20);
  });

  test('finishing a level pays its bonus', () {
    const start = UserProgress(xp: 90);
    final (next, result) = start.withWorkout(
      exercise: Exercise.sitUp,
      reps: 15,
      seconds: 30,
    );

    expect(next.level, 2);
    expect(result.levelBonus, 40);
    expect(next.earnedPoints, 55);
    expect(next.todayPoints, 15);
  });

  testWidgets('finished Quests can be claimed once for bonus Points', (
    tester,
  ) async {
    await openSitUp(tester);
    await tapText(tester, 'Start counting');
    await passSeconds(tester, 60);
    await tapText(tester, 'Finish and see result');
    await tapText(tester, "See today's Quests →");

    // 1 workout and 30 reps are done; 10 minutes is not.
    expect(find.text('1 / 1'), findsOneWidget);
    expect(find.text('30 / 30'), findsOneWidget);
    expect(find.text('1:00 / 10:00'), findsOneWidget);
    expect(find.byKey(const Key('train-tenMinutes')), findsOneWidget);

    await tapText(tester, 'Claim +15');
    await tapText(tester, 'Claim +35');
    expect(find.text('Claimed'), findsNWidgets(2));
    expect(find.textContaining('Claim +'), findsNothing);

    await openTab(tester, 'Home');
    // 340 + 30 from reps + 15 + 35.
    expect(find.text('420'), findsOneWidget);
    expect(find.text('2 of 3 claimed'), findsOneWidget);
    // Bonus Points give no XP.
    expect(find.text('70 / 300 XP', findRichText: true), findsOneWidget);
  });

  test('a Quest cannot be claimed early or twice', () {
    const empty = UserProgress();
    expect(empty.withClaim(Quest.getMoving).earnedPoints, 0);

    final (worked, _) = empty.withWorkout(
      exercise: Exercise.sitUp,
      reps: 1,
      seconds: 2,
    );
    final once = worked.withClaim(Quest.getMoving);
    final twice = once.withClaim(Quest.getMoving);

    expect(once.earnedPoints, 16);
    expect(twice.earnedPoints, 16);
    expect(once.todayPoints, 1);
  });

  testWidgets('Ranking shows my place and moves after a workout', (
    tester,
  ) async {
    await openApp(tester);
    await logIn(tester, 'demo@overcise.app', '123456');
    await openTab(tester, 'Ranking');

    expect(find.text('#12'), findsOneWidget);
    expect(find.text('340 Points this month'), findsOneWidget);
    expect(find.textContaining('You are in the top 20.'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('my-row')),
        matching: find.text('340'),
      ),
      findsOneWidget,
    );

    await tapText(tester, 'Earn more Points →');
    final start = find.byKey(const Key('start-sit-up'));
    await tester.ensureVisible(start);
    await tester.pumpAndSettle();
    await tester.tap(start);
    await tester.pumpAndSettle();
    await tapText(tester, 'Allow camera and continue');
    await tapText(tester, 'Start counting');
    await passSeconds(tester, 70);
    await tapText(tester, 'Finish and see result');
    await openTab(tester, 'Ranking');

    // 375 Points passes Aom, who has 372.
    expect(find.text('#11'), findsOneWidget);
    expect(find.text('375 Points this month'), findsOneWidget);
  });

  testWidgets('a new account sees how far the top 20 is', (tester) async {
    await openApp(tester);
    await openSignUp(tester);
    await signUp(tester, name: 'Nok', email: 'nok@example.com');
    await openTab(tester, 'Ranking');

    expect(find.text('#26'), findsOneWidget);
    expect(find.text('115 more Points to reach the top 20.'), findsOneWidget);
  });

  testWidgets('Back asks before discarding a workout', (tester) async {
    await startCounting(tester);
    await tapText(tester, 'Back');

    expect(find.text(leaveQuestion), findsOneWidget);
    expect(find.text('Your reps and time will be lost.'), findsOneWidget);
    // Nothing is counted while the question is open.
    await passSeconds(tester, 5);
    await keepGoing(tester);
    expect(find.text('0:04'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
    // Still running.
    await passSeconds(tester, 1);
    expect(find.text('0:05'), findsOneWidget);

    await tapText(tester, 'Pause');
    await tapText(tester, 'Back');
    await keepGoing(tester);
    await passSeconds(tester, 3);
    expect(find.text('0:05'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);

    await tapText(tester, 'Back');
    await tapText(tester, 'Leave');
    expect(find.text('How to'), findsOneWidget);
    await openTab(tester, 'Home');
    expect(find.text('340'), findsOneWidget);
  });

  testWidgets('system back asks before discarding a workout', (tester) async {
    await startCounting(tester);
    await systemBack(tester);
    expect(find.text(leaveQuestion), findsOneWidget);

    await keepGoing(tester);
    expect(find.text('0:04'), findsOneWidget);

    await systemBack(tester);
    await tapText(tester, 'Leave');
    expect(find.text('How to'), findsOneWidget);
  });

  testWidgets('tapping Home again asks before discarding', (tester) async {
    await startCounting(tester);
    await openTab(tester, 'Home');
    expect(find.text(leaveQuestion), findsOneWidget);

    await keepGoing(tester);
    expect(find.text('0:04'), findsOneWidget);

    await openTab(tester, 'Home');
    await tapText(tester, 'Leave');
    expect(find.text('Ready to move?'), findsOneWidget);
  });

  testWidgets('Log out on the side rail asks first', (tester) async {
    await startCounting(tester);
    // Paused, so that resizing cannot add a second.
    await tapText(tester, 'Pause');
    tester.view.physicalSize = const Size(768, 1024);
    await tester.pumpAndSettle();
    await logOut(tester);
    expect(find.text(leaveQuestion), findsOneWidget);

    await keepGoing(tester);
    expect(find.text('0:04'), findsOneWidget);

    await logOut(tester);
    await tapText(tester, 'Leave');
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('Go train from Quests asks first', (tester) async {
    await startCounting(tester);
    await openTab(tester, 'Quests');
    await tapKey(tester, 'train-tenMinutes');
    expect(find.text(leaveQuestion), findsOneWidget);

    await keepGoing(tester);
    expect(find.text('Daily Quests'), findsOneWidget);
    // Switching tabs keeps the paused workout.
    await openTab(tester, 'Home');
    expect(find.text('0:04'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);

    await openTab(tester, 'Quests');
    await tapKey(tester, 'train-tenMinutes');
    await tapText(tester, 'Leave');
    expect(find.text("Choose today's exercise"), findsOneWidget);
  });

  testWidgets('Earn more Points from Ranking asks first', (tester) async {
    await startCounting(tester);
    await openTab(tester, 'Ranking');
    await tapText(tester, 'Earn more Points →');
    expect(find.text(leaveQuestion), findsOneWidget);

    await tapText(tester, 'Leave');
    expect(find.text("Choose today's exercise"), findsOneWidget);
  });

  testWidgets('Back before counting does not ask', (tester) async {
    await openSitUp(tester);
    await tapText(tester, 'Back');
    expect(find.text(leaveQuestion), findsNothing);
    expect(find.text('How to'), findsOneWidget);

    await tapText(tester, 'Try it! →');
    await systemBack(tester);
    expect(find.text(leaveQuestion), findsNothing);
    expect(find.text('How to'), findsOneWidget);
  });

  testWidgets('leaving after finishing does not ask', (tester) async {
    await startCounting(tester);
    await tapText(tester, 'Finish and see result');
    await openTab(tester, 'Home');

    expect(find.text(leaveQuestion), findsNothing);
    expect(find.text('Ready to move?'), findsOneWidget);
  });

  test('button green has at least 4.5:1 contrast with white', () {
    // WCAG contrast ratio, with white's luminance being 1.
    final ratio = 1.05 / (AppColors.primaryDark.computeLuminance() + 0.05);

    expect(ratio, greaterThanOrEqualTo(4.5));
  });

  testWidgets('a very large rep count sits over the camera', (tester) async {
    await startCounting(tester);

    final reps = tester.widget<Text>(find.byKey(const Key('big-reps')));
    expect(reps.data, '2');
    expect(reps.style!.fontSize, greaterThanOrEqualTo(96));
    expect(find.text('0:04'), findsOneWidget);
    final tip = tester.widget<Text>(find.text(Exercise.sitUp.cameraTip));
    expect(tip.style!.fontSize, greaterThanOrEqualTo(14));
  });

  testWidgets('Summary and Home say which Quests are ready to claim', (
    tester,
  ) async {
    await openSitUp(tester);
    await tapText(tester, 'Start counting');
    await passSeconds(tester, 60);
    await tapText(tester, 'Finish and see result');
    expect(find.text('2 Quests ready to claim'), findsOneWidget);

    await tapText(tester, 'Back to Home');
    expect(find.text('2 Quests ready to claim'), findsOneWidget);

    await openTab(tester, 'Quests');
    await tapText(tester, 'Claim +15');
    await openTab(tester, 'Home');
    expect(find.text('1 Quest ready to claim'), findsOneWidget);

    await openTab(tester, 'Quests');
    await tapText(tester, 'Claim +35');
    await openTab(tester, 'Home');
    expect(find.text('2 of 3 claimed'), findsOneWidget);
    expect(find.textContaining('ready to claim'), findsNothing);
  });

  testWidgets('Summary hides a Level bonus of 0', (tester) async {
    await startCounting(tester);
    await tapText(tester, 'Finish and see result');

    expect(find.text('Experience'), findsOneWidget);
    expect(find.text('Level bonus'), findsNothing);
  });

  testWidgets('Summary shows a Level bonus that was paid', (tester) async {
    await openSignUp(tester);
    await signUp(tester);
    await tapText(tester, 'Start workout →');
    await tapKey(tester, 'start-sit-up');
    await tapText(tester, 'Allow camera and continue');
    await tapText(tester, 'Start counting');
    // 100 reps finish Level 1.
    await passSeconds(tester, 200);
    await tapText(tester, 'Finish and see result');

    expect(find.text('Level bonus'), findsOneWidget);
    expect(find.text('+40 Points'), findsOneWidget);
  });

  testWidgets('Login does not promise a streak', (tester) async {
    await openApp(tester);

    expect(find.text('Log in to keep moving.'), findsOneWidget);
    expect(find.textContaining('streak'), findsNothing);
  });

  testWidgets('Ranking says top 20 Rewards are coming soon', (tester) async {
    await openApp(tester);
    await logIn(tester, 'demo@overcise.app', '123456');
    await openTab(tester, 'Ranking');

    expect(
      find.text('You are in the top 20. Top 20 Rewards are coming soon.'),
      findsOneWidget,
    );
    expect(
      find.text('Top 20 Rewards (coming soon) above this line'),
      findsOneWidget,
    );
    expect(find.textContaining('win a'), findsNothing);
  });

  testWidgets('Level rules mention the daily limit for reps', (tester) async {
    await openApp(tester);
    await logIn(tester, 'demo@overcise.app', '123456');
    await tapText(tester, 'See progress and bonus →');

    expect(
      find.textContaining('Reps give up to 200 Points a day.'),
      findsOneWidget,
    );
  });

  testWidgets('a different account is asked for the camera again', (
    tester,
  ) async {
    await openSitUp(tester);
    await openTab(tester, 'Home');
    // Home is still scrolled down to where Start workout was.
    await tester.ensureVisible(find.byTooltip('Log out'));
    await tester.pumpAndSettle();
    await logOut(tester);

    final link = find.widgetWithText(TextButton, 'Sign up');
    await tester.ensureVisible(link);
    await tester.tap(link);
    await tester.pumpAndSettle();
    await signUp(tester);
    await tapText(tester, 'Start workout →');
    await tapKey(tester, 'start-sit-up');

    expect(find.text('Your permission'), findsOneWidget);
  });

  testWidgets('a workout lost to a typed address does not ask later', (
    tester,
  ) async {
    await startCounting(tester);
    // Stands in for the browser's back button or address bar.
    GoRouter.of(tester.element(find.text('Working out'))).go('/home/level');
    await tester.pumpAndSettle();
    await tapText(tester, 'Back');

    expect(find.text(leaveQuestion), findsNothing);
    expect(find.text('Ready to move?'), findsOneWidget);
  });
}
