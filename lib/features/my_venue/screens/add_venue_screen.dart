import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/venue.dart';
import '../../../shared/providers/providers.dart';

class AddVenueScreen extends ConsumerStatefulWidget {
  const AddVenueScreen({super.key});

  @override
  ConsumerState<AddVenueScreen> createState() => _AddVenueScreenState();
}

class _AddVenueScreenState extends ConsumerState<AddVenueScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _photoCtrl = TextEditingController();
  final _mapCtrl = TextEditingController();

  VenueType _type = VenueType.restaurant;
  PriceTag _price = PriceTag.mid;
  DistanceTag _distance = DistanceTag.near;
  GroupTag _group = GroupTag.friends;
  final Set<VenueFeature> _features = {};

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addrCtrl.dispose();
    _photoCtrl.dispose();
    _mapCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final addr = _addrCtrl.text.trim();
    if (name.isEmpty || desc.isEmpty || addr.isEmpty) {
      setState(() => _error = 'Заполните название, описание и адрес');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Не авторизован');
      // ignore: avoid_print
      print('>>> [AddVenue] uid=$uid, saving venue...');

      final venue = Venue(
        id: '', // будет заменён Firestore auto-ID
        name: name,
        description: desc,
        address: addr,
        photoUrl: _photoCtrl.text.trim(),
        type: _type,
        distance: _distance,
        group: _group,
        price: _price,
        features: _features.toList(),
        category: _type.name,
        tags: [],
        mapUrl: _mapCtrl.text.trim().isEmpty ? null : _mapCtrl.text.trim(),
      );

      final venueRepo = ref.read(venueRepositoryProvider);
      final profileRepo = ref.read(userProfileRepositoryProvider);

      final venueId = await venueRepo.addVenue(venue, ownerUid: uid);
      // ignore: avoid_print
      print('>>> [AddVenue] venue created: venueId=$venueId');

      await profileRepo.addOwnedVenue(uid, venueId);
      // ignore: avoid_print
      print('>>> [AddVenue] ownedVenueId saved to profile');

      ref.invalidate(userProfileProvider);
      if (mounted) context.go('/my-venue', extra: venueId);
    } catch (e) {
      setState(() => _error = 'Ошибка: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
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
          'Добавить заведение',
          style: TextStyle(
            color: dark ? AppColors.textOnDark : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _card(
            dark: dark,
            card: card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Основное', dark),
                const SizedBox(height: 12),
                _field(_nameCtrl, 'Название', dark),
                const SizedBox(height: 12),
                _field(_descCtrl, 'Описание', dark, maxLines: 3),
                const SizedBox(height: 12),
                _field(_addrCtrl, 'Адрес', dark),
                const SizedBox(height: 12),
                _field(_photoCtrl, 'Ссылка на фото (необязательно)', dark),
                const SizedBox(height: 12),
                _field(_mapCtrl, 'Ссылка на Яндекс.Карты (необязательно)', dark),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            dark: dark,
            card: card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Тип заведения', dark),
                const SizedBox(height: 10),
                _enumChips<VenueType>(
                  values: VenueType.values,
                  selected: _type,
                  label: _venueTypeLabel,
                  onSelected: (v) => setState(() => _type = v),
                  dark: dark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            dark: dark,
            card: card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Цена', dark),
                const SizedBox(height: 10),
                _enumChips<PriceTag>(
                  values: PriceTag.values,
                  selected: _price,
                  label: _priceLabel,
                  onSelected: (v) => setState(() => _price = v),
                  dark: dark,
                ),
                const SizedBox(height: 16),
                _sectionTitle('Расстояние от центра', dark),
                const SizedBox(height: 10),
                _enumChips<DistanceTag>(
                  values: DistanceTag.values,
                  selected: _distance,
                  label: _distanceLabel,
                  onSelected: (v) => setState(() => _distance = v),
                  dark: dark,
                ),
                const SizedBox(height: 16),
                _sectionTitle('Подходит для', dark),
                const SizedBox(height: 10),
                _enumChips<GroupTag>(
                  values: GroupTag.values,
                  selected: _group,
                  label: _groupLabel,
                  onSelected: (v) => setState(() => _group = v),
                  dark: dark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            dark: dark,
            card: card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Особенности (можно несколько)', dark),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: VenueFeature.values.map((f) {
                    final selected = _features.contains(f);
                    return FilterChip(
                      label: Text(_featureLabel(f)),
                      selected: selected,
                      onSelected: (_) => setState(() {
                        if (selected) {
                          _features.remove(f);
                        } else {
                          _features.add(f);
                        }
                      }),
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: selected
                            ? AppColors.primary
                            : (dark ? AppColors.textMutedOnDark : AppColors.textSecondary),
                        fontSize: 13,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Сохранить заведение',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
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

  Widget _sectionTitle(String title, bool dark) => Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: dark ? AppColors.textMutedOnDark : AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      );

  Widget _field(
    TextEditingController ctrl,
    String hint,
    bool dark, {
    int maxLines = 1,
  }) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: TextStyle(
          color: dark ? AppColors.textOnDark : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: dark ? AppColors.textMutedOnDark : AppColors.textSecondary,
            fontSize: 14,
          ),
          filled: true,
          fillColor: dark
              ? Colors.white.withValues(alpha: 0.05)
              : AppColors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );

  Widget _enumChips<T>({
    required List<T> values,
    required T selected,
    required String Function(T) label,
    required void Function(T) onSelected,
    required bool dark,
  }) =>
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: values.map((v) {
          final isSelected = v == selected;
          return ChoiceChip(
            label: Text(label(v)),
            selected: isSelected,
            onSelected: (_) => onSelected(v),
            selectedColor: AppColors.primary.withValues(alpha: 0.2),
            labelStyle: TextStyle(
              color: isSelected
                  ? AppColors.primary
                  : (dark ? AppColors.textMutedOnDark : AppColors.textSecondary),
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          );
        }).toList(),
      );

  String _venueTypeLabel(VenueType t) => switch (t) {
        VenueType.restaurant => 'Ресторан',
        VenueType.cafe => 'Кафе',
        VenueType.park => 'Парк',
        VenueType.museum => 'Музей',
        VenueType.temple => 'Храм',
        VenueType.bar => 'Бар',
        VenueType.spa => 'СПА',
        VenueType.sport => 'Спорт',
        VenueType.attraction => 'Достопримечательность',
        VenueType.embankment => 'Набережная',
        VenueType.mall => 'ТЦ',
        VenueType.theater => 'Театр',
      };

  String _priceLabel(PriceTag p) => switch (p) {
        PriceTag.budget => 'Бюджетно',
        PriceTag.mid => 'Средне',
        PriceTag.premium => 'Премиум',
      };

  String _distanceLabel(DistanceTag d) => switch (d) {
        DistanceTag.near => 'Центр (<3 км)',
        DistanceTag.medium => 'Средне (3–15 км)',
        DistanceTag.far => 'Далеко (>15 км)',
      };

  String _groupLabel(GroupTag g) => switch (g) {
        GroupTag.solo => 'Один',
        GroupTag.couple => 'Пара',
        GroupTag.friends => 'Друзья',
        GroupTag.family => 'Семья',
        GroupTag.largeGroup => 'Большая группа',
      };

  String _featureLabel(VenueFeature f) => switch (f) {
        VenueFeature.kids => 'Дети',
        VenueFeature.christian => 'Духовное',
        VenueFeature.sport => 'Спорт',
        VenueFeature.romantic => 'Романтика',
        VenueFeature.outdoor => 'На улице',
        VenueFeature.alcohol => 'Алкоголь',
        VenueFeature.vegetarian => 'Вегетарианское',
        VenueFeature.quiet => 'Тихо',
        VenueFeature.lively => 'Шумно',
        VenueFeature.cultural => 'Культура',
        VenueFeature.historical => 'История',
        VenueFeature.nature => 'Природа',
      };
}
