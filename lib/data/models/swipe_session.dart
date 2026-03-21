import 'venue.dart';

enum SessionMode {
  normal,
  bigFamily,
  christian,
  romantic,
  budget,
  active,
  foodie,
}

extension SessionModeLabel on SessionMode {
  String get label {
    switch (this) {
      case SessionMode.normal:
        return 'Обычная сессия';
      case SessionMode.bigFamily:
        return 'Для большой семьи';
      case SessionMode.christian:
        return 'Для христиан';
      case SessionMode.romantic:
        return 'Для влюблённых';
      case SessionMode.budget:
        return 'Бюджетно';
      case SessionMode.active:
        return 'Активный отдых';
      case SessionMode.foodie:
        return 'Для гурманов';
    }
  }

  String get emoji {
    switch (this) {
      case SessionMode.normal:
        return '🗺️';
      case SessionMode.bigFamily:
        return '👨‍👩‍👧‍👦';
      case SessionMode.christian:
        return '✝️';
      case SessionMode.romantic:
        return '❤️';
      case SessionMode.budget:
        return '💰';
      case SessionMode.active:
        return '🏃';
      case SessionMode.foodie:
        return '🍽️';
    }
  }

  String get description {
    switch (this) {
      case SessionMode.normal:
        return 'Подберём место под ваши предпочтения';
      case SessionMode.bigFamily:
        return 'Места для большой компании с детьми';
      case SessionMode.christian:
        return 'Храмы, монастыри и святые места';
      case SessionMode.romantic:
        return 'Для романтического свидания';
      case SessionMode.budget:
        return 'Бесплатно или недорого';
      case SessionMode.active:
        return 'Спорт, природа, активный отдых';
      case SessionMode.foodie:
        return 'Лучшие рестораны и кафе';
    }
  }

  /// Pre-filter venues for this mode
  List<VenueFeature>? get requiredFeatures {
    switch (this) {
      case SessionMode.bigFamily:
        return [VenueFeature.kids];
      case SessionMode.christian:
        return [VenueFeature.christian];
      case SessionMode.romantic:
        return [VenueFeature.romantic];
      case SessionMode.active:
        return [VenueFeature.sport, VenueFeature.outdoor];
      default:
        return null;
    }
  }

  PriceTag? get requiredPrice {
    if (this == SessionMode.budget) return PriceTag.budget;
    return null;
  }

  VenueType? get requiredType {
    if (this == SessionMode.foodie) return VenueType.restaurant;
    return null;
  }

  /// Filter by string category (from Firestore). Takes priority over requiredType for foodie.
  List<String>? get requiredCategories {
    switch (this) {
      case SessionMode.christian:
        return ['собор'];
      case SessionMode.foodie:
        return ['ресторан', 'кафе'];
      default:
        return null;
    }
  }
}

class SwipeSession {
  const SwipeSession({
    required this.mode,
    required this.queue,
    required this.swipes,
    required this.currentIndex,
  });

  final SessionMode mode;
  final List<Venue> queue;
  final Map<String, bool> swipes; // venueId → true=like, false=dislike
  final int currentIndex;

  bool get isFinished => currentIndex >= queue.length;
  int get totalCards => queue.length;
  int get remaining => queue.length - currentIndex;

  SwipeSession copyWith({
    Map<String, bool>? swipes,
    int? currentIndex,
  }) =>
      SwipeSession(
        mode: mode,
        queue: queue,
        swipes: swipes ?? this.swipes,
        currentIndex: currentIndex ?? this.currentIndex,
      );
}
