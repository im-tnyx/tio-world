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

  test('valid customization persists and can be cleared', () async {
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

    await repository.clearCustomization();
    expect(repository.hasCustomization, isFalse);
    expect(
      (await repository.read()).findById('meal_slot_2')!.displayName,
      'Lunch',
    );
  });

  test('repository rejects invalid config and preserves prior state', () async {
    final repository = InMemoryMealCategoriesRepository();
    final valid = MealCategoriesConfig.canonicalDefaults();
    await repository.upsert(valid);
    final invalid = MealCategoriesConfig(
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
    );

    await expectLater(
      repository.upsert(invalid),
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

  test('archived identity remains resolvable but not selectable', () async {
    final repository = InMemoryMealCategoriesRepository();
    final defaults = MealCategoriesConfig.canonicalDefaults();
    final archivedLunch = MealCategoriesConfig(
      items: [
        for (final item in defaults.items)
          item.id == 'meal_slot_2' ? item.withActive(false) : item,
      ],
    );

    await repository.upsert(archivedLunch);
    final loaded = await repository.read();

    expect(loaded.findById('meal_slot_2'), isNotNull);
    expect(loaded.findById('meal_slot_2')!.active, isFalse);
    expect(
      loaded.activeItems.map((item) => item.id),
      isNot(contains('meal_slot_2')),
    );
  });
}
