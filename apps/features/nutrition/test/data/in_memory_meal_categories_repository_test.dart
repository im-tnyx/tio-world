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

  test('rejects omission of an archived retained identity atomically',
      () async {
    final repository = InMemoryMealCategoriesRepository();
    final defaults = MealCategoriesConfig.canonicalDefaults();
    const archivedId = 'meal_slot_00000000-0000-4000-8000-000000000001';
    final previous = MealCategoriesConfig(
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
    await repository.upsert(previous);

    await expectLater(
      repository.upsert(defaults),
      _throwsCode(MealCategoriesValidationCode.retainedIdentityRemoved),
    );
    expect(await repository.read(), previous);
    expect((await repository.read()).findById(archivedId), isNotNull);
  });

  test('rejects omission of an active retained identity', () async {
    final repository = InMemoryMealCategoriesRepository();
    final previous = _configWithCustom(active: true);
    await repository.upsert(previous);

    await expectLater(
      repository.upsert(MealCategoriesConfig.canonicalDefaults()),
      _throwsCode(MealCategoriesValidationCode.retainedIdentityRemoved),
    );
    expect(await repository.read(), previous);
  });

  test('accepts rename while retaining every identity', () async {
    final repository = InMemoryMealCategoriesRepository();
    final previous = _configWithCustom(active: true);
    await repository.upsert(previous);
    final next = MealCategoriesConfig(
      items: [
        for (final item in previous.items)
          item.id == _customId ? item.renamed('Post Workout') : item,
      ],
    );

    await repository.upsert(next);

    expect((await repository.read()).findById(_customId)!.displayName,
        'Post Workout');
  });

  test('accepts reorder while retaining every identity', () async {
    final repository = InMemoryMealCategoriesRepository();
    final previous = _configWithCustom(active: true);
    await repository.upsert(previous);
    final next = MealCategoriesConfig(
      items: [
        for (final item in previous.items)
          if (item.id == _customId)
            item.reordered(1)
          else if (item.id == 'meal_slot_2')
            item.reordered(4)
          else
            item,
      ],
    );

    await repository.upsert(next);

    expect((await repository.read()).findById(_customId)!.order, 1);
    expect((await repository.read()).findById('meal_slot_2')!.order, 4);
  });

  test('accepts active to inactive transition', () async {
    final repository = InMemoryMealCategoriesRepository();
    final previous = _configWithCustom(active: true);
    await repository.upsert(previous);
    final next = MealCategoriesConfig(
      items: [
        for (final item in previous.items)
          item.id == _customId ? item.withActive(false) : item,
      ],
    );

    await repository.upsert(next);

    expect((await repository.read()).findById(_customId)!.active, isFalse);
  });

  test('accepts inactive to active transition within the limit', () async {
    final repository = InMemoryMealCategoriesRepository();
    final previous = _configWithCustom(active: false);
    await repository.upsert(previous);
    final next = MealCategoriesConfig(
      items: [
        for (final item in previous.items)
          item.id == _customId ? item.withActive(true) : item,
      ],
    );

    await repository.upsert(next);

    expect((await repository.read()).findById(_customId)!.active, isTrue);
  });

  test('rejected removal keeps retained ID in future collision input',
      () async {
    final repository = InMemoryMealCategoriesRepository();
    final previous = _configWithCustom(active: false);
    await repository.upsert(previous);
    await expectLater(
      repository.upsert(MealCategoriesConfig.canonicalDefaults()),
      _throwsCode(MealCategoriesValidationCode.retainedIdentityRemoved),
    );
    var calls = 0;
    final generator = UuidMealCategoryIdGenerator(
      uuidV4: () {
        calls++;
        return calls == 1
            ? '00000000-0000-4000-8000-000000000001'
            : '00000000-0000-4000-8000-000000000002';
      },
    );
    final retainedIds = (await repository.read()).items.map((item) => item.id);

    expect(
      generator.generate(retainedIds),
      'meal_slot_00000000-0000-4000-8000-000000000002',
    );
    expect(calls, 2);
  });
}

const _customId = 'meal_slot_00000000-0000-4000-8000-000000000001';

MealCategoriesConfig _configWithCustom({required bool active}) =>
    MealCategoriesConfig(
      items: [
        ...MealCategoriesConfig.canonicalDefaults().items,
        MealCategory(
          id: _customId,
          defaultKey: null,
          displayName: 'Pre Workout',
          active: active,
          order: 4,
        ),
      ],
    );

Matcher _throwsCode(MealCategoriesValidationCode code) => throwsA(
      isA<MealCategoriesValidationException>()
          .having((error) => error.code, 'code', code),
    );
