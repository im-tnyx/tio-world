import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  group('UnitPreferences', () {
    test('metric preset maps to canonical metric preferences', () {
      expect(UnitPreferences.metric.weightUnit, WeightUnit.kg);
      expect(UnitPreferences.metric.heightUnit, HeightUnit.cm);
      expect(UnitPreferences.metric.distanceUnit, DistanceUnit.km);
      expect(UnitPreferences.metric.volumeUnit, VolumeUnit.ml);
    });

    test('imperial preset maps to independent imperial preferences', () {
      expect(UnitPreferences.imperial.weightUnit, WeightUnit.lb);
      expect(UnitPreferences.imperial.heightUnit, HeightUnit.ftIn);
      expect(UnitPreferences.imperial.distanceUnit, DistanceUnit.mi);
      expect(UnitPreferences.imperial.volumeUnit, VolumeUnit.flOz);
    });

    test('mixed preferences remain independently selectable', () {
      final mixed = UnitPreferences.metric.copyWith(
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

    test('serializes mixed preferences into one durable json object', () {
      const mixed = UnitPreferences(
        weightUnit: WeightUnit.kg,
        heightUnit: HeightUnit.ftIn,
        distanceUnit: DistanceUnit.mi,
        volumeUnit: VolumeUnit.ml,
      );

      expect(mixed.toJson(), {
        'weight': 'kg',
        'height': 'ft_in',
        'distance': 'mi',
        'volume': 'ml',
      });
      expect(UnitPreferences.fromJson(mixed.toJson()), mixed);
    });

    test('invalid json values fall back per category to safe metric defaults', () {
      final parsed = UnitPreferences.fromJson({
        'weight': 'stones',
        'height': 'ft_in',
        'distance': null,
        'volume': 'fl_oz',
      });

      expect(parsed.weightUnit, WeightUnit.kg);
      expect(parsed.heightUnit, HeightUnit.ftIn);
      expect(parsed.distanceUnit, DistanceUnit.km);
      expect(parsed.volumeUnit, VolumeUnit.flOz);
      expect(UnitPreferences.fromJson(null), UnitPreferences.metric);
    });

    test('invalid stored unit values fall back to safe metric defaults', () {
      expect(WeightUnit.fromStorage('stones'), WeightUnit.kg);
      expect(HeightUnit.fromStorage('yards'), HeightUnit.cm);
      expect(DistanceUnit.fromStorage('nautical_miles'), DistanceUnit.km);
      expect(VolumeUnit.fromStorage('cups'), VolumeUnit.ml);
      expect(WeightUnit.fromStorage(null), WeightUnit.kg);
      expect(HeightUnit.fromStorage(null), HeightUnit.cm);
      expect(DistanceUnit.fromStorage(null), DistanceUnit.km);
      expect(VolumeUnit.fromStorage(null), VolumeUnit.ml);
    });
  });

  group('UnitConverters', () {
    test('kg and lb roundtrip within tolerance', () {
      const kg = 81.6466;
      expect(
        UnitConverters.lbToKg(UnitConverters.kgToLb(kg)),
        closeTo(kg, 1e-9),
      );
    });

    test('cm and feet/inches roundtrip within display tolerance', () {
      const cm = 180.0;
      final display = UnitConverters.cmToFeetInches(cm);
      final restored = UnitConverters.feetInchesToCm(
        feet: display.feet,
        inches: display.inches,
      );
      expect(restored, closeTo(cm, 1.3));
    });

    test('km and mi roundtrip within tolerance', () {
      const km = 5.0;
      expect(
        UnitConverters.miToKm(UnitConverters.kmToMi(km)),
        closeTo(km, 1e-9),
      );
    });

    test('ml and US fl oz roundtrip within tolerance', () {
      const ml = 2500.0;
      expect(
        UnitConverters.flOzToMl(UnitConverters.mlToFlOz(ml)),
        closeTo(ml, 1e-8),
      );
    });
  });

  group('UnitFormatters', () {
    test('metric volume uses mL below one litre and L above it', () {
      expect(UnitFormatters.formatVolume(750, VolumeUnit.ml), '750 mL');
      expect(UnitFormatters.formatVolume(2500, VolumeUnit.ml), '2.5 L');
    });

    test('height formatter avoids inches rollover bugs', () {
      expect(UnitFormatters.formatHeight(182.88, HeightUnit.ftIn), '6 ft 0 in');
    });
  });
}
