import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('DailyNutritionBudgetResolver', () {
    test('Standard preserves the explicit selected date and canonical target',
        () async {
      final repository = InMemoryNutritionTargetsRepository();
      const targets = NutritionTargetsData(
        caloriesKcal: 2200,
        proteinGrams: 140,
        carbohydrateGrams: 250,
        fatGrams: 70,
        fiberGrams: 30,
        customizationState: NutritionTargetCustomizationState.mixed,
        customizedFields: {'protein_grams'},
        recommendationMetadata: {'source': 'settings'},
      );
      await repository.upsert(targets);
      final resolver = DailyNutritionBudgetResolver(
        nutritionTargetsRepository: repository,
      );
      final selectedDate = MealLogLocalDate(
        year: 2025,
        month: 1,
        day: 15,
      );

      final budget = await resolver.resolve(selectedDate);

      expect(budget, isNotNull);
      expect(budget!.localDate, selectedDate);
      expect(budget.baseTarget, same(targets));
      expect(budget.strategyAdjustedTarget, same(targets));
    });

    test('returns unavailable when the canonical target row is absent',
        () async {
      final resolver = DailyNutritionBudgetResolver(
        nutritionTargetsRepository: InMemoryNutritionTargetsRepository(),
      );

      final budget = await resolver.resolve(
        MealLogLocalDate(year: 2026, month: 9, day: 13),
      );

      expect(budget, isNull);
    });

    test('preserves unknown target fields instead of fabricating zero',
        () async {
      final repository = InMemoryNutritionTargetsRepository();
      const targets = NutritionTargetsData(
        caloriesKcal: 2100,
        proteinGrams: null,
        carbohydrateGrams: 225,
        fatGrams: null,
        fiberGrams: null,
      );
      await repository.upsert(targets);
      final resolver = DailyNutritionBudgetResolver(
        nutritionTargetsRepository: repository,
      );

      final budget = await resolver.resolve(
        MealLogLocalDate(year: 2024, month: 12, day: 31),
      );

      expect(budget, isNotNull);
      expect(budget!.strategyAdjustedTarget.caloriesKcal, 2100);
      expect(budget.strategyAdjustedTarget.proteinGrams, isNull);
      expect(budget.strategyAdjustedTarget.carbohydrateGrams, 225);
      expect(budget.strategyAdjustedTarget.fatGrams, isNull);
      expect(budget.strategyAdjustedTarget.fiberGrams, isNull);
    });

    test('propagates canonical target read failures', () async {
      final resolver = DailyNutritionBudgetResolver(
        nutritionTargetsRepository: _ThrowingNutritionTargetsRepository(),
      );

      await expectLater(
        resolver.resolve(MealLogLocalDate(year: 2026, month: 9, day: 13)),
        throwsA(isA<StateError>()),
      );
    });

    test('fails closed if a repository returns an invalid canonical target',
        () async {
      final resolver = DailyNutritionBudgetResolver(
        nutritionTargetsRepository: _InvalidNutritionTargetsRepository(),
      );

      await expectLater(
        resolver.resolve(MealLogLocalDate(year: 2026, month: 9, day: 13)),
        throwsArgumentError,
      );
    });
  });
}

final class _ThrowingNutritionTargetsRepository
    implements NutritionTargetsRepository {
  @override
  Future<NutritionTargetsData?> read() async {
    throw StateError('target read failed');
  }

  @override
  Future<void> upsert(NutritionTargetsData targets) {
    throw UnsupportedError('not used');
  }
}

final class _InvalidNutritionTargetsRepository
    implements NutritionTargetsRepository {
  @override
  Future<NutritionTargetsData?> read() async {
    return const NutritionTargetsData(caloriesKcal: 0);
  }

  @override
  Future<void> upsert(NutritionTargetsData targets) {
    throw UnsupportedError('not used');
  }
}
