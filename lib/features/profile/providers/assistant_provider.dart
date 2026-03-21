import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/models/venue.dart';
import '../../../shared/providers/providers.dart';
import '../models/assistant_customization.dart';

const _assistantName = 'Понаехчик';

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

final kazakAssistantAiLoadingProvider = StateProvider.autoDispose<bool>((_) {
  return false;
});

final kazakAssistantAiReplyProvider =
    StateProvider.autoDispose<(String, String)?>((
  _,
) {
  return null;
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
  final aiReply = ref.watch(kazakAssistantAiReplyProvider);
  final aiLoading = ref.watch(kazakAssistantAiLoadingProvider);

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
  final resolvedPhrase = aiReply ??
      (aiLoading
          ? (
              _assistantName,
              'Ща без суеты соберу нормальный ответ под твой запрос и текущий вкус.',
            )
          : selectedPhrase);

  return KazakAssistantSnapshot(
    customization: customization,
    mood: mood,
    headline: resolvedPhrase.$1,
    message: resolvedPhrase.$2,
    supportingStats: [
      '${effective.length} мест подходят',
      '$nearbyCount рядом',
      if (typeLabels.isNotEmpty) typeLabels.join(' · '),
      if (aiReply != null || aiLoading) 'ответ от $_assistantName',
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

enum AssistantChatRole { user, bot }

class AssistantChatMessage {
  const AssistantChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.recommendations = const [],
    this.isLoading = false,
  });

  final String id;
  final AssistantChatRole role;
  final String text;
  final List<Venue> recommendations;
  final bool isLoading;
}

class AssistantChatState {
  const AssistantChatState({
    this.messages = const [],
    this.isSending = false,
    this.hasClarifiedIntent = false,
  });

  final List<AssistantChatMessage> messages;
  final bool isSending;
  final bool hasClarifiedIntent;

  AssistantChatState copyWith({
    List<AssistantChatMessage>? messages,
    bool? isSending,
    bool? hasClarifiedIntent,
  }) {
    return AssistantChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      hasClarifiedIntent: hasClarifiedIntent ?? this.hasClarifiedIntent,
    );
  }
}

final assistantChatProvider =
    StateNotifierProvider.autoDispose<AssistantChatController, AssistantChatState>(
  (ref) => AssistantChatController(ref),
);

class AssistantChatController extends StateNotifier<AssistantChatState> {
  AssistantChatController(this.ref) : super(const AssistantChatState()) {
    _seedWelcome();
  }

  final Ref ref;

  void _seedWelcome() {
    state = state.copyWith(
      messages: [
        AssistantChatMessage(
          id: _messageId(),
          role: AssistantChatRole.bot,
          text:
              'Я $_assistantName. Соберём тебе внятный маршрут без городской чепухи. Что хочешь сегодня: спокойно погулять, вкусно поесть, романтику, движ или формат с детьми?',
        ),
      ],
      hasClarifiedIntent: false,
    );
  }

  Future<void> sendMessage(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || state.isSending) return;

    final userMessage = AssistantChatMessage(
      id: _messageId(),
      role: AssistantChatRole.user,
      text: text,
    );
    final loadingMessage = AssistantChatMessage(
      id: _messageId(),
      role: AssistantChatRole.bot,
      text: 'Секунду, фильтрую лишний шум и собираю маршрут...',
      isLoading: true,
    );

    state = state.copyWith(
      isSending: true,
      messages: [...state.messages, userMessage, loadingMessage],
    );

    try {
      final groq = ref.read(groqServiceProvider);
      final configured = ref.read(groqConfiguredProvider);
      final profile = ref.read(userProfileProvider).valueOrNull;
      final venues = ref.read(venueRepositoryProvider).getAll();
      final recommended = _recommendVenuesForQuery(
        venues: venues,
        query: text,
        profile: profile,
      );

      String botText;
      if (!configured) {
        botText =
            'Маршрут карточками ниже уже собран. Докинь район, бюджет или темп вечера, и я быстро перестрою всё без гадания на кофейной гуще.';
      } else {
        final prompt = _buildAssistantChatPrompt(
          query: text,
          profile: profile,
          recommendations: recommended,
        );
        botText = await groq.generateText(
          systemPrompt:
              'Ты $_assistantName, городской ассистент по Краснодару. '
              'Отвечай только на русском. '
              'Тон: полезный, уверенный, слегка дерзкий, с лёгким юмором, но без хамства и клоунады. '
              'Опирайся только на факты из запроса, профиля и переданных мест. '
              'Ничего не выдумывай: не придумывай локации, цены, расстояния, режим работы, события или особенности мест, которых нет в данных. '
              'Если данных мало или выбор слабый, честно скажи это и задай ровно один уточняющий вопрос. '
              'Если места переданы, кратко объясни, почему подходят, и упомяни 1-3 названия. '
              'Формат ответа: 2-4 короткие фразы, без markdown, без списков, без эмодзи.',
          userPrompt: prompt,
          temperature: 0.45,
          maxTokens: 180,
        );
      }

      final cleaned = _cleanAssistantText(botText);
      final response = AssistantChatMessage(
        id: _messageId(),
        role: AssistantChatRole.bot,
        text: cleaned,
        recommendations: recommended,
      );

      final messages = [...state.messages]..removeWhere((m) => m.isLoading);
      state = state.copyWith(
        isSending: false,
        hasClarifiedIntent: true,
        messages: [...messages, response],
      );
    } catch (e) {
      final messages = [...state.messages]..removeWhere((m) => m.isLoading);
      state = state.copyWith(
        isSending: false,
        messages: [
          ...messages,
          AssistantChatMessage(
            id: _messageId(),
            role: AssistantChatRole.bot,
            text:
                'До $_assistantName сейчас не достучались. Но карточки мест живы, так что уточни запрос ещё раз и попробуем без магии.',
          ),
        ],
      );
    }
  }

  void appendBotMessage(String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;
    state = state.copyWith(
      messages: [
        ...state.messages,
        AssistantChatMessage(
          id: _messageId(),
          role: AssistantChatRole.bot,
          text: cleaned,
        ),
      ],
    );
  }
}

class KazakAssistantActions {
  KazakAssistantActions(this.ref);

  final Ref ref;

  void surprise() {
    ref.read(kazakAssistantAiReplyProvider.notifier).state = null;
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

  Future<void> generateAiReply() async {
    if (ref.read(kazakAssistantAiLoadingProvider)) return;

    ref.read(kazakAssistantAiLoadingProvider.notifier).state = true;
    ref.read(kazakAssistantMoodProvider.notifier).state = KazakAssistantMood.hint;

    try {
      final snapshot = ref.read(kazakAssistantSnapshotProvider);
      final groq = ref.read(groqServiceProvider);
      final configured = ref.read(groqConfiguredProvider);

      if (!configured) {
        ref.read(kazakAssistantAiReplyProvider.notifier).state = (
          _assistantName,
          'Я бы ответил как надо, но ключ Groq не настроен. Передай --dart-define=GROQ_API_KEY=..., и погнали по-взрослому.',
        );
        return;
      }

      final prompt =
          'Пользователь выбирает места в Краснодаре.\n'
          'Сформируй короткий полезный совет на русском языке (1-2 предложения, до 220 символов).\n'
          'Контекст: подходит мест ${snapshot.matchCount}, рядом ${snapshot.nearbyCount}, форматы: ${snapshot.typeLabels.join(', ')}.';

      final content = await groq.generateText(
        systemPrompt:
            'Ты $_assistantName, ассистент городских рекомендаций по Краснодару. '
            'Отвечай полезно, ясно, слегка дерзко и с лёгким юмором. '
            'Ничего не выдумывай сверх переданного контекста. '
            'Формат: 1-2 предложения, без markdown, без списков, без эмодзи.',
        userPrompt: prompt,
        temperature: 0.45,
        maxTokens: 120,
      );

      final cleaned = _cleanAssistantText(content);
      ref.read(kazakAssistantAiReplyProvider.notifier).state = (
        _assistantName,
        cleaned.length > 260 ? '${cleaned.substring(0, 257)}...' : cleaned,
      );
      ref.read(kazakAssistantMoodProvider.notifier).state =
          KazakAssistantMood.wave;
    } catch (e) {
      final details = e.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
      final shortDetails =
          details.length > 170 ? '${details.substring(0, 167)}...' : details;
      ref.read(kazakAssistantAiReplyProvider.notifier).state = (
        '$_assistantName не в духе',
        'Ошибка запроса к Groq: $shortDetails',
      );
    } finally {
      ref.read(kazakAssistantAiLoadingProvider.notifier).state = false;
    }
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

String _messageId() => DateTime.now().microsecondsSinceEpoch.toString();

List<Venue> _recommendVenuesForQuery({
  required List<Venue> venues,
  required String query,
  required UserProfile? profile,
}) {
  if (venues.isEmpty) return const [];
  final queryLower = query.toLowerCase();
  final asksForKrasnaya = RegExp(r'(^|\s)(ул\.?\s*)?красн').hasMatch(queryLower);

  final tokens = query
      .toLowerCase()
      .split(RegExp(r'[^a-zA-Zа-яА-Я0-9]+'))
      .where((token) => token.trim().length > 2)
      .toList();

  int scoreVenue(Venue venue) {
    var score = 0;
    final haystack = [
      venue.name,
      venue.description,
      venue.category,
      ...venue.tags,
      _typeLabel(venue.type),
      _groupLabel(venue.group),
    ].join(' ').toLowerCase();

    for (final token in tokens) {
      if (venue.name.toLowerCase().contains(token)) score += 6;
      if (haystack.contains(token)) score += 3;
    }

    if (tokens.any((t) => t.contains('мор') || t.contains('вод') || t.contains('пляж'))) {
      if (venue.type == VenueType.embankment) score += 8;
      if (venue.features.contains(VenueFeature.outdoor) ||
          venue.features.contains(VenueFeature.nature)) {
        score += 4;
      }
    }

    if (profile?.preferredTypes.contains(venue.type) ?? false) score += 3;
    if (profile?.defaultGroup == venue.group) score += 2;
    if (venue.distance == DistanceTag.near) score += 2;
    if (venue.distance == DistanceTag.medium) score += 1;
    if (!asksForKrasnaya && _isKrasnayaStreet(venue.address)) {
      score -= 3;
    }

    return score;
  }

  final ranked = [...venues]
    ..sort((a, b) {
      final diff = scoreVenue(b) - scoreVenue(a);
      if (diff != 0) return diff;
      return a.name.compareTo(b.name);
    });

  return _buildRouteFromRanked(
    ranked,
    allowKrasnayaMultiple: asksForKrasnaya,
  );
}

String _buildAssistantChatPrompt({
  required String query,
  required UserProfile? profile,
  required List<Venue> recommendations,
}) {
  final groupLabel = profile == null
      ? 'свободный формат'
      : _groupLabel(profile.defaultGroup);
  final preferredTypes = profile?.preferredTypes ?? const <VenueType>[];
  final preferred = preferredTypes.map(_typeLabel).join(', ');
  final places = recommendations
      .map(
        (venue) =>
            '${venue.name} — ${venue.description} Адрес: ${venue.address}. Тип: ${_typeLabel(venue.type)}.',
      )
      .join(' ');

  return 'Запрос пользователя: "$query". '
      'Профиль: $groupLabel. '
      'Предпочтения: ${preferred.isEmpty ? 'не заданы' : preferred}. '
      'Ниже уже есть маршрут карточками. Дай короткий полезный комментарий к нему на русском. '
      'Не выдумывай факты и не советуй места, которых нет в списке. '
      'Не зацикливайся на одной улице и не делай акцент на улице Красной, если пользователь сам этого не просил. '
      'Если мест мало или подборка слабая, честно скажи это и задай один уточняющий вопрос. '
      'Вот места, которые можно рекомендовать: ${places.isEmpty ? 'подборки пока нет' : places}';
}

String _cleanAssistantText(String text) {
  final withoutMarkdown = text
      .replaceAll(RegExp(r'[*_`#>]+'), ' ')
      .replaceAll(RegExp(r'^\s*[-•]+\s*', multiLine: true), '');
  return withoutMarkdown.replaceAll(RegExp(r'\s+'), ' ').trim();
}

List<Venue> _buildRouteFromRanked(
  List<Venue> ranked, {
  required bool allowKrasnayaMultiple,
}) {
  if (ranked.isEmpty) return const [];

  final selected = <Venue>[];
  final usedStreets = <String>{};
  final usedTypes = <VenueType>{};

  void pickFrom(List<Venue> source) {
    for (final venue in source) {
      if (selected.length == 3) break;
      if (selected.any((picked) => picked.id == venue.id)) continue;

      final street = _streetKey(venue.address);
      if (street.isNotEmpty && usedStreets.contains(street)) continue;
      if (usedTypes.contains(venue.type) && selected.length < 2) continue;

      selected.add(venue);
      if (street.isNotEmpty) usedStreets.add(street);
      usedTypes.add(venue.type);
    }
  }

  if (allowKrasnayaMultiple) {
    pickFrom(ranked);
  } else {
    final nonKrasnaya = ranked.where((v) => !_isKrasnayaStreet(v.address)).toList();
    final krasnaya = ranked.where((v) => _isKrasnayaStreet(v.address)).toList();

    // First, build a route from non-Krasnaya places.
    pickFrom(nonKrasnaya);
    if (selected.length < 3) {
      // Fallback: allow only one Krasnaya place if not enough options.
      pickFrom(krasnaya.take(1).toList());
    }
  }

  if (selected.length < 3) {
    for (final venue in ranked) {
      if (selected.any((picked) => picked.id == venue.id)) continue;
      if (!allowKrasnayaMultiple &&
          _isKrasnayaStreet(venue.address) &&
          selected.any((v) => _isKrasnayaStreet(v.address))) {
        continue;
      }
      selected.add(venue);
      if (selected.length == 3) break;
    }
  }

  selected.sort((a, b) {
    final aOrder = _distanceOrder(a.distance);
    final bOrder = _distanceOrder(b.distance);
    if (aOrder != bOrder) return aOrder.compareTo(bOrder);
    return a.name.compareTo(b.name);
  });

  return selected;
}

int _distanceOrder(DistanceTag distance) => switch (distance) {
      DistanceTag.near => 0,
      DistanceTag.medium => 1,
      DistanceTag.far => 2,
    };

String _streetKey(String address) {
  final lower = address.toLowerCase().trim();
  if (lower.isEmpty) return '';
  final parts = lower.split(',');
  return parts.first.trim();
}

bool _isKrasnayaStreet(String address) {
  final lower = address.toLowerCase().trim();
  return RegExp(r'(^|\b)(ул\.?\s*)?красная(\b|\s|/)').hasMatch(lower);
}
