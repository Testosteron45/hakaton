import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/venue_assets.dart';
import '../../../data/models/venue.dart';
import '../providers/assistant_provider.dart';

class AssistantChatScreen extends ConsumerStatefulWidget {
  const AssistantChatScreen({super.key});

  @override
  ConsumerState<AssistantChatScreen> createState() => _AssistantChatScreenState();
}

class _AssistantChatScreenState extends ConsumerState<AssistantChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final SpeechToText _speech = SpeechToText();
  bool _speechReady = false;
  bool _isListening = false;

  @override
  void dispose() {
    _speech.stop();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(assistantChatProvider, (_, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      });
    });

    final state = ref.watch(assistantChatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  _TopBtn(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Поболтать с ботом',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Он задаёт вопросы и предлагает места карточками',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: state.messages.length,
                itemBuilder: (context, index) {
                  final message = state.messages[index];
                  return _ChatMessageBubble(message: message, isDark: isDark);
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          hintText: 'Например: хочу романтичный маршрут на вечер',
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : AppColors.softBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : AppColors.softBorder,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.tonal(
                      onPressed: state.isSending ? null : _toggleVoiceInput,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(54, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: state.isSending ? null : _send,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(54, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: state.isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text;
    _controller.clear();
    await ref.read(assistantChatProvider.notifier).sendMessage(text);
  }

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    if (!_speechReady) {
      _speechReady = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: (_) => setState(() => _isListening = false),
      );
    }

    if (!_speechReady || !mounted) {
      ref.read(assistantChatProvider.notifier).appendBotMessage(
        'Не удалось включить микрофон. Проверь разрешение в браузере.',
      );
      return;
    }

    ref.read(assistantChatProvider.notifier).appendBotMessage('Слушаю...');
    setState(() => _isListening = true);
    await _speech.listen(
      localeId: 'ru_RU',
      listenMode: ListenMode.confirmation,
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
    );
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    if (status == 'notListening' || status == 'done') {
      setState(() => _isListening = false);
    }
  }

  Future<void> _onSpeechResult(SpeechRecognitionResult result) async {
    if (!mounted) return;
    _controller.value = TextEditingValue(
      text: result.recognizedWords,
      selection: TextSelection.collapsed(offset: result.recognizedWords.length),
    );

    if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
      await _send();
      setState(() => _isListening = false);
    }
  }
}

class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({
    required this.message,
    required this.isDark,
  });

  final AssistantChatMessage message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == AssistantChatRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser
                      ? AppColors.primary
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: isUser
                      ? null
                      : Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppColors.softBorder,
                        ),
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: isUser ? Colors.white : null,
                  ),
                ),
              ),
              if (message.recommendations.isNotEmpty) ...[
                const SizedBox(height: 10),
                for (final venue in message.recommendations)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _VenueSuggestionCard(venue: venue),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VenueSuggestionCard extends StatelessWidget {
  const _VenueSuggestionCard({required this.venue});

  final Venue venue;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _showDetails(context),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.softBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(22)),
                child: SizedBox(
                  width: 104,
                  height: 104,
                  child: _VenueSuggestionPhoto(venue: venue),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venue.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        venue.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _MiniTag(label: _typeLabel(venue.type)),
                          _MiniTag(label: _distanceLabel(venue.distance)),
                          _MiniTag(label: _priceLabel(venue.price)),
                          for (final feature in venue.features.take(2))
                            _MiniTag(label: _featureLabel(feature)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Нажми для полного описания',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    venue.name,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    venue.address,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 170,
                      width: double.infinity,
                      child: _VenueSuggestionPhoto(venue: venue),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    venue.description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _MiniTag(label: _typeLabel(venue.type)),
                      _MiniTag(label: _distanceLabel(venue.distance)),
                      _MiniTag(label: _priceLabel(venue.price)),
                      for (final feature in venue.features)
                        _MiniTag(label: _featureLabel(feature)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isDark ? 'Листай вверх, чтобы закрыть' : 'Листай вниз, чтобы закрыть',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VenueSuggestionPhoto extends StatelessWidget {
  const _VenueSuggestionPhoto({required this.venue});

  final Venue venue;

  @override
  Widget build(BuildContext context) {
    final assetPath = kVenueAssets[venue.id];
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _error(),
      );
    }

    return Image.network(
      venue.photoUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _error(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _error();
      },
    );
  }

  Widget _error() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Icon(Icons.image_rounded, color: AppColors.textSecondary),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textOnDark : AppColors.primary,
        ),
      ),
    );
  }
}

class _TopBtn extends StatelessWidget {
  const _TopBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.softBorder,
          ),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface,
          size: 20,
        ),
      ),
    );
  }
}

String _distanceLabel(DistanceTag distance) => switch (distance) {
      DistanceTag.near => 'Рядом',
      DistanceTag.medium => '~30 мин',
      DistanceTag.far => 'Далеко',
    };

String _typeLabel(VenueType type) => switch (type) {
      VenueType.restaurant => 'Ресторан',
      VenueType.cafe => 'Кафе',
      VenueType.park => 'Парк',
      VenueType.museum => 'Музей',
      VenueType.temple => 'Храм',
      VenueType.bar => 'Бар',
      VenueType.spa => 'Спа',
      VenueType.sport => 'Спорт',
      VenueType.attraction => 'Развлечения',
      VenueType.embankment => 'Прогулка',
      VenueType.mall => 'ТЦ',
      VenueType.theater => 'Театр',
    };

String _priceLabel(PriceTag price) => switch (price) {
      PriceTag.budget => 'Бюджетно',
      PriceTag.mid => 'Средний чек',
      PriceTag.premium => 'Премиум',
    };

String _featureLabel(VenueFeature feature) => switch (feature) {
      VenueFeature.kids => 'Для детей',
      VenueFeature.christian => 'Спокойно',
      VenueFeature.sport => 'Активно',
      VenueFeature.romantic => 'Романтика',
      VenueFeature.outdoor => 'На воздухе',
      VenueFeature.alcohol => 'Вечерний вайб',
      VenueFeature.vegetarian => 'Есть veggie',
      VenueFeature.quiet => 'Тихое место',
      VenueFeature.lively => 'Живо',
      VenueFeature.cultural => 'Культура',
      VenueFeature.historical => 'Исторично',
      VenueFeature.nature => 'Природа',
    };
