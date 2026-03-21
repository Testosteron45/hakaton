import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/models/venue.dart';
import '../../../shared/providers/providers.dart';
import '../../../data/repositories/venue_repository.dart' show VenueStats;
import '../widgets/kazak_assistant_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final profileAsync = ref.watch(userProfileProvider);
    final venues = ref.watch(venueRepositoryProvider).getAll();

    final profile = profileAsync.valueOrNull;
    final insights = _ProfileInsights.from(
      userName: user?.displayName ?? user?.email?.split('@').first ?? 'Гость',
      email: user?.email ?? 'Без email',
      createdAt: user?.metadata.creationTime,
      profile: profile,
      venues: venues,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    _TopButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => context.pop(),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Профиль',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const _ThemeToggleButton(),
                    const SizedBox(width: 10),
                    _TopButton(
                      icon: Icons.logout_rounded,
                      onTap: () async {
                        await ref.read(authProvider).signOut();
                        if (context.mounted) context.go('/auth');
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _ProfileHero(insights: insights),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: KazakAssistantCard(),
              ),
            ),
            if (profileAsync.isLoading) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              const SliverToBoxAdapter(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 22)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SectionTitle(
                  title: 'Твоя статистика',
                  subtitle:
                      'Коротко и по делу о том, что тебе реально подходит.',
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate.fixed([
                  _StatCard(
                    label: 'Дней в приложении',
                    value: '${insights.daysInApp}',
                    icon: Icons.timelapse_rounded,
                    accent: AppColors.primary,
                  ),
                  _StatCard(
                    label: 'Мест под твой вайб',
                    value: '${insights.matchedCount}',
                    icon: Icons.auto_awesome_rounded,
                    accent: AppColors.secondary,
                  ),
                  _StatCard(
                    label: 'Рядом с тобой',
                    value: '${insights.nearbyCount}',
                    icon: Icons.near_me_rounded,
                    accent: AppColors.accent,
                  ),
                  _StatCard(
                    label: 'Любимых форматов',
                    value: '${insights.typeCount}',
                    icon: Icons.grid_view_rounded,
                    accent: AppColors.success,
                  ),
                ]),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.16,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 22)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SectionTitle(
                  title: 'Портрет вкуса',
                  subtitle: insights.vibeSubtitle,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _TasteCard(insights: insights),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 22)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SectionTitle(
                  title: 'Что зайдет прямо сейчас',
                  subtitle: 'Небольшая выжимка по твоим лучшим сценариям.',
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  for (final item in insights.highlights)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _HighlightCard(item: item),
                    ),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/onboarding'),
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Перенастроить интересы'),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SectionTitle(
                  title: 'Моё заведение',
                  subtitle: 'Добавьте своё место и смотрите, как на него реагируют.',
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: _MyVenueSection(
                  onAdd: () => context.push('/add-venue'),
                  onTap: (id) => context.push('/my-venue', extra: id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.insights});

  final _ProfileInsights insights;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.secondary
          ],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  insights.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insights.userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insights.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            insights.vibeTitle,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            insights.vibeDescription,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.84),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.softBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _TasteCard extends StatelessWidget {
  const _TasteCard({required this.insights});

  final _ProfileInsights insights;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.softBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ProfileChip(
                icon: Icons.group_rounded,
                label: insights.groupLabel,
                accent: AppColors.primary,
              ),
              for (final type in insights.typeLabels)
                _ProfileChip(
                  icon: _typeIcon(type.$1),
                  label: type.$2,
                  accent: AppColors.secondary,
                ),
              for (final feature in insights.featureLabels)
                _ProfileChip(
                  icon: Icons.auto_awesome_rounded,
                  label: feature,
                  accent: AppColors.accent,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              insights.matchSummary,
              style: TextStyle(
                fontSize: 14,
                height: 1.55,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isDark
            ? accent.withValues(alpha: 0.18)
            : accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.item});

  final _ProfileHighlight item;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.softBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: item.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(item.icon, color: item.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).textTheme.bodyMedium?.color,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _TopButton extends StatelessWidget {
  const _TopButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.softBorder,
          ),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface,
          size: 20,
        ),
      ),
    );
  }
}

class _ThemeToggleButton extends ConsumerWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Semantics(
      button: true,
      label: isDark ? 'Включить светлую тему' : 'Включить тёмную тему',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => ref.read(themeModeProvider.notifier).toggle(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 74,
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.softBorder,
              ),
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.light_mode_rounded,
                      size: 16,
                      color: isDark
                          ? Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5)
                          : AppColors.primary,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.dark_mode_rounded,
                      size: 16,
                      color: isDark
                          ? AppColors.primary
                          : Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                AnimatedAlign(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment:
                      isDark ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.28),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileInsights {
  const _ProfileInsights({
    required this.userName,
    required this.email,
    required this.initials,
    required this.daysInApp,
    required this.matchedCount,
    required this.nearbyCount,
    required this.typeCount,
    required this.groupLabel,
    required this.typeLabels,
    required this.featureLabels,
    required this.vibeTitle,
    required this.vibeSubtitle,
    required this.vibeDescription,
    required this.matchSummary,
    required this.highlights,
  });

  final String userName;
  final String email;
  final String initials;
  final int daysInApp;
  final int matchedCount;
  final int nearbyCount;
  final int typeCount;
  final String groupLabel;
  final List<(VenueType, String)> typeLabels;
  final List<String> featureLabels;
  final String vibeTitle;
  final String vibeSubtitle;
  final String vibeDescription;
  final String matchSummary;
  final List<_ProfileHighlight> highlights;

  factory _ProfileInsights.from({
    required String userName,
    required String email,
    required DateTime? createdAt,
    required UserProfile? profile,
    required List<Venue> venues,
  }) {
    final preferredTypes = profile?.preferredTypes ?? <VenueType>[];
    final group = profile?.defaultGroup;

    final matched = venues.where((venue) {
      final typeMatch =
          preferredTypes.isEmpty ? true : preferredTypes.contains(venue.type);
      final groupMatch = group == null ? true : venue.group == group;
      return typeMatch && groupMatch;
    }).toList();

    final effectiveMatches = matched.isEmpty ? venues : matched;
    final nearbyCount =
        effectiveMatches.where((v) => v.distance == DistanceTag.near).length;

    final featureCounts = <VenueFeature, int>{};
    for (final venue in effectiveMatches) {
      for (final feature in venue.features) {
        featureCounts.update(feature, (count) => count + 1, ifAbsent: () => 1);
      }
    }

    final topFeatures = featureCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final featureLabels = topFeatures
        .take(3)
        .map((entry) => _featureLabel(entry.key))
        .whereType<String>()
        .toList();

    final typeLabels = preferredTypes.isEmpty
        ? effectiveMatches
            .map((venue) => venue.type)
            .toSet()
            .take(3)
            .map((type) => (type, _typeLabel(type)))
            .toList()
        : preferredTypes
            .take(3)
            .map((type) => (type, _typeLabel(type)))
            .toList();

    final daysRaw =
        createdAt == null ? 1 : DateTime.now().difference(createdAt).inDays + 1;
    final daysInApp = daysRaw < 1 ? 1 : daysRaw;

    final initials = userName.trim().isEmpty
        ? 'G'
        : userName
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((part) => part.substring(0, 1).toUpperCase())
            .join();

    final vibeTitle = _vibeTitle(preferredTypes, group);
    final vibeSubtitle = preferredTypes.isEmpty
        ? 'Пока профиль строится по общему поведению и базовой географии мест.'
        : 'Твой подбор тяготеет к понятным форматам и местам, где совпадает настроение.';
    final vibeDescription =
        _vibeDescription(preferredTypes, group, nearbyCount);

    final matchedCount = effectiveMatches.length;
    final formatsLabel = typeLabels.isEmpty
        ? 'разные городские форматы'
        : typeLabels.map((item) => item.$2).join(', ');
    final matchSummary =
        'Сейчас для тебя доступно $matchedCount мест, из них $nearbyCount находятся рядом. '
        'Лучше всего система видит сценарии в формате: $formatsLabel.';

    final highlights = [
      _ProfileHighlight(
        title: 'Лучший сценарий',
        subtitle:
            '${group == null ? 'Универсальный формат' : _groupLabel(group)} + ${typeLabels.isEmpty ? 'новые места' : typeLabels.first.$2.toLowerCase()}',
        icon: Icons.bolt_rounded,
        accent: AppColors.primary,
      ),
      _ProfileHighlight(
        title: 'Быстрый выход',
        subtitle: nearbyCount == 0
            ? 'Нужно расширить вкус, чтобы видеть больше мест рядом.'
            : '$nearbyCount вариантов можно рассмотреть без долгой дороги.',
        icon: Icons.route_rounded,
        accent: AppColors.accent,
      ),
      _ProfileHighlight(
        title: 'Атмосфера',
        subtitle: featureLabels.isEmpty
            ? 'Пока мало сигналов, но профиль уже можно усиливать новыми свайпами.'
            : 'Твой профиль чаще всего тянется к атмосфере: ${featureLabels.join(', ').toLowerCase()}.',
        icon: Icons.nightlife_rounded,
        accent: AppColors.secondary,
      ),
    ];

    return _ProfileInsights(
      userName: userName,
      email: email,
      initials: initials,
      daysInApp: daysInApp,
      matchedCount: matchedCount,
      nearbyCount: nearbyCount,
      typeCount: typeLabels.length,
      groupLabel: group == null ? 'Свободный формат' : _groupLabel(group),
      typeLabels: typeLabels,
      featureLabels: featureLabels,
      vibeTitle: vibeTitle,
      vibeSubtitle: vibeSubtitle,
      vibeDescription: vibeDescription,
      matchSummary: matchSummary,
      highlights: highlights,
    );
  }
}

class _ProfileHighlight {
  const _ProfileHighlight({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
}

String _vibeTitle(List<VenueType> types, GroupTag? group) {
  if (types.contains(VenueType.restaurant) || types.contains(VenueType.cafe)) {
    return 'Гастро-исследователь';
  }
  if (types.contains(VenueType.park) ||
      types.contains(VenueType.sport) ||
      types.contains(VenueType.embankment)) {
    return 'Любитель живого города';
  }
  if (types.contains(VenueType.museum) ||
      types.contains(VenueType.theater) ||
      types.contains(VenueType.temple)) {
    return 'Спокойный эстет';
  }
  if (group == GroupTag.family || group == GroupTag.largeGroup) {
    return 'Организатор впечатлений';
  }
  return 'Охотник за новыми местами';
}

String _vibeDescription(
  List<VenueType> types,
  GroupTag? group,
  int nearbyCount,
) {
  final groupPart =
      group == null ? 'под разное настроение' : _groupLabel(group);
  final typePart =
      types.isEmpty ? 'разные городские форматы' : _typeLabel(types.first);
  return 'Твой профиль собран вокруг сценария "$groupPart" и формата "$typePart". '
      'Сейчас система видит $nearbyCount удобных вариантов рядом, так что подбор можно открыть и быстро найти что-то в касание.';
}

String _groupLabel(GroupTag group) => switch (group) {
      GroupTag.solo => 'Соло',
      GroupTag.couple => 'Вдвоём',
      GroupTag.friends => 'С друзьями',
      GroupTag.family => 'С семьёй',
      GroupTag.largeGroup => 'Большой компанией',
    };

String _typeLabel(VenueType type) => switch (type) {
      VenueType.restaurant => 'Рестораны',
      VenueType.cafe => 'Кафе',
      VenueType.park => 'Парки',
      VenueType.museum => 'Музеи',
      VenueType.temple => 'Храмы',
      VenueType.bar => 'Бары',
      VenueType.spa => 'Спа',
      VenueType.sport => 'Спорт',
      VenueType.attraction => 'Развлечения',
      VenueType.embankment => 'Прогулки',
      VenueType.mall => 'Шопинг',
      VenueType.theater => 'Театры',
    };

String? _featureLabel(VenueFeature feature) => switch (feature) {
      VenueFeature.kids => 'С детьми',
      VenueFeature.christian => 'Спокойствие',
      VenueFeature.sport => 'Активность',
      VenueFeature.romantic => 'Романтика',
      VenueFeature.outdoor => 'Свежий воздух',
      VenueFeature.alcohol => 'Вечерний вайб',
      VenueFeature.vegetarian => 'Лёгкая еда',
      VenueFeature.quiet => 'Тихая атмосфера',
      VenueFeature.lively => 'Живой ритм',
      VenueFeature.cultural => 'Культура',
      VenueFeature.historical => 'История',
      VenueFeature.nature => 'Природа',
    };

class _AddVenueTile extends StatelessWidget {
  const _AddVenueTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.softBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add_business_rounded,
                  color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Добавить своё заведение',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Оно появится в свайп-сессиях и вы\nувидите реакцию пользователей',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _MyVenueSection extends ConsumerWidget {
  const _MyVenueSection({required this.onAdd, required this.onTap});
  final VoidCallback onAdd;
  final void Function(String venueId) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(ownedVenueStatsProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final ids = profile?.ownedVenueIds ?? [];

    return Column(
      children: [
        // One tile per venue
        ...statsAsync.when(
          loading: () => ids.map((id) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _VenueStatsTile(
                  stats: null,
                  venueId: id,
                  onTap: () => onTap(id),
                ),
              )),
          error: (_, __) => [],
          data: (statsList) => List.generate(ids.length, (i) {
            final id = ids[i];
            final stats = i < statsList.length ? statsList[i] : null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _VenueStatsTile(
                stats: stats,
                venueId: id,
                onTap: () => onTap(id),
              ),
            );
          }),
        ),
        // Always show Add button
        _AddVenueTile(onTap: onAdd),
      ],
    );
  }
}

class _VenueStatsTile extends StatelessWidget {
  const _VenueStatsTile({
    required this.stats,
    required this.venueId,
    required this.onTap,
  });
  final VenueStats? stats;
  final String venueId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.12),
              AppColors.secondary.withValues(alpha: isDark ? 0.2 : 0.07),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storefront_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    stats?.name ?? '...',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const Icon(Icons.bar_chart_rounded,
                    color: AppColors.primary, size: 20),
              ],
            ),
            if (stats != null) ...[
              const SizedBox(height: 12),
              if (stats!.impressions == 0)
                Text(
                  'Ещё не попало в сессии',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                )
              else
                Row(
                  children: [
                    _mini(context, '${stats!.impressions}',
                        Icons.visibility_rounded, AppColors.secondary),
                    const SizedBox(width: 12),
                    _mini(context, '${stats!.likes}',
                        Icons.thumb_up_rounded, AppColors.success),
                    const SizedBox(width: 12),
                    _mini(context, '${stats!.dislikes}',
                        Icons.thumb_down_rounded, AppColors.error),
                    const Spacer(),
                    Text(
                      '${(stats!.likeRate * 100).toStringAsFixed(0)}% 👍',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: stats!.likeRate >= 0.7
                            ? AppColors.success
                            : stats!.likeRate >= 0.4
                                ? AppColors.accent
                                : AppColors.error,
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _mini(BuildContext ctx, String v, IconData icon, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(v,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(ctx).colorScheme.onSurface)),
        ],
      );
}

IconData _typeIcon(VenueType type) => switch (type) {
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
