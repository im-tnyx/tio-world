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

  test('does not recommend loss below BMI safety floor', () {
    final result = resolver.resolve(
      direction: GoalWeightDirection.loss,
      currentWeightKg: 54,
      heightCm: 175,
    );

    expect(result, closeTo(56.7, 0.05));
  });

  test('does not recommend gain above configured BMI guardrail', () {
    final result = resolver.resolve(
      direction: GoalWeightDirection.gain,
      currentWeightKg: 92,
      heightCm: 175,
    );

    expect(result, closeTo(91.9, 0.05));
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
