import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/venue.dart';

class VenueMapIconButton extends StatelessWidget {
  const VenueMapIconButton({
    super.key,
    required this.venue,
    this.size = 34,
  });

  final Venue venue;
  final double size;

  @override
  Widget build(BuildContext context) {
    final rawUrl = venue.mapUrl?.trim();
    if (rawUrl == null || rawUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: 'Открыть на карте',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size * 0.38),
          onTap: () => openVenueMap(context, venue),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(size * 0.38),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.softBorder,
              ),
            ),
            child: Icon(
              Icons.map_outlined,
              size: size * 0.46,
              color: isDark ? AppColors.textOnDark : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> openVenueMap(BuildContext context, Venue venue) async {
  final rawUrl = venue.mapUrl?.trim();
  if (rawUrl == null || rawUrl.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Для этого места ссылка на карту пока не заведена.'),
      ),
    );
    return;
  }

  final uri = Uri.tryParse(rawUrl);
  if (uri == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ссылка на карту выглядит кривовато.'),
      ),
    );
    return;
  }

  if (await canLaunchUrl(uri)) {
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    return;
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Не удалось открыть Яндекс Карты на этом устройстве.'),
      ),
    );
  }
}
