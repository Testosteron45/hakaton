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

class _SwipeSessionScreenState extends ConsumerState<SwipeSessionScreen> {
  late final AppinioSwiperController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppinioSwiperController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSwipe(int previousIndex, int targetIndex, SwiperActivity activity) {
    final session = ref.read(swipeSessionProvider);
    if (session == null) return;
    if (previousIndex >= session.queue.length) return;

    final venue = session.queue[previousIndex];
    final liked =
        activity is Swipe && activity.direction == AxisDirection.right;

    ref.read(swipeSessionProvider.notifier).swipe(venue.id, liked);

    final updated = ref.read(swipeSessionProvider);
    if (updated != null && updated.isFinished) {
      context.pushReplacement('/result');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(swipeSessionProvider);

    if (session == null) {
      // Venues are guaranteed loaded by loading screen — start session immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(swipeSessionProvider.notifier).startSession(widget.mode);
        }
      });
      return const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    final remaining = session.totalCards - session.currentIndex;
    final progress = session.totalCards > 0
        ? session.currentIndex / session.totalCards
        : 0.0;

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
                  // Map
                  _CircleBtn(
                    icon: Icons.explore_rounded,
                    backgroundColor: AppColors.primary,
                    iconColor: Colors.white,
                    onTap: () => context.push('/map'),
                  ),

                  const SizedBox(width: 10),

                  // Back
                  _CircleBtn(
                    icon: Icons.arrow_back_rounded,
                    onTap: () {
                      ref.read(swipeSessionProvider.notifier).reset();
                      context.pop();
                    },
                  ),

                  const SizedBox(width: 12),

                  // Progress bar + mode label
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

                  // Counter badge
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
                    return VenueCard(venue: session.queue[index]);
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
                  // Dislike
                  _ActionBtn(
                    icon: Icons.close_rounded,
                    color: AppColors.error,
                    onTap: () => _controller.swipeLeft(),
                  ),
                  const SizedBox(width: 24),

                  // Like — bigger
                  _ActionBtn(
                    icon: Icons.favorite_rounded,
                    color: AppColors.success,
                    onTap: () => _controller.swipeRight(),
                    large: true,
                  ),
                  const SizedBox(width: 24),

                  // Skip
                  _ActionBtn(
                    icon: Icons.skip_next_rounded,
                    color: Colors.white30,
                    onTap: () => _controller.swipeLeft(),
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
