import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/session_mode/screens/session_mode_screen.dart';
import '../../features/swipe_session/screens/swipe_session_screen.dart';
import '../../features/recommendation/screens/recommendation_screen.dart';
import '../../data/models/swipe_session.dart';

final routerProvider = Provider<GoRouter>((_) {
  return GoRouter(
    initialLocation: '/modes',
    routes: [
      GoRoute(
        path: '/auth',
        builder: (_, __) => const AuthScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/modes',
        builder: (_, __) => const SessionModeScreen(),
      ),
      GoRoute(
        path: '/session',
        builder: (_, state) {
          final mode = (state.extra as SessionMode?) ?? SessionMode.normal;
          return SwipeSessionScreen(mode: mode);
        },
      ),
      GoRoute(
        path: '/result',
        builder: (_, __) => const RecommendationScreen(),
      ),
    ],
  );
});
