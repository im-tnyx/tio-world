import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

void main() {
  test(
      'equal insufficient-input results have equal hashes regardless of Set order',
      () {
    const first = NutritionTargetRecommendationInsufficientInput(
      missingFields: <String>{
        'heightCm',
        'weightKg',
      },
    );
    const second = NutritionTargetRecommendationInsufficientInput(
      missingFields: <String>{
        'weightKg',
        'heightCm',
      },
    );

    expect(first, equals(second));
    expect(first.hashCode, second.hashCode);
    expect({first, second}, hasLength(1));
  });
}
