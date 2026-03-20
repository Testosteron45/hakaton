import 'package:cached_network_image/cached_network_image.dart';
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo
            CachedNetworkImage(
              imageUrl: venue.photoUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: Colors.grey.shade300,
                child: const Icon(Icons.image_not_supported,
                    size: 60, color: Colors.grey),
              ),
            ),

            // Gradient overlay
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.4, 1.0],
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),

            // Top chips
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  _TypeChip(venue.type),
                  const SizedBox(width: 8),
                  _DistanceChip(venue.distance),
                  const Spacer(),
                  _PriceChip(venue.price),
                ],
              ),
            ),

            // Bottom info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      venue.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.white60, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            venue.address,
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _GroupChip(venue.group),
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

// ── Small chips ───────────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  const _TypeChip(this.type);
  final VenueType type;

  @override
  Widget build(BuildContext context) {
    return _chip(_typeLabel(type), _typeColor(type));
  }

  String _typeLabel(VenueType t) {
    switch (t) {
      case VenueType.restaurant:
        return '🍽 Ресторан';
      case VenueType.cafe:
        return '☕ Кафе';
      case VenueType.park:
        return '🌳 Парк';
      case VenueType.museum:
        return '🏛 Музей';
      case VenueType.temple:
        return '⛪ Храм';
      case VenueType.bar:
        return '🍺 Бар';
      case VenueType.spa:
        return '🧖 Спа';
      case VenueType.sport:
        return '⚽ Спорт';
      case VenueType.attraction:
        return '🎡 Развлечения';
      case VenueType.embankment:
        return '🌊 Набережная';
      case VenueType.mall:
        return '🛍 ТЦ';
      case VenueType.theater:
        return '🎭 Театр';
    }
  }

  Color _typeColor(VenueType t) {
    switch (t) {
      case VenueType.restaurant:
      case VenueType.cafe:
        return Colors.orange.shade700;
      case VenueType.park:
        return Colors.green.shade700;
      case VenueType.museum:
      case VenueType.theater:
        return Colors.purple.shade700;
      case VenueType.temple:
        return Colors.brown.shade600;
      case VenueType.bar:
        return Colors.amber.shade800;
      case VenueType.spa:
        return Colors.pink.shade700;
      case VenueType.sport:
        return Colors.blue.shade700;
      case VenueType.attraction:
        return Colors.red.shade700;
      case VenueType.embankment:
        return Colors.teal.shade700;
      case VenueType.mall:
        return Colors.indigo.shade700;
    }
  }
}

class _DistanceChip extends StatelessWidget {
  const _DistanceChip(this.distance);
  final DistanceTag distance;

  @override
  Widget build(BuildContext context) {
    final label = switch (distance) {
      DistanceTag.near => '📍 Рядом',
      DistanceTag.medium => '🚗 Недалеко',
      DistanceTag.far => '✈️ Далеко',
    };
    return _chip(label, Colors.black54);
  }
}

class _PriceChip extends StatelessWidget {
  const _PriceChip(this.price);
  final PriceTag price;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (price) {
      PriceTag.budget => ('💰 Бюджетно', Colors.green.shade700),
      PriceTag.mid => ('💳 Средне', Colors.blue.shade700),
      PriceTag.premium => ('💎 Премиум', Colors.purple.shade700),
    };
    return _chip(label, color);
  }
}

class _GroupChip extends StatelessWidget {
  const _GroupChip(this.group);
  final GroupTag group;

  @override
  Widget build(BuildContext context) {
    final label = switch (group) {
      GroupTag.solo => '🧍 Один',
      GroupTag.couple => '👫 Вдвоём',
      GroupTag.friends => '👥 Компания',
      GroupTag.family => '👨‍👩‍👧 Семья',
      GroupTag.largeGroup => '🎉 Группа',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 11)),
    );
  }
}

Widget _chip(String label, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style:
            const TextStyle(color: Colors.white, fontSize: 11, height: 1.2),
      ),
    );
