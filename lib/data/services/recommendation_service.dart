import '../models/venue.dart';
import '../models/swipe_session.dart';
import '../repositories/venue_repository.dart';

class RecommendationResult {
  const RecommendationResult({
    required this.topVenues,
    required this.explanation,
    required this.inferredPreferences,
  });

  final List<Venue> topVenues; // top 3
  final String explanation;
  final InferredPreferences inferredPreferences;
}

class InferredPreferences {
  const InferredPreferences({
    required this.preferredDistance,
    required this.preferredGroup,
    required this.preferredPrice,
    required this.preferredTypes,
    required this.preferredFeatures,
    this.preferredTags = const [],
  });

  final DistanceTag? preferredDistance;
  final GroupTag? preferredGroup;
  final PriceTag? preferredPrice;
  final List<VenueType> preferredTypes;
  final List<VenueFeature> preferredFeatures;
  final List<String> preferredTags;
}

class RecommendationService {
  RecommendationService(this._repo);

  final VenueRepository _repo;

  RecommendationResult recommend(SwipeSession session) {
    final likedVenues = <Venue>[];
    final dislikedVenues = <Venue>[];

    for (final entry in session.swipes.entries) {
      final venue = session.queue.firstWhere(
        (v) => v.id == entry.key,
        orElse: () => session.queue.first,
      );
      if (entry.value) {
        likedVenues.add(venue);
      } else {
        dislikedVenues.add(venue);
      }
    }

    final prefs = _inferPreferences(likedVenues, dislikedVenues);

    // Score all venues not shown in session
    final shownIds = session.swipes.keys.toSet();
    final candidates = _repo.getAll().where((v) => !shownIds.contains(v.id)).toList();

    final scored = candidates.map((v) {
      return _MapEntry(v, _score(v, prefs, likedVenues, dislikedVenues));
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));

    final top = scored.take(3).map((e) => e.venue).toList();

    return RecommendationResult(
      topVenues: top,
      explanation: _buildExplanation(prefs, likedVenues),
      inferredPreferences: prefs,
    );
  }

  InferredPreferences _inferPreferences(
    List<Venue> liked,
    List<Venue> disliked,
  ) {
    if (liked.isEmpty) {
      return const InferredPreferences(
        preferredDistance: null,
        preferredGroup: null,
        preferredPrice: null,
        preferredTypes: [],
        preferredFeatures: [],
      );
    }

    // Distance
    final distCount = <DistanceTag, int>{};
    for (final v in liked) {
      distCount[v.distance] = (distCount[v.distance] ?? 0) + 1;
    }
    final prefDist = _topKey(distCount, liked.length);

    // Group
    final groupCount = <GroupTag, int>{};
    for (final v in liked) {
      groupCount[v.group] = (groupCount[v.group] ?? 0) + 1;
    }
    final prefGroup = _topKey(groupCount, liked.length);

    // Price
    final priceCount = <PriceTag, int>{};
    for (final v in liked) {
      priceCount[v.price] = (priceCount[v.price] ?? 0) + 1;
    }
    final prefPrice = _topKey(priceCount, liked.length);

    // Types (multi)
    final typeCount = <VenueType, int>{};
    for (final v in liked) {
      typeCount[v.type] = (typeCount[v.type] ?? 0) + 1;
    }
    // Penalise types found in disliked
    for (final v in disliked) {
      typeCount[v.type] = (typeCount[v.type] ?? 0) - 1;
    }
    final prefTypes = typeCount.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Features (multi)
    final featCount = <VenueFeature, int>{};
    for (final v in liked) {
      for (final f in v.features) {
        featCount[f] = (featCount[f] ?? 0) + 1;
      }
    }
    for (final v in disliked) {
      for (final f in v.features) {
        featCount[f] = (featCount[f] ?? 0) - 1;
      }
    }
    final prefFeatures = featCount.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Tags (fine-grained signal from Firestore)
    final tagCount = <String, int>{};
    for (final v in liked) {
      for (final t in v.tags) {
        tagCount[t] = (tagCount[t] ?? 0) + 1;
      }
    }
    for (final v in disliked) {
      for (final t in v.tags) {
        tagCount[t] = (tagCount[t] ?? 0) - 1;
      }
    }
    final prefTags = tagCount.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return InferredPreferences(
      preferredDistance: prefDist,
      preferredGroup: prefGroup,
      preferredPrice: prefPrice,
      preferredTypes: prefTypes.map((e) => e.key).take(3).toList(),
      preferredFeatures: prefFeatures.map((e) => e.key).take(5).toList(),
      preferredTags: prefTags.map((e) => e.key).take(10).toList(),
    );
  }

  T? _topKey<T>(Map<T, int> counts, int total) {
    if (counts.isEmpty) return null;
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    // Require at least 50% agreement
    if (top.value / total >= 0.5) return top.key;
    return null;
  }

  double _score(
    Venue v,
    InferredPreferences prefs,
    List<Venue> liked,
    List<Venue> disliked,
  ) {
    double score = 0;

    // Type match (strongest signal)
    if (prefs.preferredTypes.isNotEmpty) {
      final idx = prefs.preferredTypes.indexOf(v.type);
      if (idx == 0) score += 4;
      else if (idx == 1) score += 2;
      else if (idx == 2) score += 1;
    }

    // Disliked type – heavy penalty
    final dislikedTypes = disliked.map((d) => d.type).toSet();
    if (dislikedTypes.contains(v.type)) score -= 3;

    // Distance
    if (prefs.preferredDistance != null) {
      if (v.distance == prefs.preferredDistance) score += 2;
      else if ((v.distance.index - prefs.preferredDistance!.index).abs() == 1) {
        score += 0.5;
      }
    }

    // Group
    if (prefs.preferredGroup != null) {
      if (v.group == prefs.preferredGroup) score += 2;
    }

    // Price
    if (prefs.preferredPrice != null) {
      if (v.price == prefs.preferredPrice) score += 1;
    }

    // Features
    for (final f in prefs.preferredFeatures) {
      if (v.features.contains(f)) score += 1;
    }

    // Tags (fine-grained, capped at +3 to not dominate type signal)
    if (prefs.preferredTags.isNotEmpty) {
      final tagMatches =
          v.tags.where((t) => prefs.preferredTags.contains(t)).length;
      score += (tagMatches * 0.5).clamp(0.0, 3.0);
    }

    return score;
  }

  String _buildExplanation(InferredPreferences prefs, List<Venue> liked) {
    if (liked.isEmpty) return 'Мы подобрали что-то интересное для вас!';

    final parts = <String>[];

    if (prefs.preferredDistance != null) {
      switch (prefs.preferredDistance!) {
        case DistanceTag.near:
          parts.add('места поблизости');
          break;
        case DistanceTag.medium:
          parts.add('места не слишком далеко');
          break;
        case DistanceTag.far:
          parts.add('поездки за город');
          break;
      }
    }

    if (prefs.preferredGroup != null) {
      switch (prefs.preferredGroup!) {
        case GroupTag.solo:
          parts.add('отдых в одиночку');
          break;
        case GroupTag.couple:
          parts.add('отдых вдвоём');
          break;
        case GroupTag.friends:
          parts.add('весёлая компания');
          break;
        case GroupTag.family:
          parts.add('семейный отдых');
          break;
        case GroupTag.largeGroup:
          parts.add('большая компания');
          break;
      }
    }

    if (prefs.preferredTypes.isNotEmpty) {
      switch (prefs.preferredTypes.first) {
        case VenueType.restaurant:
        case VenueType.cafe:
          parts.add('вкусная еда');
          break;
        case VenueType.park:
          parts.add('прогулки на природе');
          break;
        case VenueType.museum:
          parts.add('культурный досуг');
          break;
        case VenueType.temple:
          parts.add('духовные места');
          break;
        case VenueType.sport:
          parts.add('активный отдых');
          break;
        case VenueType.spa:
          parts.add('расслабление и уход');
          break;
        case VenueType.bar:
          parts.add('вечерний досуг');
          break;
        case VenueType.theater:
          parts.add('театр и культура');
          break;
        default:
          break;
      }
    }

    if (parts.isEmpty) return 'Основываясь на ваших свайпах, мы подобрали лучшее!';

    return 'Вам понравились: ${parts.join(', ')}. Вот наши лучшие рекомендации!';
  }
}

class _MapEntry {
  const _MapEntry(this.venue, this.score);
  final Venue venue;
  final double score;
}
