import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/assistant_customization.dart';
import '../providers/assistant_provider.dart';
import 'kazak_assistant_view.dart';

class KazakCustomizerSheet extends StatefulWidget {
  const KazakCustomizerSheet({
    super.key,
    required this.initialCustomization,
    required this.onSave,
    this.onChanged,
    this.isSaving = false,
  });

  final AssistantCustomization initialCustomization;
  final ValueChanged<AssistantCustomization> onSave;
  final ValueChanged<AssistantCustomization>? onChanged;
  final bool isSaving;

  @override
  State<KazakCustomizerSheet> createState() => _KazakCustomizerSheetState();
}

class _KazakCustomizerSheetState extends State<KazakCustomizerSheet> {
  late AssistantCustomization _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialCustomization;
  }

  void _updateValue(AssistantCustomization nextValue) {
    setState(() => _value = nextValue);
    widget.onChanged?.call(nextValue);
  }

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
                'Собери мемный образ: шапка, усы, аксессуар и фон.',
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
                  customization: _value,
                  mood: KazakAssistantMood.wave,
                  size: 220,
                  showLoadout: false,
                ),
              ),
              const SizedBox(height: 18),
              _CustomizerSection<AssistantCostumeColor>(
                title: 'Костюм',
                values: AssistantCostumeColor.values,
                currentValue: _value.costumeColor,
                labelOf: (value) => value.label,
                onSelected: (value) {
                  _updateValue(_value.copyWith(costumeColor: value));
                },
              ),
              _CustomizerSection<AssistantHatStyle>(
                title: 'Шапка',
                values: AssistantHatStyle.values,
                currentValue: _value.hatStyle,
                labelOf: (value) => value.label,
                onSelected: (value) {
                  _updateValue(_value.copyWith(hatStyle: value));
                },
              ),
              _CustomizerSection<AssistantMustacheStyle>(
                title: 'Усы',
                values: AssistantMustacheStyle.values,
                currentValue: _value.mustacheStyle,
                labelOf: (value) => value.label,
                onSelected: (value) {
                  _updateValue(_value.copyWith(mustacheStyle: value));
                },
              ),
              _CustomizerSection<AssistantAccessory>(
                title: 'Аксессуар',
                values: AssistantAccessory.values,
                currentValue: _value.accessory,
                labelOf: (value) => value.label,
                onSelected: (value) {
                  _updateValue(_value.copyWith(accessory: value));
                },
              ),
              _CustomizerSection<AssistantBackdrop>(
                title: 'Фон',
                values: AssistantBackdrop.values,
                currentValue: _value.backdrop,
                labelOf: (value) => value.label,
                onSelected: (value) {
                  _updateValue(_value.copyWith(backdrop: value));
                },
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      widget.isSaving ? null : () => widget.onSave(_value),
                  icon: widget.isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                      widget.isSaving ? 'Сохраняем образ' : 'Сохранить образ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomizerSection<T> extends StatelessWidget {
  const _CustomizerSection({
    required this.title,
    required this.values,
    required this.currentValue,
    required this.labelOf,
    required this.onSelected,
  });

  final String title;
  final List<T> values;
  final T currentValue;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map((value) {
              final selected = value == currentValue;
              return ChoiceChip(
                label: Text(labelOf(value)),
                selected: selected,
                onSelected: (_) => onSelected(value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
