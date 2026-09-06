import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

void main() {
  test('absent customization resolves canonical defaults', () async {
    final repository = InMemoryMealCategoriesRepository();

    final config = await repository.read();

    expect(repository.hasCustomization, isFalse);
    expect(config.orderedItems.map((item) => item.id), [
      'meal_slot_1',
      'meal_slot_2',
      'meal_slot_3',
      'meal_slot_4',
    ]);
  });

  test('valid customization persists', () async {
    final repository = InMemoryMealCategoriesRepository();
    final defaults = MealCategoriesConfig.canonicalDefaults();
    final customized = MealCategoriesConfig(
      items: [
        for (final item in defaults.items)
          item.id == 'meal_slot_2' ? item.renamed('Pre Workout') : item,
      ],
    );

    await repository.upsert(customized);
    expect(repository.hasCustomization, isTrue);
    expect(
      (await repository.read()).findById('meal_slot_2')!.displayName,
      'Pre Workout',
    );
  });

  test('invalid config cannot reach or replace repository state', () async {
    final repository = InMemoryMealCategoriesRepository();
    final valid = MealCategoriesConfig.canonicalDefaults();
    await repository.upsert(valid);
    expect(
      () => MealCategoriesConfig(
        items: [
          ...valid.items,
          for (var index = 0; index < 5; index++)
            MealCategory(
              id: 'meal_slot_00000000-0000-4000-8000-${(index + 1).toString().padLeft(12, '0')}',
              defaultKey: null,
              displayName: 'Custom ${index + 1}',
              active: true,
              order: index + 4,
            ),
        ],
      ),
      throwsA(
        isA<MealCategoriesValidationException>().having(
          (error) => error.code,
          'code',
          MealCategoriesValidationCode.tooManyActiveCategories,
        ),
      ),
    );
    expect(await repository.read(), valid);
  });

  test('archived custom identity remains resolvable but not selectable',
      () async {
    final repository = InMemoryMealCategoriesRepository();
    final defaults = MealCategoriesConfig.canonicalDefaults();
    const archivedId = 'meal_slot_00000000-0000-4000-8000-000000000001';
    final archivedCustom = MealCategoriesConfig(
      items: [
        ...defaults.items,
        MealCategory(
          id: archivedId,
          defaultKey: null,
          displayName: 'Pre Workout',
          active: false,
          order: 4,
        ),
      ],
    );

    await repository.upsert(archivedCustom);
    final loaded = await repository.read();

    expect(loaded.findById(archivedId), isNotNull);
    expect(loaded.findById(archivedId)!.active, isFalse);
    expect(
      loaded.activeItems.map((item) => item.id),
      isNot(contains(archivedId)),
    );
  });
}
