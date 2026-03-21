import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/models/venue.dart';
import '../../profile/models/assistant_customization.dart';
import '../../../shared/providers/providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  GroupTag _selectedGroup = GroupTag.friends;
  final Set<VenueType> _selectedTypes = {};

  bool _saving = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_page < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final user = ref.read(authProvider).currentUser;

    try {
      if (user != null) {
        final existing = await ref
            .read(userProfileRepositoryProvider)
            .load(user.uid)
            .timeout(const Duration(seconds: 4), onTimeout: () => null);
        final profile = UserProfile(
          uid: user.uid,
          name: user.displayName ?? user.email?.split('@').first ?? 'Гость',
          preferredTypes: _selectedTypes.toList(),
          defaultGroup: _selectedGroup,
          assistantCustomization: existing?.assistantCustomization ??
              AssistantCustomization.defaults,
        );
        await ref
            .read(userProfileRepositoryProvider)
            .save(profile)
            .timeout(const Duration(seconds: 4));
      }
    } catch (_) {
      // Best-effort save: let the user continue even if Firestore is slow.
    }

    if (mounted) context.go('/modes');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [AppColors.backgroundDark, Color(0xFF111827)]
                : const [Color(0xFFEFF7F5), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryDark,
                        AppColors.primary,
                        AppColors.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Настроим подбор под тебя',
                        style: textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Два быстрых шага, чтобы рекомендации были точнее уже с первой сессии.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: List.generate(2, (i) {
                          final active = i <= _page;
                          return Expanded(
                            child: Container(
                              height: 8,
                              margin: EdgeInsets.only(right: i == 1 ? 0 : 8),
                              decoration: BoxDecoration(
                                color: active
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : AppColors.softBorder,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.16 : 0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (i) => setState(() => _page = i),
                      children: [
                        _GroupPage(
                          selected: _selectedGroup,
                          onChanged: (g) => setState(() => _selectedGroup = g),
                        ),
                        _TypesPage(
                          selected: _selectedTypes,
                          onToggle: (t) => setState(() {
                            if (_selectedTypes.contains(t)) {
                              _selectedTypes.remove(t);
                            } else {
                              _selectedTypes.add(t);
                            }
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _nextPage,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(_page == 1 ? 'Готово' : 'Далее'),
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

// ── Page 1: With whom? ────────────────────────────────────────────────────────

class _GroupPage extends StatelessWidget {
  const _GroupPage({required this.selected, required this.onChanged});

  final GroupTag selected;
  final ValueChanged<GroupTag> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = [
      (GroupTag.solo, '🧍', 'Один(а)'),
      (GroupTag.couple, '👫', 'Вдвоём'),
      (GroupTag.friends, '👥', 'Компания'),
      (GroupTag.family, '👨‍👩‍👧', 'Семья'),
      (GroupTag.largeGroup, '🎉', 'Большая группа'),
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'С кем планируете?',
                  style: textTheme.headlineMedium?.copyWith(fontSize: 30),
                ),
                const SizedBox(height: 8),
                Text(
                  'Это поможет нам подобрать подходящие места',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ...options.map((o) {
                  final (tag, emoji, label) = o;
                  final isSelected = selected == tag;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => onChanged(tag),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : AppColors.surfaceVariant),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : AppColors.softBorder),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.white),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 21),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                label,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.primary
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Page 2: Preferred types ───────────────────────────────────────────────────

class _TypesPage extends StatelessWidget {
  const _TypesPage({required this.selected, required this.onToggle});

  final Set<VenueType> selected;
  final ValueChanged<VenueType> onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = [
      (VenueType.restaurant, '🍽️', 'Рестораны'),
      (VenueType.cafe, '☕', 'Кафе'),
      (VenueType.park, '🌳', 'Парки'),
      (VenueType.museum, '🏛️', 'Музеи'),
      (VenueType.temple, '⛪', 'Храмы'),
      (VenueType.bar, '🍺', 'Бары'),
      (VenueType.spa, '🧖', 'Спа'),
      (VenueType.sport, '⚽', 'Спорт'),
      (VenueType.theater, '🎭', 'Театры'),
      (VenueType.attraction, '🎡', 'Аттракционы'),
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Что вам интересно?',
                style: textTheme.headlineMedium?.copyWith(fontSize: 30),
              ),
              const SizedBox(height: 8),
              Text(
                'Выберите одно или несколько',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 180,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        mainAxisExtent: 132,
                      ),
                  itemCount: options.length,
                  itemBuilder: (_, i) {
                    final (type, emoji, label) = options[i];
                    final isSelected = selected.contains(type);
                    return GestureDetector(
                      onTap: () => onToggle(type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : AppColors.surfaceVariant),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : AppColors.softBorder),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.16)
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.white),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium?.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                fontSize: 15,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isSelected ? 'Выбрано' : 'Нажми, чтобы выбрать',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                fontSize: 11.5,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
