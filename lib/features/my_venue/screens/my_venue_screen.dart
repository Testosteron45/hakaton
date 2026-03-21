import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/venue_repository.dart';
import '../../../shared/providers/providers.dart';

class MyVenueScreen extends ConsumerStatefulWidget {
  const MyVenueScreen({super.key, this.venueId});

  /// Passed directly from AddVenueScreen to avoid waiting for provider reload.
  final String? venueId;

  @override
  ConsumerState<MyVenueScreen> createState() => _MyVenueScreenState();
}

class _MyVenueScreenState extends ConsumerState<MyVenueScreen> {
  VenueStats? _stats;
  bool _loading = true;
  bool _deleting = false;
  String? _error;
  String? _resolvedVenueId;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Prefer venueId passed via route, fallback to profile
      String? venueId = widget.venueId;
      if (venueId == null) {
        final profile = await ref.read(userProfileProvider.future);
        venueId = profile?.ownedVenueIds.isNotEmpty == true
            ? profile!.ownedVenueIds.first
            : null;
      }
      if (venueId == null) {
        setState(() {
          _error = 'Заведение не найдено';
          _loading = false;
        });
        return;
      }
      _resolvedVenueId = venueId;
      final stats =
          await ref.read(venueRepositoryProvider).loadVenueStats(venueId);
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки: $e';
        _loading = false;
      });
    }
  }

  Future<void> _confirmAndDelete() async {
    final venueId = _resolvedVenueId;
    if (venueId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Удалить заведение?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Заведение будет удалено из Firestore и больше не будет появляться в свайп-сессиях. Статистика также будет потеряна.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text(
              'Удалить',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await ref.read(venueRepositoryProvider).deleteVenue(venueId);
      if (uid != null) {
        await ref.read(userProfileRepositoryProvider).removeOwnedVenue(uid, venueId);
      }
      ref.invalidate(userProfileProvider);
      ref.invalidate(ownedVenueStatsProvider);
      if (mounted) context.go('/profile');
    } catch (e) {
      setState(() {
        _deleting = false;
        _error = 'Ошибка удаления: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? AppColors.backgroundDark : AppColors.background;
    final card = dark ? AppColors.surfaceDark : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: dark ? AppColors.textOnDark : AppColors.textPrimary),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/profile'),
        ),
        title: Text(
          'Моё заведение',
          style: TextStyle(
            color: dark ? AppColors.textOnDark : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                color: dark ? AppColors.textMutedOnDark : AppColors.textSecondary),
            onPressed: _loading ? null : _loadStats,
            tooltip: 'Обновить',
          ),
          if (_resolvedVenueId != null)
            IconButton(
              icon: _deleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.error),
                    )
                  : const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error),
              onPressed: _deleting ? null : _confirmAndDelete,
              tooltip: 'Удалить заведение',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError(dark)
              : _buildContent(dark, card),
    );
  }

  Widget _buildError(bool dark) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48,
                  color: dark ? AppColors.textMutedOnDark : AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(
                  color: dark ? AppColors.textMutedOnDark : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _buildContent(bool dark, Color card) {
    final stats = _stats;
    final hasData = stats != null && stats.impressions > 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // Header card
        if (stats != null)
          _headerCard(stats.name, dark, card),
        const SizedBox(height: 12),

        if (!hasData)
          _emptyState(dark, card)
        else ...[
          // Summary stats
          _statsRow(dark, card, stats),
          const SizedBox(height: 12),
          // Like rate
          _likeRateCard(dark, card, stats),
          const SizedBox(height: 12),
          // Mode breakdown
          if (stats.modeStats.isNotEmpty)
            _modeStatsCard(dark, card, stats),
        ],
      ],
    );
  }

  Widget _headerCard(String name, bool dark, Color card) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.storefront_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Ваше заведение',
                    style: TextStyle(
                      color: AppColors.glassStrong,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _emptyState(bool dark, Color card) => _card(
        dark: dark,
        card: card,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Icon(Icons.bar_chart_rounded,
                size: 48,
                color: dark ? AppColors.textMutedOnDark : AppColors.outline),
            const SizedBox(height: 12),
            Text(
              'Статистика ещё не накопилась',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: dark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Как только пользователи начнут свайпать\nваше заведение — здесь появятся данные',
              style: TextStyle(
                fontSize: 13,
                color: dark ? AppColors.textMutedOnDark : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
        ),
      );

  Widget _statsRow(bool dark, Color card, VenueStats stats) => Row(
        children: [
          Expanded(
            child: _statTile(
              icon: Icons.visibility_rounded,
              iconColor: AppColors.secondary,
              value: '${stats.impressions}',
              label: 'Показов',
              dark: dark,
              card: card,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statTile(
              icon: Icons.thumb_up_rounded,
              iconColor: AppColors.success,
              value: '${stats.likes}',
              label: 'Лайков',
              dark: dark,
              card: card,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statTile(
              icon: Icons.thumb_down_rounded,
              iconColor: AppColors.error,
              value: '${stats.dislikes}',
              label: 'Дизлайков',
              dark: dark,
              card: card,
            ),
          ),
        ],
      );

  Widget _statTile({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required bool dark,
    required Color card,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.softBorder,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: dark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: dark ? AppColors.textMutedOnDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );

  Widget _likeRateCard(bool dark, Color card, VenueStats stats) {
    final rate = stats.likeRate;
    final pct = (rate * 100).toStringAsFixed(0);
    final color = rate >= 0.7
        ? AppColors.success
        : rate >= 0.4
            ? AppColors.accent
            : AppColors.error;

    return _card(
      dark: dark,
      card: card,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Рейтинг одобрения',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: dark ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: rate,
                    minHeight: 8,
                    backgroundColor: dark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppColors.softBorder,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$pct%',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 28,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeStatsCard(bool dark, Color card, VenueStats stats) {
    final modeNames = <String, String>{
      'normal': 'Обычный',
      'bigFamily': 'Семейный',
      'romantic': 'Романтика',
      'budget': 'Бюджетно',
      'active': 'Активный',
      'foodie': 'Гастрономия',
      'christian': 'Духовный',
    };

    final entries = stats.modeStats.entries
        .where((e) => (e.value['likes'] ?? 0) + (e.value['dislikes'] ?? 0) > 0)
        .toList()
      ..sort((a, b) {
        final aL = a.value['likes'] ?? 0;
        final bL = b.value['likes'] ?? 0;
        return bL.compareTo(aL);
      });

    return _card(
      dark: dark,
      card: card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'По режимам сессий',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: dark ? AppColors.textOnDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...entries.map((e) {
            final likes = e.value['likes'] ?? 0;
            final dislikes = e.value['dislikes'] ?? 0;
            final total = likes + dislikes;
            final rate = total == 0 ? 0.0 : likes / total;
            final modeName = modeNames[e.key] ?? e.key;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(
                      modeName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: dark
                            ? AppColors.textOnDark
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: rate,
                        minHeight: 6,
                        backgroundColor: dark
                            ? Colors.white.withValues(alpha: 0.08)
                            : AppColors.softBorder,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${likes}👍 ${dislikes}👎',
                    style: TextStyle(
                      fontSize: 12,
                      color: dark
                          ? AppColors.textMutedOnDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _card({
    required bool dark,
    required Color card,
    required Widget child,
  }) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: dark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.softBorder,
          ),
        ),
        child: child,
      );
}
