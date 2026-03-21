import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/venue_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/venue.dart';

// ── VenueCard ─────────────────────────────────────────────────────────────────

class VenueCard extends StatelessWidget {
  const VenueCard({
    super.key,
    required this.venue,
    this.detailsProgress = 0,
    this.compactProgress = 0,
    this.detailsExtent = 280,
    this.onDetailsDragUpdate,
    this.onDetailsDragEnd,
  });

  final Venue venue;
  final double detailsProgress;
  final double compactProgress;
  final double detailsExtent;
  final ValueChanged<DragUpdateDetails>? onDetailsDragUpdate;
  final ValueChanged<DragEndDetails>? onDetailsDragEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 36,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final p = detailsProgress.clamp(0.0, 1.0);
            final compactP = compactProgress.clamp(0.0, 1.0);
            final ep = Curves.easeOutCubic.transform(p);
            final offsetY = detailsExtent * p;
            final previewH =
                lerpDouble((constraints.maxHeight * 0.27).clamp(148.0, 182.0), 96.0, compactP)!;
            final parallax = detailsExtent * p * 0.22;
            final photoBottom = previewH - lerpDouble(22, 6, ep)!;

            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragUpdate: onDetailsDragUpdate,
              onVerticalDragEnd: onDetailsDragEnd,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: -offsetY,
                    height: constraints.maxHeight + detailsExtent,
                    child: Column(
                      children: [
                        SizedBox(
                          height: constraints.maxHeight,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // ── Photo with parallax ──────────────────────
                              Positioned.fill(
                                bottom: photoBottom,
                                child: Transform.translate(
                                  offset: Offset(0, parallax),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      _VenuePhoto(
                                        venueId: venue.id,
                                        imageUrl: venue.photoUrl,
                                      ),
                                      // top vignette
                                      const DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            stops: [0.0, 0.5, 0.8, 1.0],
                                            colors: [
                                              Color(0x18000000),
                                              Color(0x08000000),
                                              Color(0x20000000),
                                              Color(0x50000000),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // bottom fade into panel
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        bottom: 0,
                                        height: 100,
                                        child: IgnorePointer(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  const Color(0xFF141929)
                                                      .withValues(alpha: 0.9),
                                                  const Color(0xFF141929),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // ── Type chip ────────────────────────────────
                              Positioned(
                                top: 18,
                                left: 18,
                                child: _GlassChip(
                                  icon: _typeIcon(venue.type),
                                  label: _typeLabel(venue.type),
                                ),
                              ),
                              // ── Preview panel ─────────────────────────────
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: _CardPreview(
                                  venue: venue,
                                  height: previewH,
                                  progress: p,
                                  easedProgress: ep,
                                  compactProgress: compactP,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ── Details section ──────────────────────────────
                        _CardDetails(
                          venue: venue,
                          height: detailsExtent,
                          progress: p,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Photo ─────────────────────────────────────────────────────────────────────

class _VenuePhoto extends StatelessWidget {
  const _VenuePhoto({required this.venueId, required this.imageUrl});

  final String venueId;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final assetPath = kVenueAssets[venueId];
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _error(),
      );
    }

    if (kIsWeb) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _placeholder();
        },
        errorBuilder: (_, __, ___) => _error(),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) => _error(),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.surfaceDark,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.accent,
            strokeWidth: 2,
          ),
        ),
      );

  Widget _error() => Container(
        color: AppColors.surfaceDark,
        child: const Icon(
          Icons.image_not_supported_outlined,
          size: 56,
          color: AppColors.textMutedOnDark,
        ),
      );
}

// ── Glass chip ────────────────────────────────────────────────────────────────

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
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

// ── Card preview (collapsed bottom panel) ────────────────────────────────────

class _CardPreview extends StatelessWidget {
  const _CardPreview({
    required this.venue,
    required this.height,
    required this.progress,
    required this.easedProgress,
    required this.compactProgress,
  });

  final Venue venue;
  final double height;
  final double progress;
  final double easedProgress;
  final double compactProgress;

  @override
  Widget build(BuildContext context) {
    final topAlpha = lerpDouble(0.86, 0.98, easedProgress)!;
    final compactFade = (1.0 - compactProgress * 1.8).clamp(0.0, 1.0);
    const verticalPadding = 24.0; // top 10 + bottom 14
    const handleRowHeight = 22.0;
    const handleGap = 8.0;
    const titleApproxHeight = 56.0;
    final secondaryMaxHeight = (height -
            verticalPadding -
            handleRowHeight -
            handleGap -
            titleApproxHeight -
            8.0)
        .clamp(0.0, 110.0);
    final secondaryH =
        lerpDouble(secondaryMaxHeight, 0.0, easedProgress)! * compactFade;
    final secondaryOpacity =
        (1.0 - easedProgress * 1.6).clamp(0.0, 1.0) * compactFade;
    final secondarySlide = 6.0 * easedProgress;
    final titleFontSize = lerpDouble(22, 20, compactProgress)!;

    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.3, 1.0],
          colors: [
            const Color(0xFF1C2538).withValues(alpha: topAlpha),
            const Color(0xFF192035).withValues(alpha: 0.97),
            const Color(0xFF141929),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: ClipRect(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
                if (compactProgress < 0.98) ...[
                  SizedBox(
                    height: 22,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          right: 0,
                          child: _SwipeUpHint(progress: progress),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ] else
                  const SizedBox(height: 4),
                Text(
                  venue.name,
                  maxLines: compactProgress > 0.4 ? 2 : 3,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                    letterSpacing: -0.3,
                  ),
                ),
                if (compactFade > 0) ...[
                  const SizedBox(height: 8),
                  Opacity(
                    opacity: compactFade,
                    child: Row(
                      children: [
                        _PriceTag(venue.price),
                        const SizedBox(width: 6),
                        _DistanceTag(venue.distance),
                      ],
                    ),
                  ),
                ],
                if (secondaryH > 0)
                  ClipRect(
                    child: SizedBox(
                      height: secondaryH,
                      child: Opacity(
                        opacity: secondaryOpacity,
                        child: Transform.translate(
                          offset: Offset(0, secondarySlide),
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text(
                                  venue.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      color: Colors.white30,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        venue.address,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Drag handle ───────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

// ── Swipe-up hint (bouncing animation) ────────────────────────────────────────

class _SwipeUpHint extends StatefulWidget {
  final double progress;
  const _SwipeUpHint({required this.progress});

  @override
  State<_SwipeUpHint> createState() => _SwipeUpHintState();
}

class _SwipeUpHintState extends State<_SwipeUpHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = (1.0 - widget.progress * 5).clamp(0.0, 1.0);
    if (opacity == 0) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(_anim.value);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, -2.5 * t),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Card details (expanded section) ──────────────────────────────────────────

class _CardDetails extends StatelessWidget {
  const _CardDetails({
    required this.venue,
    required this.height,
    required this.progress,
  });

  final Venue venue;
  final double height;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final revealProgress = Curves.easeOutCubic.transform(
      ((progress - 0.06) / 0.94).clamp(0.0, 1.0),
    );

    return Container(
      height: height,
      width: double.infinity,
      color: const Color(0xFF141929),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Transform.translate(
        offset: Offset(0, 20 * (1 - revealProgress)),
        child: Opacity(
          opacity: revealProgress,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Feature chips ────────────────────────────────────────────
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _DetailChip(
                      icon: Icons.group_rounded,
                      label: _groupLabel(venue.group),
                    ),
                    _DetailChip(
                      icon: Icons.payments_rounded,
                      label: _priceLabel(venue.price),
                    ),
                    for (final feature in venue.features.take(2))
                      _DetailChip(
                        icon: _featureIcon(feature),
                        label: _featureLabel(feature),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                // ── Full description ─────────────────────────────────────────
                Text(
                  venue.description,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 14),
                // ── Address ──────────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.primary,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        venue.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Detail chip ───────────────────────────────────────────────────────────────

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.09),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.accent.withValues(alpha: 0.85),
            size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Price tag ─────────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
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

// ── Distance tag ──────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
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

String _groupLabel(GroupTag group) => switch (group) {
      GroupTag.solo => 'Соло',
      GroupTag.couple => 'Вдвоём',
      GroupTag.friends => 'С друзьями',
      GroupTag.family => 'С семьёй',
      GroupTag.largeGroup => 'Большой компанией',
    };

String _priceLabel(PriceTag price) => switch (price) {
      PriceTag.budget => 'Бюджетно',
      PriceTag.mid => 'Средний чек',
      PriceTag.premium => 'Премиум',
    };

String _featureLabel(VenueFeature feature) => switch (feature) {
      VenueFeature.kids => 'С детьми',
      VenueFeature.christian => 'Спокойствие',
      VenueFeature.sport => 'Активность',
      VenueFeature.romantic => 'Романтика',
      VenueFeature.outdoor => 'На воздухе',
      VenueFeature.alcohol => 'Вечерний формат',
      VenueFeature.vegetarian => 'Лёгкая еда',
      VenueFeature.quiet => 'Тихо',
      VenueFeature.lively => 'Живая атмосфера',
      VenueFeature.cultural => 'Культура',
      VenueFeature.historical => 'История',
      VenueFeature.nature => 'Природа',
    };

IconData _featureIcon(VenueFeature feature) => switch (feature) {
      VenueFeature.kids => Icons.child_care_rounded,
      VenueFeature.christian => Icons.self_improvement_rounded,
      VenueFeature.sport => Icons.directions_run_rounded,
      VenueFeature.romantic => Icons.favorite_rounded,
      VenueFeature.outdoor => Icons.park_rounded,
      VenueFeature.alcohol => Icons.local_bar_rounded,
      VenueFeature.vegetarian => Icons.eco_rounded,
      VenueFeature.quiet => Icons.nights_stay_rounded,
      VenueFeature.lively => Icons.celebration_rounded,
      VenueFeature.cultural => Icons.palette_rounded,
      VenueFeature.historical => Icons.account_balance_rounded,
      VenueFeature.nature => Icons.forest_rounded,
    };
