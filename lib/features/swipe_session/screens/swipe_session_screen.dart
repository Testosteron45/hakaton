import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/swipe_session.dart';
import '../providers/swipe_session_provider.dart';
import '../widgets/venue_card.dart';

class SwipeSessionScreen extends ConsumerStatefulWidget {
  const SwipeSessionScreen({super.key, required this.mode});

  final SessionMode mode;

  @override
  ConsumerState<SwipeSessionScreen> createState() => _SwipeSessionScreenState();
}

class _SwipeSessionScreenState extends ConsumerState<SwipeSessionScreen>
    with SingleTickerProviderStateMixin {
  late final AppinioSwiperController _controller;
  late final AnimationController _detailsController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AppinioSwiperController();
    _detailsController = AnimationController(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(swipeSessionProvider.notifier).startSession(widget.mode);
      });
    }
  }

  @override
  void dispose() {
    _detailsController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onSwipe(int previousIndex, int targetIndex, SwiperActivity activity) {
    if (activity is! Swipe) return;
    _closeDetails();

    final session = ref.read(swipeSessionProvider);
    if (session == null) return;
    if (previousIndex >= session.queue.length) return;

    final venue = session.queue[previousIndex];
    final liked = activity.direction == AxisDirection.right;
    ref.read(swipeSessionProvider.notifier).swipe(venue.id, liked);

    final updated = ref.read(swipeSessionProvider);
    if (updated != null && updated.isFinished) {
      context.pushReplacement('/result');
    }
  }

  void _closeDetails() {
    _detailsController.animateTo(
      0,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  void _swipeLeft() {
    _closeDetails();
    _controller.swipeLeft();
  }

  void _swipeRight() {
    _closeDetails();
    _controller.swipeRight();
  }

  void _handleCardVerticalDragUpdate(
    DragUpdateDetails details,
    double revealExtent,
  ) {
    final next =
        _detailsController.value - (details.delta.dy / revealExtent);
    _detailsController.value = next.clamp(0.0, 1.0);
  }

  void _handleCardVerticalDragEnd(
    DragEndDetails details,
    double revealExtent,
  ) {
    final velocity = -(details.primaryVelocity ?? 0) / revealExtent;

    if (velocity > 1.5) {
      _detailsController.animateTo(
        1.0,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    if (velocity < -1.5) {
      _detailsController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _detailsController.animateTo(
      _detailsController.value > 0.38 ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(swipeSessionProvider);

    if (session == null) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    final remaining = session.totalCards - session.currentIndex;
    final progress = session.currentIndex / session.totalCards;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  _CircleBtn(
                    icon: Icons.explore_rounded,
                    backgroundColor: AppColors.primary,
                    iconColor: Colors.white,
                    onTap: () => context.push('/map'),
                  ),
                  const SizedBox(width: 10),
                  _CircleBtn(
                    icon: Icons.arrow_back_rounded,
                    onTap: () {
                      ref.read(swipeSessionProvider.notifier).reset();
                      context.pop();
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.mode.label,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.1),
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '$remaining',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Card stack ────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final revealExtent =
                        (constraints.maxHeight * 0.45).clamp(240.0, 340.0);

                    return AnimatedBuilder(
                      animation: _detailsController,
                      builder: (context, _) => SizedBox(
                        height: constraints.maxHeight,
                        child: AppinioSwiper(
                          controller: _controller,
                          cardCount: session.queue.length,
                          initialIndex: session.currentIndex,
                          onSwipeEnd: _onSwipe,
                          swipeOptions: const SwipeOptions.only(
                            left: true,
                            right: true,
                          ),
                          backgroundCardScale: 0.95,
                          backgroundCardCount: 2,
                          cardBuilder: (context, index) {
                            if (index >= session.queue.length) {
                              return const SizedBox.shrink();
                            }
                            final isTopCard = index == session.currentIndex;
                            return VenueCard(
                              venue: session.queue[index],
                              detailsProgress:
                                  isTopCard ? _detailsController.value : 0,
                              detailsExtent: revealExtent,
                              onDetailsDragUpdate: isTopCard
                                  ? (d) => _handleCardVerticalDragUpdate(
                                        d,
                                        revealExtent,
                                      )
                                  : null,
                              onDetailsDragEnd: isTopCard
                                  ? (d) => _handleCardVerticalDragEnd(
                                        d,
                                        revealExtent,
                                      )
                                  : null,
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Action buttons ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionBtn(
                    icon: Icons.close_rounded,
                    color: AppColors.error,
                    onTap: _swipeLeft,
                  ),
                  const SizedBox(width: 24),
                  _ActionBtn(
                    icon: Icons.favorite_rounded,
                    color: AppColors.success,
                    onTap: _swipeRight,
                    large: true,
                  ),
                  const SizedBox(width: 24),
                  _ActionBtn(
                    icon: Icons.skip_next_rounded,
                    color: Colors.white30,
                    onTap: _swipeLeft,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Buttons ───────────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    this.large = false,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 74.0 : 58.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: large ? color : Colors.white.withValues(alpha: 0.07),
          shape: BoxShape.circle,
          border: large
              ? null
              : Border.all(
                  color: color.withValues(alpha: 0.5),
                  width: 1.5,
                ),
          boxShadow: large
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: large ? Colors.white : color,
          size: large ? 32 : 24,
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor ?? Colors.white70, size: 20),
      ),
    );
  }
}
