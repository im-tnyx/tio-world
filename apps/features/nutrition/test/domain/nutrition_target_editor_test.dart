import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

/// Pure editing rules for the core five targets.
///
/// The repository's `upsert` replaces the whole row, so preservation is the
/// central guarantee here: one edit must never silently drop another target,
/// custom intent, or recommendation provenance.
void main() {
  const recommendedBaseline = NutritionTargetsData(
    caloriesKcal: 2000,
    proteinGrams: 150,
    carbohydrateGrams: 200,
    fatGrams: 55.6,
    fiberGrams: 28,
    customizationState: NutritionTargetCustomizationState.recommended,
    customizedFields: {},
    recommendationMetadata: {'source': 'onboarding', 'bmr': 1600, 'tdee': 2100},
  );

  group('field identity', () {
    test('storage values are the frozen core-five vocabulary', () {
      expect(
        NutritionTargetField.values.map((f) => f.storageValue),
        ['calories', 'protein', 'carbohydrate', 'fat', 'fiber'],
      );
    });

    test('is a different namespace from NutrientId', () {
      // Same quantity, different question. Neither is renamed for symmetry.
      expect(NutritionTargetField.calories.storageValue, 'calories');
      expect(NutritionTargetField.calories.storageValue, isNot('energy'));
    });

    test('unknown stored field identities stay unknown', () {
      expect(NutritionTargetField.fromStorageValue('sodium'), isNull);
      expect(NutritionTargetField.fromStorageValue(null), isNull);
    });
  });

  group('coherence', () {
    test('is not evaluable while any of the four values is missing', () {
      for (final partial in [
        const NutritionTargetsData(),
        const NutritionTargetsData(caloriesKcal: 2000),
        const NutritionTargetsData(
          caloriesKcal: 2000,
          proteinGrams: 150,
          carbohydrateGrams: 200,
        ),
      ]) {
        final coherence = NutritionTargetEditor.coherenceOf(partial);
        expect(coherence.isEvaluable, isFalse);
        // A partial row must never be blocked: treating null as zero would
        // fabricate a value and produce a false mismatch.
        expect(coherence.blocksSave, isFalse);
      }
    });

    test('fiber is excluded from the macro-calorie equation', () {
      // Macros imply 1900.4 kcal, so the pair is coherent at a 1900 target.
      const withoutFiber = NutritionTargetsData(
        caloriesKcal: 1900,
        proteinGrams: 150,
        carbohydrateGrams: 200,
        fatGrams: 55.6,
      );
      const withLargeFiber = NutritionTargetsData(
        caloriesKcal: 1900,
        proteinGrams: 150,
        carbohydrateGrams: 200,
        fatGrams: 55.6,
        fiberGrams: 400,
      );

      expect(
        NutritionTargetEditor.coherenceOf(withoutFiber).macroCalories,
        NutritionTargetEditor.coherenceOf(withLargeFiber).macroCalories,
      );
      expect(
        NutritionTargetEditor.coherenceOf(withLargeFiber).blocksSave,
        isFalse,
      );
    });

    test('accepts drift within the tolerance', () {
      // 150*4 + 200*4 + 55.6*9 = 1900.4 against a 1900 kcal target.
      const nearlyExact = NutritionTargetsData(
        caloriesKcal: 1900,
        proteinGrams: 150,
        carbohydrateGrams: 200,
        fatGrams: 55.6,
      );

      final coherence = NutritionTargetEditor.coherenceOf(nearlyExact);
      expect(coherence.differenceKcal, lessThanOrEqualTo(5));
      expect(coherence.blocksSave, isFalse);
    });

    test('blocks a material mismatch and reports both sides', () {
      const mismatched = NutritionTargetsData(
        caloriesKcal: 1200,
        proteinGrams: 150,
        carbohydrateGrams: 200,
        fatGrams: 55.6,
      );

      final coherence = NutritionTargetEditor.coherenceOf(mismatched);
      expect(coherence.blocksSave, isTrue);
      expect(coherence.targetCalories, 1200);
      expect(coherence.macroCalories, closeTo(1900.4, 0.001));
      expect(coherence.differenceKcal, closeTo(700.4, 0.001));
    });
  });

  group('derived macro percentages', () {
    test('splits macro energy and always totals exactly 100', () {
      // 403*4 + 161*4 + 107*9 = 1612 + 644 + 963 = 3219 kcal of macro energy.
      const targets = NutritionTargetsData(
        caloriesKcal: 3220,
        proteinGrams: 161,
        carbohydrateGrams: 403,
        fatGrams: 107,
      );

      final percentages = NutritionTargetEditor.macroPercentages(targets)!;
      expect(percentages[NutritionTargetField.carbohydrate], 50);
      expect(percentages[NutritionTargetField.protein], 20);
      expect(percentages[NutritionTargetField.fat], 30);
      expect(percentages.values.reduce((a, b) => a + b), 100);
    });

    test('never displays a total of 99 or 101', () {
      // Independent rounding of these thirds would show 33/33/33.
      const awkward = NutritionTargetsData(
        proteinGrams: 100,
        carbohydrateGrams: 100,
        fatGrams: 400 / 9,
      );

      final percentages = NutritionTargetEditor.macroPercentages(awkward)!;
      expect(percentages.values.reduce((a, b) => a + b), 100);
    });

    test('is deterministic across repeated calls', () {
      const targets = NutritionTargetsData(
        proteinGrams: 100,
        carbohydrateGrams: 100,
        fatGrams: 400 / 9,
      );

      expect(
        NutritionTargetEditor.macroPercentages(targets),
        NutritionTargetEditor.macroPercentages(targets),
      );
    });

    test('is unavailable when any macro is unknown', () {
      for (final partial in [
        const NutritionTargetsData(),
        const NutritionTargetsData(proteinGrams: 150),
        const NutritionTargetsData(proteinGrams: 150, carbohydrateGrams: 200),
      ]) {
        // A percentage of an unknown is undefined, not zero.
        expect(NutritionTargetEditor.macroPercentages(partial), isNull);
      }
    });

    test('is unavailable when the macros carry no energy at all', () {
      const allZero = NutritionTargetsData(
        proteinGrams: 0,
        carbohydrateGrams: 0,
        fatGrams: 0,
      );

      // Avoids a division by zero and avoids showing a fabricated 0/0/0 split.
      expect(NutritionTargetEditor.macroPercentages(allZero), isNull);
    });

    test('fiber never affects the split', () {
      const withoutFiber = NutritionTargetsData(
        proteinGrams: 161,
        carbohydrateGrams: 403,
        fatGrams: 107,
      );
      const withFiber = NutritionTargetsData(
        proteinGrams: 161,
        carbohydrateGrams: 403,
        fatGrams: 107,
        fiberGrams: 30,
      );

      expect(
        NutritionTargetEditor.macroPercentages(withFiber),
        NutritionTargetEditor.macroPercentages(withoutFiber),
      );
    });
  });

  group('applyEdit preservation', () {
    test('editing one target leaves every other field untouched', () {
      final edited = NutritionTargetEditor.applyEdit(
        recommendedBaseline,
        field: NutritionTargetField.fiber,
        value: 35,
      );

      expect(edited.fiberGrams, 35);
      expect(edited.caloriesKcal, 2000);
      expect(edited.proteinGrams, 150);
      expect(edited.carbohydrateGrams, 200);
      expect(edited.fatGrams, 55.6);
    });

    test('recommendationMetadata survives unchanged', () {
      final edited = NutritionTargetEditor.applyEdit(
        recommendedBaseline,
        field: NutritionTargetField.protein,
        value: 160,
      );

      expect(edited.recommendationMetadata, {
        'source': 'onboarding',
        'bmr': 1600,
        'tdee': 2100,
      });
    });

    test('changing Calories never rewrites the macros', () {
      final edited = NutritionTargetEditor.applyEdit(
        recommendedBaseline,
        field: NutritionTargetField.calories,
        value: 1700,
      );

      // No recalculation, no proportional rebalance, no Profile/Body read.
      expect(edited.caloriesKcal, 1700);
      expect(edited.proteinGrams, recommendedBaseline.proteinGrams);
      expect(edited.carbohydrateGrams, recommendedBaseline.carbohydrateGrams);
      expect(edited.fatGrams, recommendedBaseline.fatGrams);
      expect(edited.fiberGrams, recommendedBaseline.fiberGrams);
    });

    test('clearing a target stores null rather than zero', () {
      final edited = NutritionTargetEditor.applyEdit(
        recommendedBaseline,
        field: NutritionTargetField.fiber,
        value: null,
      );

      expect(edited.fiberGrams, isNull);
      expect(edited.fiberGrams, isNot(0));
    });
  });

  group('applyMacroEdits', () {
    test('claims only the macros the user actually moved', () {
      final edited = NutritionTargetEditor.applyMacroEdits(
        recommendedBaseline,
        proteinGrams: 170,
        carbohydrateGrams: recommendedBaseline.carbohydrateGrams,
        fatGrams: recommendedBaseline.fatGrams,
      );

      // Opening the combined editor must not claim untouched macros as custom.
      expect(edited.customizedFields, {'protein'});
      expect(
          edited.customizationState, NutritionTargetCustomizationState.mixed);
    });

    test('preserves calories, fiber and recommendation metadata', () {
      final edited = NutritionTargetEditor.applyMacroEdits(
        recommendedBaseline,
        proteinGrams: 170,
        carbohydrateGrams: 210,
        fatGrams: 50,
      );

      expect(edited.caloriesKcal, 2000);
      expect(edited.fiberGrams, 28);
      expect(edited.recommendationMetadata,
          {'source': 'onboarding', 'bmr': 1600, 'tdee': 2100});
    });

    test('records all three when all three move', () {
      final edited = NutritionTargetEditor.applyMacroEdits(
        recommendedBaseline,
        proteinGrams: 170,
        carbohydrateGrams: 210,
        fatGrams: 50,
      );

      expect(edited.customizedFields, {'protein', 'carbohydrate', 'fat'});
    });
  });

  group('slider range', () {
    test('spans up to the grams that would use the whole calorie target', () {
      // 2000 kcal / 9 kcal per gram of fat.
      expect(
        NutritionTargetEditor.sliderMaxGrams(
          NutritionTargetField.fat,
          caloriesKcal: 2000,
          current: 55,
        ),
        223,
      );
      expect(
        NutritionTargetEditor.sliderMaxGrams(
          NutritionTargetField.protein,
          caloriesKcal: 2000,
          current: 150,
        ),
        500,
      );
    });

    test('always covers an already-stored larger value', () {
      // A stored target beyond the contextual range must stay representable
      // rather than being clamped out of view.
      expect(
        NutritionTargetEditor.sliderMaxGrams(
          NutritionTargetField.fat,
          caloriesKcal: 2000,
          current: 400,
        ),
        greaterThanOrEqualTo(400),
      );
    });

    test('falls back to twice the current value with no calorie target', () {
      expect(
        NutritionTargetEditor.sliderMaxGrams(
          NutritionTargetField.protein,
          caloriesKcal: null,
          current: 300,
        ),
        600,
      );
    });

    test('stays usable when the current value is zero', () {
      final max = NutritionTargetEditor.sliderMaxGrams(
        NutritionTargetField.protein,
        caloriesKcal: null,
        current: 0,
      );

      // A zero-gram macro still needs somewhere to slide to.
      expect(max, greaterThan(0));
    });
  });

  group('provenance', () {
    test('recommended baseline plus one manual edit becomes mixed', () {
      final edited = NutritionTargetEditor.applyEdit(
        recommendedBaseline,
        field: NutritionTargetField.protein,
        value: 170,
      );

      expect(
        edited.customizationState,
        NutritionTargetCustomizationState.mixed,
      );
      expect(edited.customizedFields, {'protein'});
    });

    test('accumulates customized fields across successive edits', () {
      var data = NutritionTargetEditor.applyEdit(
        recommendedBaseline,
        field: NutritionTargetField.protein,
        value: 170,
      );
      data = NutritionTargetEditor.applyEdit(
        data,
        field: NutritionTargetField.fiber,
        value: 30,
      );

      expect(data.customizedFields, {'protein', 'fiber'});
      expect(data.customizationState, NutritionTargetCustomizationState.mixed);
    });

    test('becomes custom once every populated field is user-owned', () {
      var data = recommendedBaseline;
      for (final (field, value) in const [
        (NutritionTargetField.calories, 1900),
        (NutritionTargetField.protein, 150),
        (NutritionTargetField.carbohydrate, 200),
        (NutritionTargetField.fat, 55.6),
        (NutritionTargetField.fiber, 30),
      ]) {
        data =
            NutritionTargetEditor.applyEdit(data, field: field, value: value);
      }

      expect(data.customizationState, NutritionTargetCustomizationState.custom);
    });

    test('an unknown baseline with user values becomes custom', () {
      final edited = NutritionTargetEditor.applyEdit(
        const NutritionTargetsData(),
        field: NutritionTargetField.calories,
        value: 2100,
      );

      expect(
          edited.customizationState, NutritionTargetCustomizationState.custom);
      expect(edited.customizedFields, {'calories'});
    });

    test('custom intent is kept when a value returns to the recommendation',
        () {
      var data = NutritionTargetEditor.applyEdit(
        recommendedBaseline,
        field: NutritionTargetField.protein,
        value: 170,
      );
      data = NutritionTargetEditor.applyEdit(
        data,
        field: NutritionTargetField.protein,
        // Numerically equal to the original recommendation.
        value: 150,
      );

      // Only an explicit Reset-to-Recommended flow may clear custom intent.
      expect(data.customizedFields, contains('protein'));
      expect(data.customizationState, NutritionTargetCustomizationState.mixed);
    });
  });
}
