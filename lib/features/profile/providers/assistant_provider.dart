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
              'Нейро-режим',
              'Секунду, собираю ответ под твой текущий вкус и формат мест...',
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
      if (aiReply != null || aiLoading) 'ответ через Groq',
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
  });

  final List<AssistantChatMessage> messages;
  final bool isSending;

  AssistantChatState copyWith({
    List<AssistantChatMessage>? messages,
    bool? isSending,
  }) {
    return AssistantChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
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
    final profile = ref.read(userProfileProvider).valueOrNull;
    final venues = _effectiveVenues(
      ref.read(venueRepositoryProvider).getAll(),
      profile,
    );

    state = state.copyWith(
      messages: [
        AssistantChatMessage(
          id: _messageId(),
          role: AssistantChatRole.bot,
          text:
              'Привет. Я помогу собрать маршрут по Краснодару. Скажи, что тебе хочется: романтика, тихая прогулка, кафе, активный день или что-то семейное?',
          recommendations: venues.take(3).toList(),
        ),
      ],
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
      text: 'Секунду, подбираю маршрут и места...',
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
      final venues = _effectiveVenues(
        ref.read(venueRepositoryProvider).getAll(),
        profile,
      );
      final recommended = _recommendVenuesForQuery(
        venues: venues,
        query: text,
        profile: profile,
      );

      String botText;
      if (!configured) {
        botText =
            'Нейро не настроен, но я уже вижу подходящие варианты ниже. Напиши, например: "хочу романтичный вечер" или "маршрут на полдня".';
      } else {
        final prompt = _buildAssistantChatPrompt(
          query: text,
          profile: profile,
          recommendations: recommended,
        );
        botText = await groq.generateText(
          systemPrompt:
              'Ты дружелюбный городской travel-ассистент. Отвечай на русском, коротко, живо, без markdown и без списков. Если данных мало, задай один уточняющий вопрос.',
          userPrompt: prompt,
          temperature: 0.8,
          maxTokens: 180,
        );
      }

      final cleaned = botText.replaceAll(RegExp(r'\s+'), ' ').trim();
      final response = AssistantChatMessage(
        id: _messageId(),
        role: AssistantChatRole.bot,
        text: cleaned,
        recommendations: recommended,
      );

      final messages = [...state.messages]..removeWhere((m) => m.isLoading);
      state = state.copyWith(
        isSending: false,
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
                'Не удалось достучаться до нейросети. Но я всё равно могу показывать карточки мест. Попробуй уточнить запрос ещё раз.',
          ),
        ],
      );
    }
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
          'Нейро не настроен',
          'Передай ключ запуска: --dart-define=GROQ_API_KEY=... и я буду отвечать по-настоящему через Groq.',
        );
        return;
      }

      final prompt =
          'Пользователь выбирает места в Краснодаре.\n'
          'Сформируй короткий дружелюбный совет на русском языке (1-2 предложения, до 220 символов).\n'
          'Контекст: подходит мест ${snapshot.matchCount}, рядом ${snapshot.nearbyCount}, форматы: ${snapshot.typeLabels.join(', ')}.';

      final content = await groq.generateText(
        systemPrompt:
            'Ты ассистент городских рекомендаций. Отвечай понятно, без markdown и без списка.',
        userPrompt: prompt,
        temperature: 0.8,
        maxTokens: 120,
      );

      final cleaned = content.replaceAll(RegExp(r'\s+'), ' ').trim();
      ref.read(kazakAssistantAiReplyProvider.notifier).state = (
        'Нейро-совет',
        cleaned.length > 260 ? '${cleaned.substring(0, 257)}...' : cleaned,
      );
      ref.read(kazakAssistantMoodProvider.notifier).state =
          KazakAssistantMood.wave;
    } catch (e) {
      final details = e.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
      final shortDetails =
          details.length > 170 ? '${details.substring(0, 167)}...' : details;
      ref.read(kazakAssistantAiReplyProvider.notifier).state = (
        'Не вышло с нейро',
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
      venue.address,
      venue.category,
      ...venue.tags,
      _typeLabel(venue.type),
      _groupLabel(venue.group),
    ].join(' ').toLowerCase();

    for (final token in tokens) {
      if (venue.name.toLowerCase().contains(token)) score += 6;
      if (haystack.contains(token)) score += 3;
    }

    if (profile?.preferredTypes.contains(venue.type) ?? false) score += 3;
    if (profile?.defaultGroup == venue.group) score += 2;
    if (venue.distance == DistanceTag.near) score += 1;

    return score;
  }

  final ranked = [...venues]
    ..sort((a, b) {
      final diff = scoreVenue(b) - scoreVenue(a);
      if (diff != 0) return diff;
      return a.name.compareTo(b.name);
    });

  return ranked.take(3).toList();
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
      'Предложи короткий ответ, при необходимости задай один уточняющий вопрос и мягко подведи к маршруту. '
      'Вот места, которые можно рекомендовать: $places';
}
