import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  test('Additional Nutrition route describes the read-only reference surface',
      () {
    expect(
      AppRoutes.nutritionAdditionalGoalsSettings.description,
      'View calculated daily reference values for additional nutrients.',
    );
    expect(
      AppRoutes.nutritionAdditionalGoalsSettings.path,
      '/settings/nutrition/targets/additional-goals',
      reason: 'The compatibility path is unchanged.',
    );
  });
}
