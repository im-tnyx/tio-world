import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

void main() {
  test('null decodes as absent customization and resolves to defaults', () {
    final decoded = MealCategoriesConfigCodec.decode(null);

    expect(decoded, isNull);
    expect(MealCategoriesConfig.resolve(decoded).items, hasLength(4));
  });

  test('V1 round-trip is deterministic and lossless', () {
    final config = MealCategoriesConfig(
      items: [
        ...MealCategoriesConfig.canonicalDefaults().items,
        MealCategory(
          id: 'meal_slot_00000000-0000-4000-8000-000000000001',
          defaultKey: null,
          displayName: 'Pre Workout',
          active: false,
          order: 4,
        ),
      ],
    );

    final encoded = MealCategoriesConfigCodec.encode(config);
    final decoded = MealCategoriesConfigCodec.decode(encoded);

    expect(decoded, config);
    expect(MealCategoriesConfigCodec.encode(decoded!), encoded);
    expect(encoded.keys, ['schema_version', 'items']);
  });

  test('does not infer identity from display name or order', () {
    final raw = _validEncodedDefaults();
    final items = raw['items']! as List<Object?>;
    final lunch = items[1] as Map<String, Object?>;
    lunch['display_name'] = 'Pre Workout';
    lunch['order'] = 2;
    final dinner = items[2] as Map<String, Object?>;
    dinner['order'] = 1;

    final decoded = MealCategoriesConfigCodec.decode(raw)!;

    expect(decoded.findById('meal_slot_2')!.displayName, 'Pre Workout');
    expect(
      decoded.findById('meal_slot_2')!.defaultKey,
      MealCategoryDefaultKey.lunch,
    );
    expect(decoded.findById('meal_slot_2')!.order, 2);
  });

  test('accepts an absent default_key for a custom category', () {
    const customId = 'meal_slot_00000000-0000-4000-8000-000000000001';
    final raw = _validEncodedDefaults();
    final items = raw['items']! as List<Object?>;
    items.add(<String, Object?>{
      'id': customId,
      'display_name': 'Pre Workout',
      'active': true,
      'order': 4,
    });

    final decoded = MealCategoriesConfigCodec.decode(raw)!;

    expect(decoded.findById(customId)!.defaultKey, isNull);
  });

  test('rejects unsupported schema versions', () {
    final raw = _validEncodedDefaults()..['schema_version'] = 2;

    expect(
      () => MealCategoriesConfigCodec.decode(raw),
      _throwsCode(MealCategoriesValidationCode.unsupportedSchemaVersion),
    );
  });

  test('rejects malformed field types and unknown V1 fields', () {
    final wrongType = _validEncodedDefaults()..['schema_version'] = '1';
    final unknownField = _validEncodedDefaults()..['future_field'] = true;

    expect(
      () => MealCategoriesConfigCodec.decode(wrongType),
      _throwsCode(MealCategoriesValidationCode.malformedConfig),
    );
    expect(
      () => MealCategoriesConfigCodec.decode(unknownField),
      _throwsCode(MealCategoriesValidationCode.malformedConfig),
    );
    expect(
      () => MealCategoriesConfigCodec.decode(const ['not', 'an', 'object']),
      _throwsCode(MealCategoriesValidationCode.malformedConfig),
    );
  });

  test('rejects duplicate IDs and more than eight active items', () {
    final duplicate = _validEncodedDefaults();
    final duplicateItems = duplicate['items']! as List<Object?>;
    duplicateItems.add(<String, Object?>{
      'id': 'meal_slot_1',
      'default_key': null,
      'display_name': 'Duplicate',
      'active': false,
      'order': 4,
    });

    expect(
      () => MealCategoriesConfigCodec.decode(duplicate),
      _throwsCode(MealCategoriesValidationCode.duplicateId),
    );

    final tooMany = _validEncodedDefaults();
    final tooManyItems = tooMany['items']! as List<Object?>;
    for (var index = 0; index < 5; index++) {
      tooManyItems.add(<String, Object?>{
        'id':
            'meal_slot_00000000-0000-4000-8000-${(index + 1).toString().padLeft(12, '0')}',
        'default_key': null,
        'display_name': 'Custom ${index + 1}',
        'active': true,
        'order': index + 4,
      });
    }

    expect(
      () => MealCategoriesConfigCodec.decode(tooMany),
      _throwsCode(MealCategoriesValidationCode.tooManyActiveCategories),
    );
    expect(tooManyItems, hasLength(9));
  });
}

Map<String, Object?> _validEncodedDefaults() {
  return <String, Object?>{
    'schema_version': 1,
    'items': <Object?>[
      for (final item in MealCategoriesConfig.canonicalDefaults().orderedItems)
        <String, Object?>{
          'id': item.id,
          'default_key': item.defaultKey!.storageValue,
          'display_name': item.displayName,
          'active': item.active,
          'order': item.order,
        },
    ],
  };
}

Matcher _throwsCode(MealCategoriesValidationCode code) => throwsA(
      isA<MealCategoriesValidationException>()
          .having((error) => error.code, 'code', code),
    );
