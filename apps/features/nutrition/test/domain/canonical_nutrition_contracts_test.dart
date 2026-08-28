import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

void main() {
  group('canonical Nutrition Profile contract', () {
    test('in-memory owner preserves unknown vs explicitly empty collections',
        () async {
      final repository = InMemoryNutritionProfileRepository();

      const unknown = NutritionProfileData(
        preferredDiet: null,
        allergies: null,
        dislikedFoods: null,
        medicalConditions: null,
      );
      await repository.upsert(unknown);
      expect((await repository.read())?.allergies, isNull);

      const explicitNone = NutritionProfileData(
        preferredDiet: 'balanced',
        allergies: {},
        dislikedFoods: {},
        medicalConditions: {},
      );
      await repository.upsert(explicitNone);
      final stored = await repository.read();
      expect(stored?.preferredDiet, 'balanced');
      expect(stored?.allergies, isEmpty);
      expect(stored?.dislikedFoods, isEmpty);
      expect(stored?.medicalConditions, isEmpty);
    });
  });

  group('canonical Nutrition Targets contract', () {
    test('in-memory owner preserves nullable targets and customization metadata',
        () async {
      final repository = InMemoryNutritionTargetsRepository();
      const targets = NutritionTargetsData(
        caloriesKcal: null,
        proteinGrams: 120.5,
        carbohydrateGrams: null,
        fatGrams: 60,
        fiberGrams: 30,
        customizationState: NutritionTargetCustomizationState.mixed,
        customizedFields: {'protein_grams'},
        recommendationMetadata: {'source': 'onboarding'},
      );

      await repository.upsert(targets);
      final stored = await repository.read();

      expect(stored?.caloriesKcal, isNull);
      expect(stored?.proteinGrams, 120.5);
      expect(stored?.customizationState, NutritionTargetCustomizationState.mixed);
      expect(stored?.customizedFields, {'protein_grams'});
      expect(stored?.recommendationMetadata['source'], 'onboarding');
    });

    test('storage-level validation rejects impossible canonical numeric values',
        () async {
      final repository = InMemoryNutritionTargetsRepository();

      for (final targets in <NutritionTargetsData>[
        const NutritionTargetsData(caloriesKcal: 0),
        const NutritionTargetsData(proteinGrams: -1),
        const NutritionTargetsData(carbohydrateGrams: double.nan),
        const NutritionTargetsData(fatGrams: double.infinity),
        const NutritionTargetsData(fiberGrams: -0.1),
      ]) {
        await expectLater(() => repository.upsert(targets), throwsArgumentError);
      }
    });

    test('customization state storage mapping is strict and lossless', () {
      for (final state in NutritionTargetCustomizationState.values) {
        expect(
          parseNutritionTargetCustomizationState(state.storageValue),
          state,
        );
      }
      expect(
        () => parseNutritionTargetCustomizationState('future_state'),
        throwsFormatException,
      );
      expect(
        () => parseNutritionTargetCustomizationState(null),
        throwsFormatException,
      );
    });
  });
}
