import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

void main() {
  test('in-memory MealLog owner is deterministic and readable', () async {
    final now = DateTime.utc(2026, 9, 11, 12);
    final repository = InMemoryMealLogRepository(
      mealCategoriesRepository: InMemoryMealCategoriesRepository(),
      clock: () => now,
    );
    final input = ManualMealLogCreate(
      mealCategoryId: 'meal_slot_1',
      mealName: 'Breakfast',
      consumedAt: DateTime.utc(2026, 9, 11, 2, 30),
      consumedLocalDate: MealLogLocalDate(year: 2026, month: 9, day: 11),
      consumedUtcOffsetMinutes: 330,
      captureSource: MealLogCaptureSource.quickAdd,
      manualNutritionSnapshot: NutritionSnapshot(
        schemaVersion: 1,
        nutrients: {NutrientId.energy: 300},
      ),
    );

    final first = await repository.createManual(input);
    final second = await repository.createManual(input);

    expect(first.id, 'in_memory_meal_log_1');
    expect(second.id, 'in_memory_meal_log_2');
    expect(first.userId, 'in_memory_meal_log_user');
    expect(first.createdAt, now);
    expect(first.updatedAt, now);
    expect(first.consumedAt, DateTime.utc(2026, 9, 11, 2, 30));
    expect((await repository.readById(first.id))?.id, first.id);
  });

  test('in-memory create rejects a missing Meal Category identity', () async {
    final repository = InMemoryMealLogRepository(
      mealCategoriesRepository: InMemoryMealCategoriesRepository(),
    );
    final input = ManualMealLogCreate(
      mealCategoryId: 'missing-category',
      consumedAt: DateTime.utc(2026, 9, 11, 2, 30),
      consumedLocalDate: MealLogLocalDate(year: 2026, month: 9, day: 11),
      consumedUtcOffsetMinutes: 330,
      manualNutritionSnapshot: NutritionSnapshot(
        schemaVersion: 1,
        nutrients: {NutrientId.energy: 300},
      ),
    );

    await expectLater(
      () => repository.createManual(input),
      throwsArgumentError,
    );
  });

  test('blank in-memory identity is rejected', () async {
    final repository = InMemoryMealLogRepository(
      mealCategoriesRepository: InMemoryMealCategoriesRepository(),
    );
    await expectLater(() => repository.readById('  '), throwsArgumentError);
  });
}
