import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../../data/repositories/venue_repository.dart';
import '../../core/services/groq_service.dart';
import '../../data/services/recommendation_service.dart';
import '../../data/services/venue_seed_service.dart';

// ── Firebase ──────────────────────────────────────────────────────────────────

final authProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);

final firestoreProvider =
    Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('SharedPreferences must be overridden'),
);

final authStateProvider = StreamProvider<User?>(
  (_) => FirebaseAuth.instance.authStateChanges(),
);

// ── Repositories ──────────────────────────────────────────────────────────────

final venueRepositoryProvider = Provider<VenueRepository>(
  (ref) => VenueRepository(ref.read(firestoreProvider)),
);

/// Seeds Firestore with venues (no-op if already seeded),
/// then loads them into the repository cache.
final venuesInitProvider = FutureProvider<void>((ref) async {
  final repo = ref.read(venueRepositoryProvider);
  final firestore = ref.read(firestoreProvider);
  try {
    await VenueSeedService(firestore)
        .seedIfEmpty()
        .timeout(const Duration(seconds: 10));
    await repo.loadFromFirestore().timeout(const Duration(seconds: 10));
  } catch (_) {
    // Firestore недоступен — продолжаем без данных
  }
});

final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => UserProfileRepository(ref.read(firestoreProvider)),
);

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  return ref.read(userProfileRepositoryProvider).load(user.uid);
});

/// Loads swipe stats for all venues owned by the user.
final ownedVenueStatsProvider = FutureProvider<List<VenueStats>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final ids = profile?.ownedVenueIds ?? [];
  if (ids.isEmpty) return [];
  final repo = ref.read(venueRepositoryProvider);
  final results = await Future.wait(ids.map((id) => repo.loadVenueStats(id)));
  return results.whereType<VenueStats>().toList();
});

// ── App settings ──────────────────────────────────────────────────────────────

const _themeModeKey = 'app_theme_mode';

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  return ThemeModeController(ref.read(sharedPreferencesProvider));
});

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._prefs) : super(_readMode(_prefs));

  final SharedPreferences _prefs;

  static ThemeMode _readMode(SharedPreferences prefs) {
    final value = prefs.getString(_themeModeKey);
    return switch (value) {
      'dark' => ThemeMode.dark,
      _ => ThemeMode.light,
    };
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    await _prefs.setString(
      _themeModeKey,
      next == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}

// ── Services ──────────────────────────────────────────────────────────────────

final recommendationServiceProvider = Provider<RecommendationService>(
    (ref) => RecommendationService(ref.read(venueRepositoryProvider)));

final groqServiceProvider = Provider<GroqService>((ref) {
  final service = GroqService(apiKey: AppConstants.groqApiKey);
  ref.onDispose(service.dispose);
  return service;
});

final groqConfiguredProvider = Provider<bool>((ref) {
  return ref.watch(groqServiceProvider).isConfigured;
});
