import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/models/venue.dart';
import '../../../shared/providers/providers.dart';
import '../models/assistant_customization.dart';

enum KazakAssistantMood {
  idle,
  dance,
  wave,
  celebrate,
  hint,
}

class KazakAssistantSnapshot {
  const KazakAssistantSnapshot({
    required this.customization,
    required this.mood,
    required this.headline,
    required this.message,
    required this.supportingStats,
    required this.ctaLabel,
    required this.matchCount,
    required this.nearbyCount,
    required this.typeLabels,
    required this.phraseCount,
  });

  final AssistantCustomization customization;
  final KazakAssistantMood mood;
  final String headline;
  final String message;
  final List<String> supportingStats;
  final String ctaLabel;
  final int matchCount;
  final int nearbyCount;
  final List<String> typeLabels;
  final int phraseCount;
}

final kazakAssistantMoodProvider =
    StateProvider.autoDispose<KazakAssistantMood>((_) {
  return KazakAssistantMood.idle;
});

final kazakAssistantPhraseIndexProvider = StateProvider.autoDispose<int>((_) {
  return 0;
});

final kazakAssistantSavingProvider = StateProvider.autoDispose<bool>((_) {
  return false;
});

final kazakAssistantCustomizationDraftProvider =
    StateProvider.autoDispose<AssistantCustomization?>((_) {
  return null;
});

final kazakAssistantCustomizationProvider =
    Provider.autoDispose<AssistantCustomization>((_) {
  return AssistantCustomization.defaults;
});

final kazakAssistantSnapshotProvider =
    Provider.autoDispose<KazakAssistantSnapshot>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final customization = ref.watch(kazakAssistantCustomizationProvider);
  final mood = ref.watch(kazakAssistantMoodProvider);
  final phraseIndex = ref.watch(kazakAssistantPhraseIndexProvider);
  final venues = ref.watch(venueRepositoryProvider).getAll();

  final effective = _effectiveVenues(venues, profile);
  final nearbyCount =
      effective.where((venue) => venue.distance == DistanceTag.near).length;
  final typeLabels = _resolveTypeLabels(effective, profile);
  final phrases = _buildPhrases(
    userName: user?.displayName ?? user?.email?.split('@').first ?? 'брат',
    profile: profile,
    effectiveVenues: effective,
    nearbyCount: nearbyCount,
    typeLabels: typeLabels,
  );

  final safeIndex = phraseIndex % phrases.length;
  final selectedPhrase = phrases[safeIndex];

  return KazakAssistantSnapshot(
    customization: customization,
    mood: mood,
    headline: selectedPhrase.$1,
    message: selectedPhrase.$2,
    supportingStats: [
      '${effective.length} мест подходят',
      '$nearbyCount рядом',
      if (typeLabels.isNotEmpty) typeLabels.join(' · '),
    ],
    ctaLabel: _ctaLabel(mood),
    matchCount: effective.length,
    nearbyCount: nearbyCount,
    typeLabels: typeLabels,
    phraseCount: phrases.length,
  );
});

final kazakAssistantActionsProvider =
    Provider.autoDispose<KazakAssistantActions>((ref) {
  return KazakAssistantActions(ref);
});

class KazakAssistantActions {
  KazakAssistantActions(this.ref);

  final Ref ref;

  void surprise() {
    final snapshot = ref.read(kazakAssistantSnapshotProvider);
    final currentIndex = ref.read(kazakAssistantPhraseIndexProvider);
    ref.read(kazakAssistantPhraseIndexProvider.notifier).state =
        (currentIndex + 1) % math.max(snapshot.phraseCount, 1);

    final nextMood = switch ((currentIndex + 1) % 5) {
      0 => KazakAssistantMood.idle,
      1 => KazakAssistantMood.wave,
      2 => KazakAssistantMood.dance,
      3 => KazakAssistantMood.hint,
      _ => KazakAssistantMood.celebrate,
    };
    ref.read(kazakAssistantMoodProvider.notifier).state = nextMood;
  }

  void setMood(KazakAssistantMood mood) {
    ref.read(kazakAssistantMoodProvider.notifier).state = mood;
  }

  void stageCustomization(AssistantCustomization customization) {
    ref.read(kazakAssistantCustomizationDraftProvider.notifier).state =
        customization;
  }

  void resetDraft() {
    ref.read(kazakAssistantCustomizationDraftProvider.notifier).state = null;
  }

  Future<void> saveCustomization(AssistantCustomization customization) async {
    ref.read(kazakAssistantCustomizationDraftProvider.notifier).state =
        customization;
    ref.read(kazakAssistantSavingProvider.notifier).state = true;
    var saved = false;

    try {
      final user = ref.read(authProvider).currentUser;
      if (user == null) return;

      final repository = ref.read(userProfileRepositoryProvider);
      final existing = ref.read(userProfileProvider).valueOrNull;

      final profile = (existing ??
              UserProfile(
                uid: user.uid,
                name:
                    user.displayName ?? user.email?.split('@').first ?? 'Гость',
                preferredTypes: const [],
                defaultGroup: GroupTag.friends,
              ))
          .copyWith(
        name: user.displayName ?? user.email?.split('@').first ?? 'Гость',
        assistantCustomization: customization,
      );

      await repository.save(profile);
      ref.invalidate(userProfileProvider);
      ref.read(kazakAssistantMoodProvider.notifier).state =
          KazakAssistantMood.celebrate;
      saved = true;
    } finally {
      ref.read(kazakAssistantSavingProvider.notifier).state = false;
      if (!saved) {
        ref.read(kazakAssistantCustomizationDraftProvider.notifier).state = null;
      }
    }
  }
}

List<Venue> _effectiveVenues(List<Venue> venues, UserProfile? profile) {
  final preferredTypes = profile?.preferredTypes ?? const <VenueType>[];
  final group = profile?.defaultGroup;

  final matches = venues.where((venue) {
    final typeMatch =
        preferredTypes.isEmpty ? true : preferredTypes.contains(venue.type);
    final groupMatch = group == null ? true : venue.group == group;
    return typeMatch && groupMatch;
  }).toList();

  return matches.isEmpty ? venues : matches;
}

List<String> _resolveTypeLabels(List<Venue> venues, UserProfile? profile) {
  final profileTypes = profile?.preferredTypes ?? const <VenueType>[];
  if (profileTypes.isNotEmpty) {
    return profileTypes.take(3).map(_typeLabel).toList();
  }

  return venues
      .map((venue) => venue.type)
      .toSet()
      .take(3)
      .map(_typeLabel)
      .toList();
}

List<(String, String)> _buildPhrases({
  required String userName,
  required UserProfile? profile,
  required List<Venue> effectiveVenues,
  required int nearbyCount,
  required List<String> typeLabels,
}) {
  final groupLabel = profile == null
      ? 'универсальный режим'
      : _groupLabel(profile.defaultGroup);
  final formatLabel =
      typeLabels.isEmpty ? 'свободный микс по городу' : typeLabels.join(', ');

  return [
    (
      'Опа, $userName',
      'Я уже прикинул расклад: тебе лучше всего заходят $formatLabel. Не суетимся, работаем по красоте.',
    ),
    (
      'Есть тема',
      nearbyCount == 0
          ? 'Рядом пока тихо, но если чуть расширить вкус, я быстро натаскаю тебе новые варианты.'
          : 'Рядом уже лежит $nearbyCount бодрых вариантов. Можно идти в свайпы и не тратить вечер на сомнения.',
    ),
    (
      'Сценарий читается',
      'У тебя профиль про "$groupLabel". Я это вижу и под тебя уже собрано ${effectiveVenues.length} подходящих мест.',
    ),
    (
      'Казачий инсайт',
      'Сейчас я работаю без лишнего маскарада. Цель одна: чтобы ты быстрее находил нормальные места, а не листал всё подряд.',
    ),
  ];
}

String _ctaLabel(KazakAssistantMood mood) => switch (mood) {
      KazakAssistantMood.idle => 'Разбудить',
      KazakAssistantMood.wave => 'Помахать ещё',
      KazakAssistantMood.dance => 'Дать жару',
      KazakAssistantMood.celebrate => 'Отжечь снова',
      KazakAssistantMood.hint => 'Ещё инсайт',
    };

String _groupLabel(GroupTag group) => switch (group) {
      GroupTag.solo => 'соло-формат',
      GroupTag.couple => 'вечер вдвоём',
      GroupTag.friends => 'движ с друзьями',
      GroupTag.family => 'семейный выезд',
      GroupTag.largeGroup => 'большая компания',
    };

String _typeLabel(VenueType type) => switch (type) {
      VenueType.restaurant => 'рестораны',
      VenueType.cafe => 'кафе',
      VenueType.park => 'парки',
      VenueType.museum => 'музеи',
      VenueType.temple => 'храмы',
      VenueType.bar => 'бары',
      VenueType.spa => 'спа',
      VenueType.sport => 'активности',
      VenueType.attraction => 'развлечения',
      VenueType.embankment => 'прогулки',
      VenueType.mall => 'шопинг',
      VenueType.theater => 'театр',
    };
