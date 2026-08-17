import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

void main() {
  group('WaterUnitConverter', () {
    test('converts ml to litres correctly and preserves float precision', () {
      expect(WaterUnitConverter.mlToLitres(2500), 2.5);
      expect(WaterUnitConverter.mlToLitres(1000), 1.0);
      expect(WaterUnitConverter.mlToLitres(3750), 3.75);
    });

    test('converts litres to ml correctly', () {
      expect(WaterUnitConverter.litresToMl(2.5), 2500);
      expect(WaterUnitConverter.litresToMl(1.0), 1000);
    });

    test('converts ml to fluid ounces using 0.033814 factor', () {
      // 2500 ml * 0.033814 = 84.535 oz
      expect(WaterUnitConverter.mlToOz(2500), closeTo(84.535, 0.001));
    });

    test('converts fluid ounces to ml correctly', () {
      // 84.535 / 0.033814 ≈ 2500
      expect(WaterUnitConverter.ozToMl(84.535), 2500);
    });

    test('formats values for display according to unit requirements', () {
      expect(WaterUnitConverter.formatLitres(2500), '2.5');
      expect(WaterUnitConverter.formatLitres(2000), '2.0');
      expect(WaterUnitConverter.formatMl(2500), '2500');
      expect(WaterUnitConverter.formatOz(2500), '85');
    });
  });
}
