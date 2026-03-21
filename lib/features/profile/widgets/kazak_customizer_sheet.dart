import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/assistant_customization.dart';
import '../providers/assistant_provider.dart';
import 'kazak_assistant_view.dart';

class KazakCustomizerSheet extends StatelessWidget {
  const KazakCustomizerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Переодеть казачка',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Экран кастомизации временно отключен. Скоро вернем его в более аккуратном виде.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: KazakAssistantView(
                  customization: const AssistantCustomization(),
                  mood: KazakAssistantMood.idle,
                  size: 220,
                  showLoadout: false,
                  showBadges: false,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.softBorder),
                ),
                child: const Text(
                  'Пока оставили один фиксированный образ, чтобы 3D-модель выглядела стабильнее и не мешала интерфейсу.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Понятно'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
