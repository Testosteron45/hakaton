import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/swipe_session.dart';
import '../../../data/models/venue.dart';
import '../../../data/repositories/venue_repository.dart';
import '../../../data/repositories/user_profile_repository.dart';
import '../../../shared/providers/providers.dart';

// ── Session state ─────────────────────────────────────────────────────────────

final lastCompletedLikedVenueIdsProvider = StateProvider<List<String>>(
  (_) => const [],
);

class SwipeSessionNotifier extends StateNotifier<SwipeSession?> {
  SwipeSessionNotifier(
    this._ref,
    this._venueRepo,
    this._profileRepo,
    this._auth,
  ) : super(null);

  final Ref _ref;
  final VenueRepository _venueRepo;
  final UserProfileRepository _profileRepo;
  final FirebaseAuth _auth;

  void startSession(SessionMode mode) {
    final queue = _venueRepo.buildSessionQueue(mode);
    state = SwipeSession(
      mode: mode,
      queue: queue,
      swipes: const {},
      currentIndex: 0,
    );
  }

  void swipe(String venueId, bool liked) {
    final s = state;
    if (s == null) return;
    final newSwipes = Map<String, bool>.from(s.swipes)..[venueId] = liked;
    final nextState = s.copyWith(
      swipes: newSwipes,
      currentIndex: s.currentIndex + 1,
    );
    state = nextState;
    if (nextState.isFinished) {
      _ref.read(lastCompletedLikedVenueIdsProvider.notifier).state = [
        for (final entry in nextState.swipes.entries)
          if (entry.value) entry.key,
      ];
      _persistAll(nextState);
    }
  }

  void reset() => state = null;

  // ── Persistence ─────────────────────────────────────────────────────────────

  void _persistAll(SwipeSession session) {
    _persistUserInterests(session);
    _persistVenueStats(session);
  }

  /// Writes liked-venue counters to user_profiles/{uid}.
  void _persistUserInterests(SwipeSession session) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final liked = _likedVenues(session);
    if (liked.isEmpty) return;

    _profileRepo.updateInterests(
      uid: uid,
      likedTypesDelta: _countBy(liked, (v) => v.type.name),
      likedFeaturesDelta: _countFeatures(liked),
      preferredPriceDelta: _countBy(liked, (v) => v.price.name),
      preferredDistanceDelta: _countBy(liked, (v) => v.distance.name),
      preferredGroupDelta: _countBy(liked, (v) => v.group.name),
    );
  }

  /// Batch-writes likes + dislikes + impressions to each venue document.
  void _persistVenueStats(SwipeSession session) {
    final records = session.swipes.entries.map((e) {
      return VenueSwipeRecord(
        venueId: e.key,
        liked: e.value,
        mode: session.mode,
      );
    }).toList();

    _venueRepo.updateVenueStats(records);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  List<Venue> _likedVenues(SwipeSession session) => session.swipes.entries
      .where((e) => e.value)
      .map((e) => session.queue.firstWhere((v) => v.id == e.key))
      .toList();

  Map<String, int> _countBy(List<Venue> venues, String Function(Venue) key) {
    final m = <String, int>{};
    for (final v in venues) {
      m[key(v)] = (m[key(v)] ?? 0) + 1;
    }
    return m;
  }

  Map<String, int> _countFeatures(List<Venue> venues) {
    final m = <String, int>{};
    for (final v in venues) {
      for (final f in v.features) {
        m[f.name] = (m[f.name] ?? 0) + 1;
      }
    }
    return m;
  }
}

final swipeSessionProvider =
    StateNotifierProvider<SwipeSessionNotifier, SwipeSession?>((ref) {
  return SwipeSessionNotifier(
    ref,
    ref.read(venueRepositoryProvider),
    ref.read(userProfileRepositoryProvider),
    ref.read(authProvider),
  );
});

// ── Recommendation ─────────────────────────────────────────────────────────────

final recommendationProvider = Provider((ref) {
  final session = ref.watch(swipeSessionProvider);
  if (session == null || !session.isFinished) return null;
  final service = ref.read(recommendationServiceProvider);
  final profile = ref.watch(userProfileProvider).valueOrNull;
  return service.recommend(session, profile: profile);
});
