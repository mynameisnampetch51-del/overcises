import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/home/home_screen.dart';
import '../features/leaderboard/ranking_screen.dart';
import '../features/level/level_screen.dart';
import '../features/quests/quests_screen.dart';
import '../features/rewards/rewards_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/splash/splash_screen.dart';
import '../features/workout/exercise.dart';
import '../features/workout/how_to_screen.dart';
import '../features/workout/selection_screen.dart';
import '../features/workout/workout_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run the redirect whenever someone signs in or out.
  final authChanged = ValueNotifier<int>(0);
  ref.listen(
    authControllerProvider.select((state) => state.user),
    (_, _) => authChanged.value++,
  );

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: authChanged,
    redirect: (context, state) {
      // The splash screen decides where to go after it has checked.
      if (state.matchedLocation == '/splash') return null;
      final signedIn = ref.read(authControllerProvider).user != null;
      final onAuthPage = const [
        '/login',
        '/signup',
      ].contains(state.matchedLocation);

      if (!signedIn && !onAuthPage) return '/login';
      if (signedIn && onAuthPage) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, _) => const SignUpScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          // Pages under Home keep the bottom bar, as in the Figma.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, _) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'workout',
                    builder: (_, _) => const WorkoutSelectionScreen(),
                    routes: [
                      GoRoute(
                        path: ':exercise',
                        // An unknown name goes back to the list.
                        redirect: (_, state) =>
                            Exercise.fromSlug(
                                  state.pathParameters['exercise'],
                                ) ==
                                null
                            ? '/home/workout'
                            : null,
                        builder: (_, state) => HowToScreen(
                          exercise: Exercise.fromSlug(
                            state.pathParameters['exercise'],
                          )!,
                        ),
                        routes: [
                          GoRoute(
                            path: 'active',
                            builder: (_, state) => ActiveWorkoutScreen(
                              exercise: Exercise.fromSlug(
                                state.pathParameters['exercise'],
                              )!,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'level',
                    builder: (_, _) => const LevelScreen(),
                  ),
                ],
              ),
            ],
          ),
          for (final (path, screen) in const [
            ('/quests', QuestsScreen()),
            ('/ranking', RankingScreen()),
            ('/rewards', RewardsScreen()),
          ])
            StatefulShellBranch(
              routes: [GoRoute(path: path, builder: (_, _) => screen)],
            ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    authChanged.dispose();
  });
  return router;
});
