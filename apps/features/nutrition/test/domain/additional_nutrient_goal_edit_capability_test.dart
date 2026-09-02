import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

/// Frozen TNYX-141 edit eligibility, owned by the domain.
///
/// These are the rules an editor renders rather than re-derives, so that a
/// second surface offering the same actions cannot quietly disagree with the
/// first about what a user is allowed to do.
void main() {
  NutrientRecommendation available() => const NutrientRecommendation.available(
        nutrientId: NutrientId.vitaminD,
        goalType: NutrientGoalType.target,
        comparison: NutrientGoalComparison.target,
        recommendedValue: 15,
      );

  NutrientRecommendation unavailable() =>
      const NutrientRecommendation.unavailable(
        nutrientId: NutrientId.vitaminD,
        goalType: NutrientGoalType.target,
        comparison: NutrientGoalComparison.target,
      );

  group('the recommendation is derivable', () {
    test('an unconfigured nutrient can be set custom or enabled outright', () {
      final capability = AdditionalNutrientGoalEditCapability.forGoal(
        goal: null,
        recommendation: available(),
      );

      expect(capability.canSetCustomValue, isTrue);
      expect(
        capability.canUseRecommendation,
        isTrue,
        reason: 'Opting in must not require inventing a Custom value first.',
      );
      expect(capability.canTurnOff, isFalse);
      expect(capability.isValuePreserved, isFalse);
    });

    test('a custom goal may revert to the recommendation', () {
      final capability = AdditionalNutrientGoalEditCapability.forGoal(
        goal: const AdditionalNutrientGoal(
          nutrientId: NutrientId.vitaminD,
          customValue: 18,
        ),
        recommendation: available(),
      );

      expect(capability.canSetCustomValue, isTrue);
      expect(capability.canUseRecommendation, isTrue);
      expect(capability.canTurnOff, isTrue);
    });

    test('a goal already on the recommendation has nothing to revert to', () {
      final capability = AdditionalNutrientGoalEditCapability.forGoal(
        goal: const AdditionalNutrientGoal(nutrientId: NutrientId.vitaminD),
        recommendation: available(),
      );

      expect(capability.canUseRecommendation, isFalse);
      expect(capability.canSetCustomValue, isTrue);
      expect(capability.canTurnOff, isTrue);
    });

    test('an explicit zero is a custom value, not an absent one', () {
      final capability = AdditionalNutrientGoalEditCapability.forGoal(
        goal: const AdditionalNutrientGoal(
          nutrientId: NutrientId.transFat,
          customValue: 0,
        ),
        recommendation: available(),
      );

      expect(capability.canUseRecommendation, isTrue);
      expect(capability.canTurnOff, isTrue);
    });
  });

  group('the recommendation is not derivable', () {
    test('an unconfigured nutrient offers no way to enable it', () {
      final capability = AdditionalNutrientGoalEditCapability.forGoal(
        goal: null,
        recommendation: unavailable(),
      );

      expect(
        capability.canSetCustomValue,
        isFalse,
        reason: 'Custom must not be a bypass around the eligibility rule.',
      );
      expect(capability.canUseRecommendation, isFalse);
      expect(capability.canTurnOff, isFalse);
      expect(
        capability.isValuePreserved,
        isFalse,
        reason: 'There is no stored value to preserve.',
      );
    });

    test('an already-configured goal is preserved and still removable', () {
      final capability = AdditionalNutrientGoalEditCapability.forGoal(
        goal: const AdditionalNutrientGoal(
          nutrientId: NutrientId.vitaminD,
          customValue: 18,
        ),
        recommendation: unavailable(),
      );

      expect(capability.canSetCustomValue, isFalse);
      expect(capability.canUseRecommendation, isFalse);
      expect(
        capability.canTurnOff,
        isTrue,
        reason: 'Removing your own data is never gated on a prerequisite.',
      );
      expect(capability.isValuePreserved, isTrue);
    });
  });
}
