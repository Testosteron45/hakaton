import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/assistant_provider.dart';
import 'kazak_assistant_view.dart';

class GlobalAssistantOverlay extends ConsumerStatefulWidget {
  const GlobalAssistantOverlay({super.key});

  @override
  ConsumerState<GlobalAssistantOverlay> createState() =>
      _GlobalAssistantOverlayState();
}

class _GlobalAssistantOverlayState
    extends ConsumerState<GlobalAssistantOverlay> {
  bool _expanded = false;
  Offset? _position;

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(kazakAssistantSnapshotProvider);
    final actions = ref.read(kazakAssistantActionsProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final modelSize = _expanded ? 128.0 : 108.0;
          final viewport = constraints.biggest;
          final position = _clampPosition(
            _position ??
                Offset(
                  math.max(8, viewport.width - modelSize - 20),
                  math.max(8, viewport.height - modelSize - 28),
                ),
            viewport,
            modelSize,
          );
          final bubbleWidth = math.min(viewport.width - 24, 260.0);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: position.dx,
                top: position.dy,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    setState(() => _expanded = true);
                    actions.generateAiReply();
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _position = _clampPosition(
                        position + details.delta,
                        viewport,
                        modelSize,
                      );
                    });
                  },
                  child: SizedBox.square(
                    dimension: modelSize,
                    child: KazakAssistantView(
                      customization: snapshot.customization,
                      mood: snapshot.mood,
                      size: modelSize,
                      showLoadout: false,
                      showBadges: false,
                      showFrame: false,
                      enableModelInteraction: false,
                    ),
                  ),
                ),
              ),
              if (_expanded)
                Positioned(
                  left: math.max(8, position.dx - 6),
                  top: math.min(
                    math.max(8.0, viewport.height - 52),
                    position.dy + modelSize + 6,
                  ),
                  child: PointerInterceptor(
                    child: _AssistantActionButton(
                      label: 'Поболтать с ботом',
                      onTap: () {
                        setState(() => _expanded = false);
                        context.push('/assistant-chat');
                      },
                    ),
                  ),
                ),
              if (_expanded)
                Positioned(
                  left: math.max(12, position.dx + modelSize - bubbleWidth + 12),
                  top: math.max(8, position.dy - 124),
                  child: PointerInterceptor(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: bubbleWidth),
                      child: _AssistantSpeechBubble(
                        isDark: isDark,
                        onSurface: scheme.onSurface,
                        headline: snapshot.headline,
                        message: snapshot.message,
                        onClose: () => setState(() => _expanded = false),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Offset _clampPosition(Offset position, Size viewport, double size) {
    const padding = 8.0;
    return Offset(
      position.dx.clamp(padding, math.max(padding, viewport.width - size - padding)),
      position.dy.clamp(padding, math.max(padding, viewport.height - size - padding)),
    );
  }
}

class _AssistantSpeechBubble extends StatelessWidget {
  const _AssistantSpeechBubble({
    required this.isDark,
    required this.onSurface,
    required this.headline,
    required this.message,
    required this.onClose,
  });

  final bool isDark;
  final Color onSurface;
  final String headline;
  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceDark.withValues(alpha: 0.94)
              : Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.10),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    headline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onClose,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: onSurface.withValues(alpha: 0.68),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssistantActionButton extends StatelessWidget {
  const _AssistantActionButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark.withValues(alpha: 0.96)
                : Colors.white.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.softBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.chat_bubble_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
