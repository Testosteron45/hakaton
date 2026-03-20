import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/venue_repository.dart';
import '../../data/services/recommendation_service.dart';

// ── Firebase ──────────────────────────────────────────────────────────────────

final authProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);

final authStateProvider = StreamProvider<User?>(
  (_) => FirebaseAuth.instance.authStateChanges(),
);

// ── Repositories ──────────────────────────────────────────────────────────────

final venueRepositoryProvider =
    Provider<VenueRepository>((_) => VenueRepository());

// ── Services ──────────────────────────────────────────────────────────────────

final recommendationServiceProvider = Provider<RecommendationService>(
    (ref) => RecommendationService(ref.read(venueRepositoryProvider)));
