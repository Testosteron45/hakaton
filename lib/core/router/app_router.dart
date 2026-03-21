import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/map/screens/krasnodar_map_screen.dart';
import '../../features/profile/screens/loading_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/session_mode/screens/session_mode_screen.dart';
import '../../features/swipe_session/screens/swipe_session_screen.dart';
import '../../features/recommendation/screens/recommendation_screen.dart';
import '../../data/models/swipe_session.dart';
import '../../shared/providers/providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  final notifier = _AuthNotifier(FirebaseAuth.instance.authStateChanges());
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/loading',
    refreshListenable: notifier,
    redirect: (context, state) {
      if (authState.isLoading) return '/loading';
      final isAuth = authState.valueOrNull != null;
      final loc = state.matchedLocation;
      if (!isAuth && loc != '/auth') return '/auth';
      if (isAuth && loc == '/auth') return '/loading';
      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (_, __) => const LoadingScreen(),
      ),
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
        path: '/profile',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/map',
        builder: (_, __) => const KrasnodarMapScreen(),
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

class _AuthNotifier extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;

  _AuthNotifier(Stream<dynamic> stream) {
    _sub = stream.listen(
      (_) => notifyListeners(),
      onError: (_) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
