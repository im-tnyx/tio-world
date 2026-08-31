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
