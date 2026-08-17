import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  group('MeasurementUnitPreferences', () {
    test('metric preset maps to canonical metric preferences', () {
      expect(MeasurementUnitPreferences.metric.weightUnit, WeightUnit.kg);
      expect(MeasurementUnitPreferences.metric.heightUnit, HeightUnit.cm);
      expect(MeasurementUnitPreferences.metric.distanceUnit, DistanceUnit.km);
      expect(MeasurementUnitPreferences.metric.volumeUnit, VolumeUnit.ml);
    });

    test('imperial preset maps to independent imperial preferences', () {
      expect(MeasurementUnitPreferences.imperial.weightUnit, WeightUnit.lb);
      expect(MeasurementUnitPreferences.imperial.heightUnit, HeightUnit.ftIn);
      expect(MeasurementUnitPreferences.imperial.distanceUnit, DistanceUnit.mi);
      expect(MeasurementUnitPreferences.imperial.volumeUnit, VolumeUnit.flOz);
    });

    test('mixed preferences remain independently selectable', () {
      final mixed = MeasurementUnitPreferences.metric.copyWith(
        heightUnit: HeightUnit.ftIn,
        volumeUnit: VolumeUnit.flOz,
      );
      expect(mixed.weightUnit, WeightUnit.kg);
      expect(mixed.heightUnit, HeightUnit.ftIn);
      expect(mixed.distanceUnit, DistanceUnit.km);
      expect(mixed.volumeUnit, VolumeUnit.flOz);
      expect(mixed.isMetricPreset, isFalse);
      expect(mixed.isImperialPreset, isFalse);
    });
  });

  group('MeasurementConverters', () {
    test('kg and lb roundtrip within tolerance', () {
      const kg = 81.6466;
      expect(
        MeasurementConverters.lbToKg(MeasurementConverters.kgToLb(kg)),
        closeTo(kg, 1e-9),
      );
    });

    test('cm and feet/inches roundtrip within display tolerance', () {
      const cm = 180.0;
      final display = MeasurementConverters.cmToFeetInches(cm);
      final restored = MeasurementConverters.feetInchesToCm(
        feet: display.feet,
        inches: display.inches,
      );
      expect(restored, closeTo(cm, 1.3));
    });

    test('km and mi roundtrip within tolerance', () {
      const km = 5.0;
      expect(
        MeasurementConverters.miToKm(MeasurementConverters.kmToMi(km)),
        closeTo(km, 1e-9),
      );
    });

    test('ml and US fl oz roundtrip within tolerance', () {
      const ml = 2500.0;
      expect(
        MeasurementConverters.flOzToMl(MeasurementConverters.mlToFlOz(ml)),
        closeTo(ml, 1e-8),
      );
    });
  });

  group('MeasurementFormatters', () {
    test('metric volume uses mL below one litre and L above it', () {
      expect(MeasurementFormatters.formatVolume(750, VolumeUnit.ml), '750 mL');
      expect(MeasurementFormatters.formatVolume(2500, VolumeUnit.ml), '2.5 L');
    });

    test('height formatter avoids inches rollover bugs', () {
      expect(MeasurementFormatters.formatHeight(182.88, HeightUnit.ftIn), '6 ft 0 in');
    });
  });
}
