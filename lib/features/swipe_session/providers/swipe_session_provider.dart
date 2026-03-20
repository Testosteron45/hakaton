import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/swipe_session.dart';
import '../../../data/repositories/venue_repository.dart';
import '../../../shared/providers/providers.dart';

// ── Session state ─────────────────────────────────────────────────────────────

class SwipeSessionNotifier extends StateNotifier<SwipeSession?> {
  SwipeSessionNotifier(this._venueRepo) : super(null);

  final VenueRepository _venueRepo;

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
    state = s.copyWith(
      swipes: newSwipes,
      currentIndex: s.currentIndex + 1,
    );
  }

  void reset() => state = null;
}

final swipeSessionProvider =
    StateNotifierProvider<SwipeSessionNotifier, SwipeSession?>((ref) {
  return SwipeSessionNotifier(ref.read(venueRepositoryProvider));
});

// ── Recommendation ─────────────────────────────────────────────────────────────

final recommendationProvider = Provider((ref) {
  final session = ref.watch(swipeSessionProvider);
  if (session == null || !session.isFinished) return null;
  final service = ref.read(recommendationServiceProvider);
  return service.recommend(session);
});
