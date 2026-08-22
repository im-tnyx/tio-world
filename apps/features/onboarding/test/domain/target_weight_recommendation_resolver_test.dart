import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

void main() {
  const resolver = TargetWeightRecommendationResolver();

  test('returns deterministic directional starting targets', () {
    expect(
      resolver.resolve(
        direction: GoalWeightDirection.loss,
        currentWeightKg: 80,
        heightCm: 175,
      ),
      76.0,
    );
    expect(
      resolver.resolve(
        direction: GoalWeightDirection.gain,
        currentWeightKg: 80,
        heightCm: 175,
      ),
      84.0,
    );
  });

  test('suppresses loss recommendation at or below BMI safety floor', () {
    final result = resolver.resolve(
      direction: GoalWeightDirection.loss,
      currentWeightKg: 54,
      heightCm: 175,
    );

    expect(result, isNull);
  });

  test('suppresses gain recommendation above configured BMI guardrail', () {
    final result = resolver.resolve(
      direction: GoalWeightDirection.gain,
      currentWeightKg: 92,
      heightCm: 175,
    );

    expect(result, isNull);
  });

  test('returns no recommendation without explicit direction or current weight', () {
    expect(
      resolver.resolve(
        direction: null,
        currentWeightKg: 80,
        heightCm: 175,
      ),
      isNull,
    );
    expect(
      resolver.resolve(
        direction: GoalWeightDirection.loss,
        currentWeightKg: null,
        heightCm: 175,
      ),
      isNull,
    );
  });
}
