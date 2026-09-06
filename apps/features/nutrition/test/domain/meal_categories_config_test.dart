import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

void main() {
  group('canonical defaults', () {
    test('absent config resolves the exact four canonical categories', () {
      final config = MealCategoriesConfig.resolve(null);

      expect(config.schemaVersion, MealCategoriesPolicy.currentSchemaVersion);
      expect(config.orderedItems, hasLength(4));
      expect(
        config.orderedItems.map((item) => item.id),
        ['meal_slot_1', 'meal_slot_2', 'meal_slot_3', 'meal_slot_4'],
      );
      expect(
        config.orderedItems.map((item) => item.defaultKey),
        MealCategoryDefaultKey.values,
      );
      expect(
        config.orderedItems.map((item) => item.displayName),
        ['Breakfast', 'Lunch', 'Dinner', 'Snacks'],
      );
      expect(config.orderedItems.every((item) => item.active), isTrue);
      expect(config.orderedItems.map((item) => item.order), [0, 1, 2, 3]);
    });
  });

  group('identity', () {
    test('rename changes displayName only', () {
      final defaults = MealCategoriesConfig.canonicalDefaults();
      final lunch = defaults.findById('meal_slot_2')!;

      final renamed = lunch.renamed('  Pre Workout  ');

      expect(renamed.id, 'meal_slot_2');
      expect(renamed.defaultKey, MealCategoryDefaultKey.lunch);
      expect(renamed.displayName, 'Pre Workout');
      expect(renamed.order, lunch.order);
      expect(renamed.active, lunch.active);
    });

    test('reorder changes order without renumbering default IDs', () {
      final defaults = MealCategoriesConfig.canonicalDefaults();
      final reordered = MealCategoriesConfig(
        items: [
          for (final item in defaults.items)
            if (item.id == 'meal_slot_2')
              item.reordered(2)
            else if (item.id == 'meal_slot_3')
              item.reordered(1)
            else
              item,
        ],
      );

      reordered.validate();
      expect(reordered.findById('meal_slot_2')!.order, 2);
      expect(
        reordered.findById('meal_slot_2')!.defaultKey,
        MealCategoryDefaultKey.lunch,
      );
      expect(reordered.findById('meal_slot_3')!.order, 1);
      expect(
        reordered.items.map((item) => item.id),
        ['meal_slot_1', 'meal_slot_2', 'meal_slot_3', 'meal_slot_4'],
      );
    });
  });

  group('custom identity generation', () {
    test('uses a lowercase UUID-v4 suffix and meal_slot prefix', () {
      final generator = UuidMealCategoryIdGenerator(
        uuidV4: () => 'AAAAAAAA-AAAA-4AAA-8AAA-AAAAAAAAAAAA',
      );

      expect(
        generator.generate(const []),
        'meal_slot_aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      );
    });

    test('same display label does not imply the same generated identity', () {
      var index = 0;
      final values = [
        '00000000-0000-4000-8000-000000000001',
        '00000000-0000-4000-8000-000000000002',
      ];
      final generator = UuidMealCategoryIdGenerator(
        uuidV4: () => values[index++],
      );

      final firstId = generator.generate(const []);
      final secondId = generator.generate([firstId]);
      final first = MealCategory(
        id: firstId,
        defaultKey: null,
        displayName: 'Pre Workout',
        active: true,
        order: 4,
      );
      final second = MealCategory(
        id: secondId,
        defaultKey: null,
        displayName: 'Pre Workout',
        active: false,
        order: 5,
      );

      expect(first.displayName, second.displayName);
      expect(first.id, isNot(second.id));
    });

    test('retries a collision against all retained IDs', () {
      var calls = 0;
      final generator = UuidMealCategoryIdGenerator(
        uuidV4: () {
          calls++;
          return calls == 1
              ? '00000000-0000-4000-8000-000000000001'
              : '00000000-0000-4000-8000-000000000002';
        },
      );

      final id = generator.generate(const [
        'meal_slot_00000000-0000-4000-8000-000000000001',
      ]);

      expect(id, 'meal_slot_00000000-0000-4000-8000-000000000002');
      expect(calls, 2);
    });

    test('does not reuse an archived retained identity', () {
      const archivedId = 'meal_slot_00000000-0000-4000-8000-000000000001';
      var calls = 0;
      final generator = UuidMealCategoryIdGenerator(
        uuidV4: () {
          calls++;
          return calls == 1
              ? '00000000-0000-4000-8000-000000000001'
              : '00000000-0000-4000-8000-000000000002';
        },
      );
      final config = _configWithCustomCategories(
        customCount: 1,
        activeCustomCount: 0,
      );

      expect(config.findById(archivedId)!.active, isFalse);
      expect(
        generator.generate(config.items.map((item) => item.id)),
        'meal_slot_00000000-0000-4000-8000-000000000002',
      );
    });
  });

  group('policy validation', () {
    test('accepts zero active categories when defaults remain retained', () {
      final defaults = MealCategoriesConfig.canonicalDefaults();
      final config = MealCategoriesConfig(
        items: defaults.items.map((item) => item.withActive(false)),
      );

      config.validate();
      expect(config.activeItems, isEmpty);
      expect(config.items, hasLength(4));
    });

    test('accepts exactly eight active categories', () {
      final config = _configWithCustomCategories(
        customCount: 4,
        activeCustomCount: 4,
      );

      expect(config.activeItems, hasLength(8));
    });

    test('rejects a ninth active category without truncating state', () {
      final config = _configWithCustomCategories(
        customCount: 5,
        activeCustomCount: 5,
      );

      expect(config.items, hasLength(9));
      expect(
        config.validate,
        _throwsCode(MealCategoriesValidationCode.tooManyActiveCategories),
      );
      expect(config.items, hasLength(9));
    });

    test('accepts eight active categories plus an archived retained item', () {
      final config = _configWithCustomCategories(
        customCount: 5,
        activeCustomCount: 4,
      );

      config.validate();
      expect(config.items, hasLength(9));
      expect(config.activeItems, hasLength(8));
    });

    test('rejects blank and whitespace-only display names', () {
      for (final value in ['', '   ', '\n\t']) {
        expect(
          () => MealCategory(
            id: 'meal_slot_custom',
            defaultKey: null,
            displayName: value,
            active: true,
            order: 4,
          ),
          _throwsCode(MealCategoriesValidationCode.blankDisplayName),
        );
      }
    });

    test('rejects duplicate normalized active display names', () {
      final config = MealCategoriesConfig(
        items: [
          ...MealCategoriesConfig.canonicalDefaults().items,
          MealCategory(
            id: 'meal_slot_00000000-0000-4000-8000-000000000001',
            defaultKey: null,
            displayName: 'Pre Workout',
            active: true,
            order: 4,
          ),
          MealCategory(
            id: 'meal_slot_00000000-0000-4000-8000-000000000002',
            defaultKey: null,
            displayName: '  pre   WORKOUT  ',
            active: true,
            order: 5,
          ),
        ],
      );

      expect(
        config.validate,
        _throwsCode(
          MealCategoriesValidationCode.duplicateActiveDisplayName,
        ),
      );
    });

    test('rejects custom IDs outside the lowercase UUID-v4 contract', () {
      final config = MealCategoriesConfig(
        items: [
          ...MealCategoriesConfig.canonicalDefaults().items,
          MealCategory(
            id: 'meal_slot_pre_workout',
            defaultKey: null,
            displayName: 'Pre Workout',
            active: false,
            order: 4,
          ),
        ],
      );

      expect(
        config.validate,
        _throwsCode(MealCategoriesValidationCode.invalidId),
      );
    });

    test('rejects duplicate durable IDs', () {
      final config = MealCategoriesConfig(
        items: [
          ...MealCategoriesConfig.canonicalDefaults().items,
          MealCategory(
            id: 'meal_slot_1',
            defaultKey: null,
            displayName: 'Early Meal',
            active: false,
            order: 4,
          ),
        ],
      );

      expect(
        config.validate,
        _throwsCode(MealCategoriesValidationCode.duplicateId),
      );
    });

    test('rejects duplicate canonical default keys', () {
      final config = MealCategoriesConfig(
        items: [
          ...MealCategoriesConfig.canonicalDefaults().items,
          MealCategory(
            id: 'meal_slot_00000000-0000-4000-8000-000000000001',
            defaultKey: MealCategoryDefaultKey.breakfast,
            displayName: 'Early Meal',
            active: false,
            order: 4,
          ),
        ],
      );

      expect(
        config.validate,
        _throwsCode(MealCategoriesValidationCode.duplicateDefaultKey),
      );
    });

    test('rejects a custom ID pretending to be a canonical default', () {
      final defaults = MealCategoriesConfig.canonicalDefaults();
      final config = MealCategoriesConfig(
        items: [
          MealCategory(
            id: 'meal_slot_00000000-0000-4000-8000-000000000001',
            defaultKey: MealCategoryDefaultKey.breakfast,
            displayName: 'Breakfast',
            active: true,
            order: 0,
          ),
          ...defaults.items.where(
            (item) => item.defaultKey != MealCategoryDefaultKey.breakfast,
          ),
        ],
      );

      expect(
        config.validate,
        _throwsCode(MealCategoriesValidationCode.invalidDefaultMapping),
      );
    });

    test('rejects a config that drops a canonical default identity', () {
      final defaults = MealCategoriesConfig.canonicalDefaults();
      final config = MealCategoriesConfig(
        items: defaults.items.where(
          (item) => item.defaultKey != MealCategoryDefaultKey.snacks,
        ),
      );

      expect(
        config.validate,
        _throwsCode(MealCategoriesValidationCode.missingCanonicalDefault),
      );
    });

    test('rejects duplicate ordering', () {
      final config = MealCategoriesConfig(
        items: [
          ...MealCategoriesConfig.canonicalDefaults().items,
          MealCategory(
            id: 'meal_slot_00000000-0000-4000-8000-000000000001',
            defaultKey: null,
            displayName: 'Pre Workout',
            active: false,
            order: 3,
          ),
        ],
      );

      expect(
        config.validate,
        _throwsCode(MealCategoriesValidationCode.duplicateOrder),
      );
    });

    test('rejects an unsupported schema version', () {
      final config = MealCategoriesConfig(
        schemaVersion: 2,
        items: MealCategoriesConfig.canonicalDefaults().items,
      );

      expect(
        config.validate,
        _throwsCode(MealCategoriesValidationCode.unsupportedSchemaVersion),
      );
    });
  });
}

MealCategoriesConfig _configWithCustomCategories({
  required int customCount,
  required int activeCustomCount,
}) {
  return MealCategoriesConfig(
    items: [
      ...MealCategoriesConfig.canonicalDefaults().items,
      for (var index = 0; index < customCount; index++)
        MealCategory(
          id: 'meal_slot_00000000-0000-4000-8000-${(index + 1).toString().padLeft(12, '0')}',
          defaultKey: null,
          displayName: 'Custom ${index + 1}',
          active: index < activeCustomCount,
          order: index + 4,
        ),
    ],
  );
}

Matcher _throwsCode(MealCategoriesValidationCode code) => throwsA(
      isA<MealCategoriesValidationException>()
          .having((error) => error.code, 'code', code),
    );
