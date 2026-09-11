import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

const _mutation1 = '11111111-1111-4111-8111-111111111111';
const _mutation2 = '22222222-2222-4222-8222-222222222222';

void main() {
  test('same in-memory mutation returns one deterministic readable row',
      () async {
    final now = DateTime.utc(2026, 9, 11, 12);
    final repository = InMemoryMealLogRepository(
      mealCategoriesRepository: InMemoryMealCategoriesRepository(),
      clock: () => now,
    );
    final input = _input(clientMutationId: _mutation1);

    final first = await repository.createManual(input);
    final retry = await repository.createManual(input);
    final secondLogicalCreate = await repository.createManual(
      _input(clientMutationId: _mutation2),
    );

    expect(first.id, 'in_memory_meal_log_1');
    expect(retry.id, first.id);
    expect(secondLogicalCreate.id, 'in_memory_meal_log_2');
    expect(first.userId, 'in_memory_meal_log_user');
    expect(first.createdAt, now);
    expect(first.updatedAt, now);
    expect(first.consumedAt, DateTime.utc(2026, 9, 11, 2, 30));
    expect((await repository.readById(first.id))?.id, first.id);
  });

  test('same in-memory mutation id with different facts fails closed',
      () async {
    final repository = InMemoryMealLogRepository(
      mealCategoriesRepository: InMemoryMealCategoriesRepository(),
    );
    await repository.createManual(_input(clientMutationId: _mutation1));

    await expectLater(
      () => repository.createManual(
        _input(clientMutationId: _mutation1, mealName: 'Different'),
      ),
      throwsA(isA<MealLogCreateMutationConflict>()),
    );
  });

  test('in-memory retry survives category archived after first create',
      () async {
    final categories = InMemoryMealCategoriesRepository();
    final repository = InMemoryMealLogRepository(
      mealCategoriesRepository: categories,
    );
    final input = _input(clientMutationId: _mutation1);
    final created = await repository.createManual(input);

    final current = await categories.read();
    await categories.upsert(
      MealCategoriesConfig(
        items: current.items.map(
          (item) => item.id == 'meal_slot_1' ? item.withActive(false) : item,
        ),
      ),
    );

    final retry = await repository.createManual(input);
    expect(retry.id, created.id);
  });

  test('in-memory create rejects a missing Meal Category identity', () async {
    final repository = InMemoryMealLogRepository(
      mealCategoriesRepository: InMemoryMealCategoriesRepository(),
    );

    await expectLater(
      () => repository.createManual(
        _input(
          clientMutationId: _mutation1,
          mealCategoryId: 'missing-category',
        ),
      ),
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

ManualMealLogCreate _input({
  required String clientMutationId,
  String mealCategoryId = 'meal_slot_1',
  String mealName = 'Breakfast',
}) {
  return ManualMealLogCreate(
    clientMutationId: clientMutationId,
    mealCategoryId: mealCategoryId,
    mealName: mealName,
    consumedAt: DateTime.utc(2026, 9, 11, 2, 30),
    consumedLocalDate: MealLogLocalDate(year: 2026, month: 9, day: 11),
    consumedUtcOffsetMinutes: 330,
    captureSource: MealLogCaptureSource.quickAdd,
    manualNutritionSnapshot: NutritionSnapshot(
      schemaVersion: 1,
      nutrients: {NutrientId.energy: 300},
    ),
  );
}
