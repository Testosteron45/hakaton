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
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AppinioSwiperController();
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
    _controller.dispose();
    super.dispose();
  }

  void _onSwipe(int previousIndex, int targetIndex, SwiperActivity activity) {
    final session = ref.read(swipeSessionProvider);
    if (session == null) return;
    if (previousIndex >= session.queue.length) return;

    final venue = session.queue[previousIndex];
    final liked = activity is Swipe && activity.direction == AxisDirection.right;

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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final remaining = session.totalCards - session.currentIndex;
    final progress = session.currentIndex / session.totalCards;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: () {
                      ref.read(swipeSessionProvider.notifier).reset();
                      context.pop();
                    },
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          widget.mode.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white24,
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$remaining',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            // Hint
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SwipeHint(
                      icon: Icons.close, color: Colors.redAccent, text: 'Не интересно'),
                  SizedBox(width: 32),
                  _SwipeHint(
                      icon: Icons.favorite, color: Colors.greenAccent, text: 'Хочу сходить'),
                ],
              ),
            ),

            // Card stack
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
                  cardBuilder: (context, index) {
                    if (index >= session.queue.length) {
                      return const SizedBox.shrink();
                    }
                    return VenueCard(venue: session.queue[index]);
                  },
                ),
              ),
            ),

            // Manual buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(48, 8, 48, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.close,
                    color: Colors.redAccent,
                    onTap: () => _controller.swipeLeft(),
                  ),
                  _ActionButton(
                    icon: Icons.favorite,
                    color: Colors.greenAccent,
                    onTap: () => _controller.swipeRight(),
                    large: true,
                  ),
                  _ActionButton(
                    icon: Icons.skip_next,
                    color: Colors.white38,
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

class _SwipeHint extends StatelessWidget {
  const _SwipeHint(
      {required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
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
    final size = large ? 64.0 : 52.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: large ? color.withOpacity(0.15) : Colors.white12,
          shape: BoxShape.circle,
          border: Border.all(
            color: large ? color : Colors.white24,
            width: large ? 2.5 : 1.5,
          ),
        ),
        child: Icon(icon, color: color, size: large ? 32 : 24),
      ),
    );
  }
}
