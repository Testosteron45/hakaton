import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/venue.dart';

class VenueCard extends StatelessWidget {
  const VenueCard({super.key, required this.venue});

  final Venue venue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo
            _VenuePhoto(imageUrl: venue.photoUrl),

            // Gradient — soft, only at bottom
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.45, 1.0],
                  colors: [Colors.transparent, Colors.black],
                ),
              ),
            ),

            // Top row — category chip only
            Positioned(
              top: 20,
              left: 20,
              child: _GlassChip(
                icon: _typeIcon(venue.type),
                label: _typeLabel(venue.type),
              ),
            ),

            // Bottom info — clean & minimal
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white54,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            venue.address,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (venue.rating != null) ...[
                          _RatingTag(venue.rating!),
                          const SizedBox(width: 6),
                        ],
                        _PriceTag(venue.price),
                        const SizedBox(width: 6),
                        _DistanceTag(venue.distance),
                      ],
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
}

class _VenuePhoto extends StatelessWidget {
  const _VenuePhoto({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _placeholder();
      },
      errorBuilder: (_, __, ___) => _error(),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceDark,
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.accent,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _error() {
    return Container(
      color: AppColors.surfaceDark,
      child: const Icon(
        Icons.image_not_supported_outlined,
        size: 56,
        color: AppColors.textMutedOnDark,
      ),
    );
  }
}

// ── Chips ─────────────────────────────────────────────────────────────────────

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceTag extends StatelessWidget {
  const _PriceTag(this.price);

  final PriceTag price;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (price) {
      PriceTag.budget => ('₽', const Color(0xFF4ADE80)),
      PriceTag.mid => ('₽₽', const Color(0xFFFBBF24)),
      PriceTag.premium => ('₽₽₽', const Color(0xFFC084FC)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DistanceTag extends StatelessWidget {
  const _DistanceTag(this.distance);

  final DistanceTag distance;

  @override
  Widget build(BuildContext context) {
    final label = switch (distance) {
      DistanceTag.near => 'Рядом',
      DistanceTag.medium => '~30 мин',
      DistanceTag.far => 'Далеко',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RatingTag extends StatelessWidget {
  const _RatingTag(this.rating);

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFBBF24).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 13),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Color(0xFFFBBF24),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _typeLabel(VenueType t) => switch (t) {
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

IconData _typeIcon(VenueType t) => switch (t) {
      VenueType.restaurant => Icons.restaurant_rounded,
      VenueType.cafe => Icons.local_cafe_rounded,
      VenueType.park => Icons.park_rounded,
      VenueType.museum => Icons.museum_rounded,
      VenueType.temple => Icons.account_balance_rounded,
      VenueType.bar => Icons.local_bar_rounded,
      VenueType.spa => Icons.spa_rounded,
      VenueType.sport => Icons.sports_soccer_rounded,
      VenueType.attraction => Icons.attractions_rounded,
      VenueType.embankment => Icons.water_rounded,
      VenueType.mall => Icons.shopping_bag_rounded,
      VenueType.theater => Icons.theater_comedy_rounded,
    };
