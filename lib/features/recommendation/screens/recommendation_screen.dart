import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/venue.dart';
import '../../../data/services/recommendation_service.dart';
import '../../swipe_session/providers/swipe_session_provider.dart';

class RecommendationScreen extends ConsumerWidget {
  const RecommendationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(recommendationProvider);

    if (result == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Нет данных', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(swipeSessionProvider.notifier).reset();
                  context.go('/modes');
                },
                child: const Text('На главную'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero header with first recommendation
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                ref.read(swipeSessionProvider.notifier).reset();
                context.go('/modes');
              },
            ),
            title: const Text('Ваш результат',
                style: TextStyle(color: Colors.white)),
            flexibleSpace: FlexibleSpaceBar(
              background: result.topVenues.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: result.topVenues.first.photoUrl,
                          fit: BoxFit.cover,
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black87],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('⭐ Лучший выбор',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                result.topVenues.first.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          ),

          // Explanation
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Text('🤖', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result.explanation,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top venues list
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'Топ ${result.topVenues.length} рекомендации',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final venue = result.topVenues[index];
                return _VenueResultCard(
                  venue: venue,
                  rank: index + 1,
                );
              },
              childCount: result.topVenues.length,
            ),
          ),

          // Preferences summary
          if (result.inferredPreferences.preferredFeatures.isNotEmpty)
            SliverToBoxAdapter(
              child: _PreferencesSummary(prefs: result.inferredPreferences),
            ),

          // Again button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(swipeSessionProvider.notifier).reset();
                  context.go('/modes');
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Новая сессия'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VenueResultCard extends StatelessWidget {
  const _VenueResultCard({required this.venue, required this.rank});

  final Venue venue;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final medals = ['🥇', '🥈', '🥉'];
    final medal = rank <= 3 ? medals[rank - 1] : '$rank';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Photo
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16)),
            child: SizedBox(
              width: 100,
              height: 100,
              child: CachedNetworkImage(
                imageUrl: venue.photoUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(medal, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          venue.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    venue.description,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _smallChip(_distLabel(venue.distance),
                          Colors.grey.shade200, AppColors.textSecondary),
                      const SizedBox(width: 4),
                      _smallChip(
                          _priceLabel(venue.price),
                          AppColors.primary.withOpacity(0.1),
                          AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _distLabel(DistanceTag d) => switch (d) {
        DistanceTag.near => '📍 Рядом',
        DistanceTag.medium => '🚗 Недалеко',
        DistanceTag.far => '✈️ Далеко',
      };

  String _priceLabel(PriceTag p) => switch (p) {
        PriceTag.budget => '💰 Бесплатно/дёшево',
        PriceTag.mid => '💳 Средний чек',
        PriceTag.premium => '💎 Премиум',
      };

  Widget _smallChip(String label, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 10, color: fg)),
      );
}

class _PreferencesSummary extends StatelessWidget {
  const _PreferencesSummary({required this.prefs});

  final InferredPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final features = prefs.preferredFeatures;
    if (features.isEmpty) return const SizedBox.shrink();

    final labels = {
      VenueFeature.kids: '👶 С детьми',
      VenueFeature.christian: '✝️ Христианин',
      VenueFeature.sport: '🏃 Спорт',
      VenueFeature.romantic: '❤️ Романтика',
      VenueFeature.outdoor: '🌿 На улице',
      VenueFeature.alcohol: '🍺 Алкоголь',
      VenueFeature.vegetarian: '🥗 Вегетарианец',
      VenueFeature.quiet: '🤫 Тишина',
      VenueFeature.lively: '🎉 Движуха',
      VenueFeature.cultural: '🎨 Культура',
      VenueFeature.historical: '🏰 История',
      VenueFeature.nature: '🌲 Природа',
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ваш профиль',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: features
                .where((f) => labels.containsKey(f))
                .map((f) => Chip(
                      label: Text(labels[f]!,
                          style: const TextStyle(fontSize: 12)),
                      backgroundColor:
                          AppColors.primary.withOpacity(0.1),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
