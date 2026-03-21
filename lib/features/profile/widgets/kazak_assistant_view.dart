import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../models/assistant_customization.dart';
import '../providers/assistant_provider.dart';

class KazakAssistantView extends StatelessWidget {
  const KazakAssistantView({
    super.key,
    required this.customization,
    required this.mood,
    this.size = 280,
    this.showLoadout = false,
    this.showBadges = true,
    this.showFrame = true,
    this.showDecorations = false,
    this.enableModelInteraction = true,
  });

  final AssistantCustomization customization;
  final KazakAssistantMood mood;
  final double size;
  final bool showLoadout;
  final bool showBadges;
  final bool showFrame;
  final bool showDecorations;
  final bool enableModelInteraction;

  @override
  Widget build(BuildContext context) {
    final theme = _viewTheme(customization.backdrop);
    final borderRadius = BorderRadius.circular(28);
    final content = Stack(
      children: [
        if (showFrame)
          Positioned(
            top: -32,
            left: -16,
            child: _GlowOrb(
              color: customization.costumeColor.primary.withValues(alpha: 0.28),
              size: 120,
            ),
          ),
        if (showFrame)
          Positioned(
            top: 26,
            right: -22,
            child: _GlowOrb(
              color: Colors.white.withValues(alpha: 0.14),
              size: 104,
            ),
          ),
        Align(
          child: SizedBox.square(
            dimension: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      showFrame ? 8 : 0,
                      0,
                      showFrame ? 34 : 12,
                    ),
                    child: _Real3DModel(
                      mood: mood,
                      backdrop: customization.backdrop,
                      enableInteraction: enableModelInteraction,
                    ),
                  ),
                ),
                if (showDecorations)
                  Align(
                    alignment: const Alignment(0, -0.78),
                    child: _HatDecoration(
                      style: customization.hatStyle,
                      color: customization.costumeColor.primary,
                    ),
                  ),
                if (showDecorations &&
                    customization.mustacheStyle != AssistantMustacheStyle.none)
                  Align(
                    alignment: const Alignment(0, -0.05),
                    child: _MustacheDecoration(
                      style: customization.mustacheStyle,
                    ),
                  ),
                if (showDecorations)
                  Align(
                    alignment: const Alignment(0.52, 0.36),
                    child: _AccessoryDecoration(
                      accessory: customization.accessory,
                      accent: customization.costumeColor.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (showBadges && showFrame)
          Positioned(
            top: 14,
            left: 14,
            child: _OverlayBadge(
              icon: Icons.view_in_ar_rounded,
              label: '3D prototype',
              background: Colors.white.withValues(alpha: 0.14),
              foreground: Colors.white,
            ),
          ),
        if (showBadges && showFrame)
          Positioned(
            top: 14,
            right: 14,
            child: _OverlayBadge(
              icon: _moodIcon(mood),
              label: _moodLabel(mood),
              background: Colors.black.withValues(alpha: 0.18),
              foreground: Colors.white,
            ),
          ),
        if (showLoadout && showFrame)
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _OverlayBadge(
                  icon: Icons.checkroom_rounded,
                  label: customization.costumeColor.label,
                  background: Colors.white.withValues(alpha: 0.14),
                  foreground: Colors.white,
                ),
                _OverlayBadge(
                  icon: Icons.face_rounded,
                  label: customization.mustacheStyle.label,
                  background: Colors.white.withValues(alpha: 0.14),
                  foreground: Colors.white,
                ),
                _OverlayBadge(
                  icon: Icons.workspace_premium_rounded,
                  label: customization.hatStyle.label,
                  background: Colors.white.withValues(alpha: 0.14),
                  foreground: Colors.white,
                ),
              ],
            ),
          ),
      ],
    );

    if (!showFrame) {
      return SizedBox.square(
        dimension: size,
        child: content,
      );
    }

    return Container(
      height: size,
      decoration: BoxDecoration(
        gradient: theme.gradient,
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: content,
      ),
    );
  }
}

class _Real3DModel extends StatelessWidget {
  const _Real3DModel({
    required this.mood,
    required this.backdrop,
    required this.enableInteraction,
  });

  final KazakAssistantMood mood;
  final AssistantBackdrop backdrop;
  final bool enableInteraction;

  static const _modelSrc =
      'https://modelviewer.dev/shared-assets/models/RobotExpressive.glb';

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !enableInteraction,
      child: ModelViewer(
        src: _modelSrc,
        alt: 'Animated 3D assistant prototype',
        backgroundColor: Colors.transparent,
        cameraControls: enableInteraction,
        disableZoom: !enableInteraction,
        disablePan: !enableInteraction,
        autoRotate: mood != KazakAssistantMood.hint,
        autoRotateDelay: 0,
        rotationPerSecond: _rotationPerSecond(mood),
        cameraOrbit: _cameraOrbit(mood),
        minCameraOrbit: 'auto auto 90%',
        maxCameraOrbit: 'auto auto 190%',
        fieldOfView: '28deg',
        minFieldOfView: '20deg',
        maxFieldOfView: '48deg',
        environmentImage: 'neutral',
        exposure: _exposure(backdrop),
        shadowIntensity: 0,
        autoPlay: true,
        animationCrossfadeDuration: 380,
        animationName: _animationName(mood),
        interactionPromptThreshold: 1800,
        relatedCss: '''
          model-viewer {
            width: 100%;
            height: 100%;
            background: transparent;
            --poster-color: transparent;
          }
        ''',
        debugLogging: false,
      ),
    );
  }
}

class _FloorGlow extends StatelessWidget {
  const _FloorGlow({
    required this.primary,
    required this.secondary,
  });

  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.0),
            primary.withValues(alpha: 0.65),
            secondary.withValues(alpha: 0.0),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.35),
            blurRadius: 28,
            spreadRadius: 4,
          ),
        ],
      ),
    );
  }
}

class _HatDecoration extends StatelessWidget {
  const _HatDecoration({
    required this.style,
    required this.color,
  });

  final AssistantHatStyle style;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icon = switch (style) {
      AssistantHatStyle.kubanka => Icons.workspace_premium_rounded,
      AssistantHatStyle.papakha => Icons.terrain_rounded,
      AssistantHatStyle.cap => Icons.sports_baseball_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.34),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, size: 22, color: Colors.white),
    );
  }
}

class _MustacheDecoration extends StatelessWidget {
  const _MustacheDecoration({
    required this.style,
  });

  final AssistantMustacheStyle style;

  @override
  Widget build(BuildContext context) {
    final width = style == AssistantMustacheStyle.handlebar ? 54.0 : 42.0;
    final rotation = style == AssistantMustacheStyle.handlebar ? 0.12 : 0.0;

    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: width,
        height: 14,
        decoration: BoxDecoration(
          color: const Color(0xFF2B1A14).withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessoryDecoration extends StatelessWidget {
  const _AccessoryDecoration({
    required this.accessory,
    required this.accent,
  });

  final AssistantAccessory accessory;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final icon = switch (accessory) {
      AssistantAccessory.sunflower => Icons.local_florist_rounded,
      AssistantAccessory.shashka => Icons.gesture_rounded,
      AssistantAccessory.accordion => Icons.music_note_rounded,
      AssistantAccessory.coffee => Icons.coffee_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(icon, size: 18, color: accent),
    );
  }
}

class _OverlayBadge extends StatelessWidget {
  const _OverlayBadge({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 38,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}

class _AssistantViewTheme {
  const _AssistantViewTheme(this.gradient);

  final Gradient gradient;
}

_AssistantViewTheme _viewTheme(AssistantBackdrop backdrop) {
  return switch (backdrop) {
    AssistantBackdrop.steppe => const _AssistantViewTheme(
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF134E4A), Color(0xFF0F766E), Color(0xFF6EE7B7)],
        ),
      ),
    AssistantBackdrop.confetti => const _AssistantViewTheme(
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D4ED8), Color(0xFF7C3AED), Color(0xFFEC4899)],
        ),
      ),
    AssistantBackdrop.sunset => const _AssistantViewTheme(
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFB923C), Color(0xFFEF4444), Color(0xFF7C2D12)],
        ),
      ),
    AssistantBackdrop.night => const _AssistantViewTheme(
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.backgroundDark,
            Color(0xFF1E293B),
            Color(0xFF4338CA)
          ],
        ),
      ),
  };
}

String? _animationName(KazakAssistantMood mood) => switch (mood) {
      KazakAssistantMood.dance => 'Dance',
      KazakAssistantMood.celebrate => 'Dance',
      KazakAssistantMood.idle => 'Idle',
      KazakAssistantMood.wave => 'Idle',
      KazakAssistantMood.hint => 'Idle',
    };

String _cameraOrbit(KazakAssistantMood mood) => switch (mood) {
      KazakAssistantMood.dance => '15deg 75deg 110%',
      KazakAssistantMood.celebrate => '-8deg 68deg 105%',
      KazakAssistantMood.wave => '28deg 78deg 118%',
      KazakAssistantMood.hint => '-18deg 80deg 120%',
      KazakAssistantMood.idle => '0deg 75deg 115%',
    };

String _rotationPerSecond(KazakAssistantMood mood) => switch (mood) {
      KazakAssistantMood.dance => '42deg',
      KazakAssistantMood.celebrate => '54deg',
      KazakAssistantMood.wave => '18deg',
      KazakAssistantMood.hint => '0deg',
      KazakAssistantMood.idle => '12deg',
    };

double _exposure(AssistantBackdrop backdrop) => switch (backdrop) {
      AssistantBackdrop.steppe => 1.1,
      AssistantBackdrop.confetti => 1.2,
      AssistantBackdrop.sunset => 1.15,
      AssistantBackdrop.night => 1.3,
    };

IconData _moodIcon(KazakAssistantMood mood) => switch (mood) {
      KazakAssistantMood.idle => Icons.self_improvement_rounded,
      KazakAssistantMood.wave => Icons.waving_hand_rounded,
      KazakAssistantMood.dance => Icons.music_note_rounded,
      KazakAssistantMood.celebrate => Icons.celebration_rounded,
      KazakAssistantMood.hint => Icons.tips_and_updates_rounded,
    };

String _moodLabel(KazakAssistantMood mood) => switch (mood) {
      KazakAssistantMood.idle => 'спокоен',
      KazakAssistantMood.wave => 'на связи',
      KazakAssistantMood.dance => 'в танце',
      KazakAssistantMood.celebrate => 'разошёлся',
      KazakAssistantMood.hint => 'советует',
    };
