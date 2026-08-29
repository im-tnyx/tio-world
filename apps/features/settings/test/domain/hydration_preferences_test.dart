import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_settings/settings.dart';

void main() {
  for (final value in [50, 200, 250, 260, 500, 750, 2000]) {
    test('canonical Glass Size accepts $value ml', () {
      expect(
        () => HydrationPreferences(defaultGlassSizeMl: value).validate(),
        returnsNormally,
      );
    });
  }

  for (final value in [-10, 0, 40, 49, 55, 255, 2001, 2010]) {
    test('canonical Glass Size rejects $value without rounding', () {
      expect(
        () => HydrationPreferences(defaultGlassSizeMl: value).validate(),
        throwsArgumentError,
      );
    });
  }

  test('default is a non-null 250 ml value and equality preserves ml', () {
    expect(
      const HydrationPreferences().defaultGlassSizeMl,
      HydrationPreferences.defaultGlassSizeMlDefault,
    );
    expect(
      const HydrationPreferences(),
      const HydrationPreferences(defaultGlassSizeMl: 250),
    );
    expect(
      const HydrationPreferences(defaultGlassSizeMl: 250),
      isNot(const HydrationPreferences(defaultGlassSizeMl: 300)),
    );
  });
}
