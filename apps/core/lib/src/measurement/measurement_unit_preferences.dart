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
