import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

/// Goal-state semantics for Additional Nutrient Goals V1.
///
/// The four states the product depends on are absent, enabled-on-recommended,
/// enabled-with-custom-override, and explicit zero. The distinction that
/// matters most is that a custom override records user intent: it must survive
/// a recommendation becoming underivable, and only an explicit "Use
/// Recommended" may clear it.
void main() {
  NutrientRecommendation recommendation({double? value = 15}) => value == null
      ? const NutrientRecommendation.unavailable(
          nutrientId: NutrientId.vitaminD,
          goalType: NutrientGoalType.target,
          comparison: NutrientGoalComparison.target,
        )
      : NutrientRecommendation.available(
          nutrientId: NutrientId.vitaminD,
          goalType: NutrientGoalType.target,
          comparison: NutrientGoalComparison.target,
          recommendedValue: value,
        );

  group('goal presence', () {
    test('an empty set has no configured nutrients', () {
      const goals = AdditionalNutrientGoalSet.empty();

      expect(goals.isEmpty, isTrue);
      expect(goals.contains(NutrientId.vitaminD), isFalse);
      expect(goals[NutrientId.vitaminD], isNull);
    });

    test('enabling creates a key that uses the recommendation', () {
      final goals = const AdditionalNutrientGoalSet.empty().withGoal(
        const AdditionalNutrientGoal(nutrientId: NutrientId.vitaminD),
      );

      expect(goals.contains(NutrientId.vitaminD), isTrue);
      expect(goals[NutrientId.vitaminD]!.customValue, isNull);
      expect(goals[NutrientId.vitaminD]!.usesRecommendation, isTrue);
    });

    test('disabling removes the goal entirely', () {
      final enabled = const AdditionalNutrientGoalSet.empty().withGoal(
        const AdditionalNutrientGoal(nutrientId: NutrientId.vitaminD),
      );

      final disabled = enabled.without(NutrientId.vitaminD);

      expect(disabled.contains(NutrientId.vitaminD), isFalse);
      expect(disabled.isEmpty, isTrue);
    });

    test('each nutrient is configured independently', () {
      final goals = const AdditionalNutrientGoalSet.empty()
          .withGoal(const AdditionalNutrientGoal(
            nutrientId: NutrientId.sodium,
            customValue: 1500,
          ))
          .withGoal(const AdditionalNutrientGoal(
            nutrientId: NutrientId.vitaminD,
          ));

      final afterDisable = goals.without(NutrientId.sodium);

      expect(afterDisable.contains(NutrientId.sodium), isFalse);
      expect(afterDisable.contains(NutrientId.vitaminD), isTrue);
    });

    test('replacing a goal does not duplicate the nutrient', () {
      final goals = const AdditionalNutrientGoalSet.empty()
          .withGoal(const AdditionalNutrientGoal(
            nutrientId: NutrientId.vitaminD,
            customValue: 18,
          ))
          .withGoal(const AdditionalNutrientGoal(
            nutrientId: NutrientId.vitaminD,
            customValue: 20,
          ));

      expect(goals.goals.length, 1);
      expect(goals[NutrientId.vitaminD]!.customValue, 20);
    });
  });

  group('effective value', () {
    test('falls back to the recommendation when no override exists', () {
      const goal = AdditionalNutrientGoal(nutrientId: NutrientId.vitaminD);

      expect(recommendation().effectiveValueFor(goal), 15);
    });

    test('a custom override wins over an available recommendation', () {
      const goal = AdditionalNutrientGoal(
        nutrientId: NutrientId.vitaminD,
        customValue: 18,
      );

      expect(recommendation().effectiveValueFor(goal), 18);
    });

    test('an explicit zero is a real override, not an absent value', () {
      const goal = AdditionalNutrientGoal(
        nutrientId: NutrientId.transFat,
        customValue: 0,
      );

      expect(
        recommendation().effectiveValueFor(goal),
        0,
        reason: 'Zero must not be treated as null and replaced by 15.',
      );
    });

    test('a custom override survives the recommendation becoming unavailable',
        () {
      const goal = AdditionalNutrientGoal(
        nutrientId: NutrientId.vitaminD,
        customValue: 18,
      );

      // Date of birth later becomes unavailable, so nothing can be derived.
      expect(recommendation(value: null).effectiveValueFor(goal), 18);
    });

    test('an unavailable recommendation with no override has no value', () {
      const goal = AdditionalNutrientGoal(nutrientId: NutrientId.vitaminD);

      expect(recommendation(value: null).effectiveValueFor(goal), isNull);
    });
  });

  group('use recommended', () {
    test('clears the override but keeps the nutrient configured', () {
      final withOverride = const AdditionalNutrientGoalSet.empty().withGoal(
        const AdditionalNutrientGoal(
          nutrientId: NutrientId.vitaminD,
          customValue: 18,
        ),
      );

      final useRecommended = withOverride.withGoal(
        const AdditionalNutrientGoal(nutrientId: NutrientId.vitaminD),
      );

      expect(
        useRecommended.contains(NutrientId.vitaminD),
        isTrue,
        reason: 'Use Recommended must not delete the goal.',
      );
      expect(useRecommended[NutrientId.vitaminD]!.customValue, isNull);
      expect(
          recommendation().effectiveValueFor(
            useRecommended[NutrientId.vitaminD],
          ),
          15);
    });
  });

  group('validation', () {
    test('rejects nutrients outside the authorized subset', () {
      expect(
        () => AdditionalNutrientGoalSet.fromGoals([
          const AdditionalNutrientGoal(nutrientId: NutrientId.protein),
        ]),
        throwsArgumentError,
      );
    });

    test('accepts all four authorized nutrients', () {
      final goals = AdditionalNutrientGoalSet.fromGoals([
        const AdditionalNutrientGoal(nutrientId: NutrientId.saturatedFat),
        const AdditionalNutrientGoal(nutrientId: NutrientId.transFat),
        const AdditionalNutrientGoal(nutrientId: NutrientId.sodium),
        const AdditionalNutrientGoal(nutrientId: NutrientId.vitaminD),
      ]);

      expect(goals.goals.length, 4);
    });

    test('rejects negative and non-finite overrides but allows zero', () {
      expect(
        () => AdditionalNutrientGoalSet.fromGoals([
          const AdditionalNutrientGoal(
            nutrientId: NutrientId.sodium,
            customValue: -1,
          ),
        ]),
        throwsArgumentError,
      );
      expect(
        () => AdditionalNutrientGoalSet.fromGoals([
          const AdditionalNutrientGoal(
            nutrientId: NutrientId.sodium,
            customValue: double.nan,
          ),
        ]),
        throwsArgumentError,
      );
      expect(
        AdditionalNutrientGoalSet.fromGoals([
          const AdditionalNutrientGoal(
            nutrientId: NutrientId.transFat,
            customValue: 0,
          ),
        ])[NutrientId.transFat]!
            .customValue,
        0,
      );
    });
  });

  group('unsupported future schema', () {
    test('is read-only and refuses edits', () {
      const unsupported = AdditionalNutrientGoalSet.unsupported();

      expect(unsupported.isWritable, isFalse);
      expect(
        () => unsupported.withGoal(
          const AdditionalNutrientGoal(nutrientId: NutrientId.sodium),
        ),
        throwsStateError,
      );
      expect(
        () => unsupported.without(NutrientId.sodium),
        throwsStateError,
      );
    });
  });
}
