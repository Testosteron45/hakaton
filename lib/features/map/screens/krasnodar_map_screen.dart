import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/venue.dart';
import '../../../shared/providers/providers.dart';
import '../../swipe_session/providers/swipe_session_provider.dart';

class KrasnodarMapScreen extends ConsumerWidget {
  const KrasnodarMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venues = ref.watch(venueRepositoryProvider).getAll();
    final session = ref.watch(swipeSessionProvider);
    final cardVenueIds =
        session?.queue.map((venue) => venue.id).toSet() ?? <String>{};

    final points = [
      ...venues.map(
        (venue) => _MapPlace.fromVenue(
          venue,
          isCardPlace: cardVenueIds.contains(venue.id),
        ),
      ),
      ..._regionHighlights,
    ];

    final featured = [
      ...points.where((point) => point.isCardPlace),
      ..._regionHighlights.where((point) => point.featured),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: _mapCenter,
              initialZoom: 7.2,
              minZoom: 5.8,
              maxZoom: 17,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'krasnodar_travel',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  for (final point in points)
                    Marker(
                      point: point.location,
                      width: point.isCardPlace ? 86 : 64,
                      height: point.isCardPlace || point.featured ? 88 : 64,
                      child: _MapPin(
                        place: point,
                        onTap: () => _showPlaceSheet(context, point),
                      ),
                    ),
                ],
              ),
              RichAttributionWidget(
                showFlutterMapAttribution: false,
                attributions: const [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  _TopButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.56),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Карта Краснодарского края',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Настоящая карта с точками по краю и местами из ваших карточек',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.35,
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
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.place_rounded,
                          label: '${points.length} точек',
                        ),
                        _InfoChip(
                          icon: Icons.explore_rounded,
                          label: '${cardVenueIds.length} из карточек',
                          color: AppColors.primary,
                        ),
                        const _LegendChip(
                          label: 'Из карточек',
                          color: AppColors.primary,
                        ),
                        const _LegendChip(
                          label: 'Достопримечательности',
                          color: AppColors.markerLandmark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Нажмите на маркер, чтобы открыть подробности',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    if (featured.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 82,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: featured.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final place = featured[index];
                            return _FeaturedPlaceCard(
                              place: place,
                              onTap: () => _showPlaceSheet(context, place),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPlaceSheet(BuildContext context, _MapPlace place) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color:
                            _categoryColor(place.category).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        place.isCardPlace
                            ? Icons.explore_rounded
                            : Icons.place_rounded,
                        color: _categoryColor(place.category),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        place.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  place.subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SheetTag(label: place.categoryLabel),
                    if (place.isCardPlace)
                      const _SheetTag(
                        label: 'Есть в карточках',
                        color: AppColors.primary,
                      ),
                    if (place.featured)
                      const _SheetTag(
                        label: 'Точка региона',
                        color: AppColors.markerLandmark,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Понятно'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.place, required this.onTap});

  final _MapPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(place.category);
    final pinSize = place.isCardPlace ? 36.0 : 28.0;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (place.isCardPlace || place.featured)
            Container(
              constraints: const BoxConstraints(maxWidth: 160),
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.74),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: place.isCardPlace
                      ? AppColors.primary.withValues(alpha: 0.9)
                      : color.withValues(alpha: 0.6),
                ),
              ),
              child: Text(
                place.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          Icon(
            Icons.location_on_rounded,
            size: pinSize,
            color: color,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 12,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopButton extends StatelessWidget {
  const _TopButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.56),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.color = Colors.white,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedPlaceCard extends StatelessWidget {
  const _FeaturedPlaceCard({required this.place, required this.onTap});

  final _MapPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 210,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _categoryColor(place.category).withValues(alpha: 0.28),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              place.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              place.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetTag extends StatelessWidget {
  const _SheetTag({required this.label, this.color = AppColors.markerLandmark});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

enum _MapCategory { card, landmark, nature, culture, beach, food }

class _MapPlace {
  const _MapPlace({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.location,
    required this.category,
    this.featured = false,
    this.isCardPlace = false,
  });

  factory _MapPlace.fromVenue(
    Venue venue, {
    required bool isCardPlace,
  }) {
    final (lat, lon) = _resolveVenueBaseCoordinate(venue.address);
    return _MapPlace(
      id: venue.id,
      name: venue.name,
      subtitle: venue.address,
      location: LatLng(
        lat + _seedOffset(venue.id, 0.045),
        lon + _seedOffset('${venue.id}_lon', 0.06),
      ),
      category:
          isCardPlace ? _MapCategory.card : _categoryFromVenueType(venue.type),
      isCardPlace: isCardPlace,
    );
  }

  final String id;
  final String name;
  final String subtitle;
  final LatLng location;
  final _MapCategory category;
  final bool featured;
  final bool isCardPlace;

  String get categoryLabel => switch (category) {
        _MapCategory.card => 'Место из подбора',
        _MapCategory.landmark => 'Достопримечательность',
        _MapCategory.nature => 'Природа',
        _MapCategory.culture => 'Культура',
        _MapCategory.beach => 'Побережье',
        _MapCategory.food => 'Еда и гастро',
      };
}

const _mapCenter = LatLng(44.82, 39.05);

const _regionHighlights = <_MapPlace>[
  _MapPlace(
    id: 'r01',
    name: 'Олимпийский парк',
    subtitle: 'Сириус, побережье Черного моря',
    location: LatLng(43.4048, 39.9557),
    category: _MapCategory.landmark,
    featured: true,
  ),
  _MapPlace(
    id: 'r02',
    name: 'Морпорт Сочи',
    subtitle: 'Исторический центр Сочи',
    location: LatLng(43.5855, 39.7231),
    category: _MapCategory.beach,
    featured: true,
  ),
  _MapPlace(
    id: 'r03',
    name: 'Красная Поляна',
    subtitle: 'Горы, канатные дороги, маршруты',
    location: LatLng(43.6806, 40.2040),
    category: _MapCategory.nature,
    featured: true,
  ),
  _MapPlace(
    id: 'r04',
    name: 'Абрау-Дюрсо',
    subtitle: 'Озеро и винодельня',
    location: LatLng(44.6974, 37.6004),
    category: _MapCategory.food,
    featured: true,
  ),
  _MapPlace(
    id: 'r05',
    name: 'Анапский маяк',
    subtitle: 'Видовая точка на берегу',
    location: LatLng(44.8948, 37.3055),
    category: _MapCategory.beach,
    featured: true,
  ),
  _MapPlace(
    id: 'r06',
    name: 'Кипарисовое озеро',
    subtitle: 'Сукко, прогулки и сапы',
    location: LatLng(44.8120, 37.4434),
    category: _MapCategory.nature,
    featured: true,
  ),
  _MapPlace(
    id: 'r07',
    name: 'Геленджикская набережная',
    subtitle: 'Центр курортной жизни',
    location: LatLng(44.5630, 38.0788),
    category: _MapCategory.beach,
    featured: true,
  ),
  _MapPlace(
    id: 'r08',
    name: 'Скала Парус',
    subtitle: 'Одна из самых узнаваемых точек края',
    location: LatLng(44.4389, 38.1843),
    category: _MapCategory.landmark,
  ),
  _MapPlace(
    id: 'r09',
    name: 'Плато Лаго-Наки',
    subtitle: 'Пещеры, горы, смотровые',
    location: LatLng(44.0894, 40.0145),
    category: _MapCategory.nature,
    featured: true,
  ),
  _MapPlace(
    id: 'r10',
    name: 'Гуамское ущелье',
    subtitle: 'Узкоколейка и прогулки по каньону',
    location: LatLng(44.2106, 39.8966),
    category: _MapCategory.nature,
    featured: true,
  ),
  _MapPlace(
    id: 'r11',
    name: 'Долина лотосов',
    subtitle: 'Темрюкский район',
    location: LatLng(45.2833, 37.2905),
    category: _MapCategory.nature,
  ),
  _MapPlace(
    id: 'r12',
    name: 'Этнопарк Атамань',
    subtitle: 'Казачий быт и фестивали',
    location: LatLng(45.2197, 36.7248),
    category: _MapCategory.culture,
    featured: true,
  ),
];

Color _categoryColor(_MapCategory category) => switch (category) {
      _MapCategory.card => AppColors.primary,
      _MapCategory.landmark => AppColors.markerLandmark,
      _MapCategory.nature => AppColors.markerNature,
      _MapCategory.culture => AppColors.markerMuseum,
      _MapCategory.beach => AppColors.markerBeach,
      _MapCategory.food => AppColors.markerFood,
    };

_MapCategory _categoryFromVenueType(VenueType type) => switch (type) {
      VenueType.restaurant => _MapCategory.food,
      VenueType.cafe => _MapCategory.food,
      VenueType.park => _MapCategory.nature,
      VenueType.museum => _MapCategory.culture,
      VenueType.temple => _MapCategory.culture,
      VenueType.bar => _MapCategory.landmark,
      VenueType.spa => _MapCategory.beach,
      VenueType.sport => _MapCategory.nature,
      VenueType.attraction => _MapCategory.landmark,
      VenueType.embankment => _MapCategory.beach,
      VenueType.mall => _MapCategory.landmark,
      VenueType.theater => _MapCategory.culture,
    };

(double, double) _resolveVenueBaseCoordinate(String address) {
  final normalized = address.toLowerCase();

  if (normalized.contains('сочи')) return (43.5855, 39.7231);
  if (normalized.contains('геленджик')) return (44.5630, 38.0788);
  if (normalized.contains('горячий ключ')) return (44.6343, 39.1356);
  if (normalized.contains('динской район')) return (45.1870, 39.1900);
  if (normalized.contains('копанской')) return (45.1000, 38.7600);
  if (normalized.contains('краснодарское')) return (45.0480, 39.1820);
  if (normalized.contains('новый')) return (45.0500, 39.3900);
  if (normalized.contains('краснодарский край')) return (44.9200, 38.6500);
  return (45.0355, 38.9753);
}

double _seedOffset(String value, double scale) {
  final seed = value.codeUnits.fold<int>(0, (sum, code) => sum + code);
  final normalized = math.sin(seed.toDouble()) * 0.5 + 0.5;
  return (normalized - 0.5) * scale;
}
