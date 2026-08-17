import 'measurement_units.dart';

class MeasurementUnitPreferences {
  const MeasurementUnitPreferences({
    this.weightUnit = WeightUnit.kg,
    this.heightUnit = HeightUnit.cm,
    this.distanceUnit = DistanceUnit.km,
    this.volumeUnit = VolumeUnit.ml,
  });

  static const metric = MeasurementUnitPreferences();
  static const imperial = MeasurementUnitPreferences(
    weightUnit: WeightUnit.lb,
    heightUnit: HeightUnit.ftIn,
    distanceUnit: DistanceUnit.mi,
    volumeUnit: VolumeUnit.flOz,
  );

  final WeightUnit weightUnit;
  final HeightUnit heightUnit;
  final DistanceUnit distanceUnit;
  final VolumeUnit volumeUnit;

  bool get isMetricPreset => this == metric;
  bool get isImperialPreset => this == imperial;

  /// Canonical account-storage shape used by the Supabase `jsonb` column.
  ///
  /// Presets are intentionally not persisted because mixed preferences are a
  /// first-class state. Each category remains independently selectable.
  Map<String, String> toJson() => <String, String>{
        'weight': weightUnit.storageValue,
        'height': heightUnit.storageValue,
        'distance': distanceUnit.storageValue,
        'volume': volumeUnit.storageValue,
      };

  /// Parses the durable account-storage shape and safely falls back to metric
  /// values when the object or any individual value is missing/corrupt.
  factory MeasurementUnitPreferences.fromJson(Object? value) {
    if (value is! Map) return metric;

    String? readString(String key) {
      final raw = value[key];
      return raw is String ? raw : null;
    }

    return MeasurementUnitPreferences(
      weightUnit: WeightUnit.fromStorage(readString('weight')),
      heightUnit: HeightUnit.fromStorage(readString('height')),
      distanceUnit: DistanceUnit.fromStorage(readString('distance')),
      volumeUnit: VolumeUnit.fromStorage(readString('volume')),
    );
  }

  MeasurementUnitPreferences copyWith({
    WeightUnit? weightUnit,
    HeightUnit? heightUnit,
    DistanceUnit? distanceUnit,
    VolumeUnit? volumeUnit,
  }) {
    return MeasurementUnitPreferences(
      weightUnit: weightUnit ?? this.weightUnit,
      heightUnit: heightUnit ?? this.heightUnit,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      volumeUnit: volumeUnit ?? this.volumeUnit,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasurementUnitPreferences &&
          weightUnit == other.weightUnit &&
          heightUnit == other.heightUnit &&
          distanceUnit == other.distanceUnit &&
          volumeUnit == other.volumeUnit;

  @override
  int get hashCode => Object.hash(
        weightUnit,
        heightUnit,
        distanceUnit,
        volumeUnit,
      );
}
