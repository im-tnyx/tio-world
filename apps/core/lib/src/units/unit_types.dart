enum WeightUnit {
  kg('kg'),
  lb('lb');

  const WeightUnit(this.storageValue);
  final String storageValue;

  static WeightUnit fromStorage(String? value) => values.firstWhere(
        (unit) => unit.storageValue == value,
        orElse: () => WeightUnit.kg,
      );
}

enum HeightUnit {
  cm('cm'),
  ftIn('ft_in');

  const HeightUnit(this.storageValue);
  final String storageValue;

  static HeightUnit fromStorage(String? value) => values.firstWhere(
        (unit) => unit.storageValue == value,
        orElse: () => HeightUnit.cm,
      );
}

enum DistanceUnit {
  km('km'),
  mi('mi');

  const DistanceUnit(this.storageValue);
  final String storageValue;

  static DistanceUnit fromStorage(String? value) => values.firstWhere(
        (unit) => unit.storageValue == value,
        orElse: () => DistanceUnit.km,
      );
}

enum VolumeUnit {
  ml('ml'),
  flOz('fl_oz');

  const VolumeUnit(this.storageValue);
  final String storageValue;

  static VolumeUnit fromStorage(String? value) => values.firstWhere(
        (unit) => unit.storageValue == value,
        orElse: () => VolumeUnit.ml,
      );
}
