import 'package:go_router/go_router.dart';

import '../auth/auth_state.dart';
import '../screens/learn_screen.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/programs_screen.dart';
import '../screens/quiz_screen.dart';
import '../screens/reminders_screen.dart';
import '../screens/shell.dart';
import '../screens/today_screen.dart';
import '../screens/watch_screen.dart';
import '../games/games_hub_screen.dart';
import '../games/game_play_screen.dart';

GoRouter createRouter(AuthState auth) {
  return GoRouter(
    initialLocation: '/today',
    refreshListenable: auth,
    redirect: (context, state) {
      if (!auth.ready) return null;
      final loc = state.matchedLocation;
      final loggingIn = loc == '/login';

      if (!auth.isLoggedIn) {
        return loggingIn ? null : '/login';
      }
      if (loggingIn) return '/today';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                builder: (_, state) => TodayScreen(
                  scrollToNextIncomplete:
                      state.uri.queryParameters['scrollToNext'] == '1',
                  afterSlotId: state.uri.queryParameters['afterSlot'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/learn', builder: (_, __) => const LearnScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/games', builder: (_, __) => const GamesHubScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reminders',
                builder: (_, state) => RemindersScreen(
                  openAdd: state.uri.queryParameters['add'] == '1',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/me', builder: (_, __) => const ProfileScreen()),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/watch/:id',
        builder: (_, state) => WatchScreen(
          contentId: state.pathParameters['id']!,
          preferMock: state.uri.queryParameters['mock'] == '1',
          titleHint: state.uri.queryParameters['title'],
          slotId: state.uri.queryParameters['slotId'],
          timelineDate: state.uri.queryParameters['date'],
          fromToday: state.uri.queryParameters['fromToday'] == '1',
        ),
      ),
      GoRoute(
        path: '/quiz/:id',
        builder: (_, state) => QuizScreen(quizId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/programs',
        builder: (_, __) => const ProgramsScreen(),
      ),
      GoRoute(
        path: '/games/play/:id',
        builder: (_, state) => GamePlayScreen(
          gameId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
}
