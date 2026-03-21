import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/venue_assets.dart';
import '../../../data/models/venue.dart';
import '../../../shared/widgets/venue_map_icon_button.dart';

class ProfileFeedView extends StatelessWidget {
  const ProfileFeedView({
    super.key,
    required this.venues,
  });

  final List<Venue> venues;

  @override
  Widget build(BuildContext context) {
    if (venues.isEmpty) {
      return const _EmptyFeedState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FeedIntro(totalCount: venues.length),
        const SizedBox(height: 16),
        for (var i = 0; i < venues.length; i++) ...[
          _FeedVenueCard(
            venue: venues[i],
            rank: i + 1,
          ),
          if (i != venues.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _FeedIntro extends StatelessWidget {
  const _FeedIntro({required this.totalCount});

  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.softBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.newspaper_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Лента мест',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Новых публикаций пока маловато, поэтому здесь показываем все места из базы. Зато есть из чего выбрать, а не смотреть на пустую витрину.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaPill(
                icon: Icons.place_rounded,
                label: '$totalCount мест в ленте',
              ),
              const _MetaPill(
                icon: Icons.description_rounded,
                label: 'Адрес и описание на месте',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedVenueCard extends StatelessWidget {
  const _FeedVenueCard({
    required this.venue,
    required this.rank,
  });

  final Venue venue;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.softBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: SizedBox(
              height: 188,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _FeedVenuePhoto(venue: venue),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '#$rank в ленте',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _OverlayTag(label: _typeLabel(venue.type)),
                        _OverlayTag(label: _distanceLabel(venue.distance)),
                        _OverlayTag(label: _priceLabel(venue.price)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        venue.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (venue.mapUrl != null && venue.mapUrl!.trim().isNotEmpty) ...[
                      const SizedBox(width: 10),
                      VenueMapIconButton(venue: venue, size: 34),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        venue.address.isEmpty ? 'Адрес уточняется' : venue.address,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  venue.description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (venue.features.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final feature in venue.features.take(4))
                        _FeatureChip(label: _featureLabel(feature)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedVenuePhoto extends StatelessWidget {
  const _FeedVenuePhoto({required this.venue});

  final Venue venue;

  @override
  Widget build(BuildContext context) {
    final assetPath = kVenueAssets[venue.id];
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    if (venue.photoUrl.isNotEmpty) {
      return Image.network(
        venue.photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _placeholder();
        },
      );
    }

    return _fallback();
  }

  Widget _placeholder() => Container(
        color: AppColors.surfaceVariant,
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );

  Widget _fallback() => Container(
        color: AppColors.surfaceVariant,
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_rounded,
          color: AppColors.textSecondary,
          size: 30,
        ),
      );
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayTag extends StatelessWidget {
  const _OverlayTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.18)
            : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _EmptyFeedState extends StatelessWidget {
  const _EmptyFeedState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.softBorder,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.inbox_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Лента пока пустая',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Как только в базе появятся места, они всплывут здесь без лишнего шаманства.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}

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

String _distanceLabel(DistanceTag distance) => switch (distance) {
      DistanceTag.near => 'Рядом',
      DistanceTag.medium => '~30 мин',
      DistanceTag.far => 'Подальше',
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
