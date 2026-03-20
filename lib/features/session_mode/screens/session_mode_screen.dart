import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/swipe_session.dart';

class SessionModeScreen extends ConsumerWidget {
  const SessionModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? user?.email?.split('@').first ?? 'Гость';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Привет, $name! 👋',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Куда хочешь сходить сегодня?',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Обычная сессия',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ModeCard(
                      mode: SessionMode.normal,
                      onTap: () => _startSession(context, SessionMode.normal),
                      featured: true,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Тематические сессии',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate([
                  for (final mode in SessionMode.values.skip(1))
                    _ModeCard(
                      mode: mode,
                      onTap: () => _startSession(context, mode),
                    ),
                ]),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  void _startSession(BuildContext context, SessionMode mode) {
    context.push('/session', extra: mode);
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.onTap,
    this.featured = false,
  });

  final SessionMode mode;
  final VoidCallback onTap;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(featured ? 20 : 16),
        decoration: BoxDecoration(
          gradient: featured
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.secondary],
                )
              : null,
          color: featured ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: featured
            ? Row(
                children: [
                  Text(
                    mode.emoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mode.label,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mode.description,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.white70, size: 16),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mode.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  Text(
                    mode.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mode.description,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
      ),
    );
  }
}
