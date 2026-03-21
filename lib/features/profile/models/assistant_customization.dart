import 'package:flutter/material.dart';

enum AssistantHatStyle {
  kubanka,
  papakha,
  cap,
}

enum AssistantMustacheStyle {
  classic,
  handlebar,
  none,
}

enum AssistantAccessory {
  sunflower,
  shashka,
  accordion,
  coffee,
}

enum AssistantBackdrop {
  steppe,
  confetti,
  sunset,
  night,
}

enum AssistantCostumeColor {
  emerald,
  cobalt,
  cherry,
  amber,
}

class AssistantCustomization {
  const AssistantCustomization({
    this.hatStyle = AssistantHatStyle.kubanka,
    this.mustacheStyle = AssistantMustacheStyle.classic,
    this.accessory = AssistantAccessory.accordion,
    this.backdrop = AssistantBackdrop.confetti,
    this.costumeColor = AssistantCostumeColor.emerald,
  });

  final AssistantHatStyle hatStyle;
  final AssistantMustacheStyle mustacheStyle;
  final AssistantAccessory accessory;
  final AssistantBackdrop backdrop;
  final AssistantCostumeColor costumeColor;

  static const defaults = AssistantCustomization();

  AssistantCustomization copyWith({
    AssistantHatStyle? hatStyle,
    AssistantMustacheStyle? mustacheStyle,
    AssistantAccessory? accessory,
    AssistantBackdrop? backdrop,
    AssistantCostumeColor? costumeColor,
  }) {
    return AssistantCustomization(
      hatStyle: hatStyle ?? this.hatStyle,
      mustacheStyle: mustacheStyle ?? this.mustacheStyle,
      accessory: accessory ?? this.accessory,
      backdrop: backdrop ?? this.backdrop,
      costumeColor: costumeColor ?? this.costumeColor,
    );
  }

  Map<String, dynamic> toMap() => {
        'hatStyle': hatStyle.name,
        'mustacheStyle': mustacheStyle.name,
        'accessory': accessory.name,
        'backdrop': backdrop.name,
        'costumeColor': costumeColor.name,
      };

  factory AssistantCustomization.fromMap(Map<String, dynamic>? map) {
    if (map == null) return defaults;

    return AssistantCustomization(
      hatStyle: _hatFromName(map['hatStyle'] as String?),
      mustacheStyle: _mustacheFromName(map['mustacheStyle'] as String?),
      accessory: _accessoryFromName(map['accessory'] as String?),
      backdrop: _backdropFromName(map['backdrop'] as String?),
      costumeColor: _costumeFromName(map['costumeColor'] as String?),
    );
  }
}

AssistantHatStyle _hatFromName(String? value) {
  return AssistantHatStyle.values.firstWhere(
    (item) => item.name == value,
    orElse: () => AssistantHatStyle.kubanka,
  );
}

AssistantMustacheStyle _mustacheFromName(String? value) {
  return AssistantMustacheStyle.values.firstWhere(
    (item) => item.name == value,
    orElse: () => AssistantMustacheStyle.classic,
  );
}

AssistantAccessory _accessoryFromName(String? value) {
  return AssistantAccessory.values.firstWhere(
    (item) => item.name == value,
    orElse: () => AssistantAccessory.accordion,
  );
}

AssistantBackdrop _backdropFromName(String? value) {
  return AssistantBackdrop.values.firstWhere(
    (item) => item.name == value,
    orElse: () => AssistantBackdrop.confetti,
  );
}

AssistantCostumeColor _costumeFromName(String? value) {
  return AssistantCostumeColor.values.firstWhere(
    (item) => item.name == value,
    orElse: () => AssistantCostumeColor.emerald,
  );
}

extension AssistantCostumePalette on AssistantCostumeColor {
  Color get primary => switch (this) {
        AssistantCostumeColor.emerald => const Color(0xFF0E8F74),
        AssistantCostumeColor.cobalt => const Color(0xFF4263EB),
        AssistantCostumeColor.cherry => const Color(0xFFD6336C),
        AssistantCostumeColor.amber => const Color(0xFFF08C00),
      };

  Color get secondary => switch (this) {
        AssistantCostumeColor.emerald => const Color(0xFF085A49),
        AssistantCostumeColor.cobalt => const Color(0xFF1D4ED8),
        AssistantCostumeColor.cherry => const Color(0xFF9D174D),
        AssistantCostumeColor.amber => const Color(0xFFC2410C),
      };

  String get label => switch (this) {
        AssistantCostumeColor.emerald => 'Изумруд',
        AssistantCostumeColor.cobalt => 'Кобальт',
        AssistantCostumeColor.cherry => 'Вишня',
        AssistantCostumeColor.amber => 'Янтарь',
      };
}

extension AssistantHatStyleLabel on AssistantHatStyle {
  String get label => switch (this) {
        AssistantHatStyle.kubanka => 'Кубанка',
        AssistantHatStyle.papakha => 'Папаха',
        AssistantHatStyle.cap => 'Кепка',
      };
}

extension AssistantMustacheStyleLabel on AssistantMustacheStyle {
  String get label => switch (this) {
        AssistantMustacheStyle.classic => 'Классика',
        AssistantMustacheStyle.handlebar => 'Закрученные',
        AssistantMustacheStyle.none => 'Без усов',
      };
}

extension AssistantAccessoryLabel on AssistantAccessory {
  String get label => switch (this) {
        AssistantAccessory.sunflower => 'Подсолнух',
        AssistantAccessory.shashka => 'Шашка',
        AssistantAccessory.accordion => 'Гармошка',
        AssistantAccessory.coffee => 'Кофе',
      };
}

extension AssistantBackdropLabel on AssistantBackdrop {
  String get label => switch (this) {
        AssistantBackdrop.steppe => 'Степь',
        AssistantBackdrop.confetti => 'Конфетти',
        AssistantBackdrop.sunset => 'Закат',
        AssistantBackdrop.night => 'Ночь',
      };
}
