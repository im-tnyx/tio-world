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

  test('round-trip canonicalizes valid shuffled input by semantic order', () {
    final config = MealCategoriesConfig(
      items: MealCategoriesConfig.canonicalDefaults().items.reversed,
    );

    final decoded = MealCategoriesConfigCodec.decode(
      MealCategoriesConfigCodec.encode(config),
    );

    expect(decoded, config);
    expect(config.items.map((item) => item.order), [0, 1, 2, 3]);
  });

  test('does not infer identity from display name', () {
    final raw = _validEncodedDefaults();
    final items = raw['items']! as List<Object?>;
    final lunch = items[1] as Map<String, Object?>;
    lunch['display_name'] = 'Pre Workout';

    final decoded = MealCategoriesConfigCodec.decode(raw)!;

    expect(decoded.findById('meal_slot_2')!.displayName, 'Pre Workout');
    expect(
      decoded.findById('meal_slot_2')!.defaultKey,
      MealCategoryDefaultKey.lunch,
      reason: 'renaming never reassigns the canonical anchor',
    );
    expect(decoded.findById('meal_slot_2')!.order, 1);
  });

  test('rejects a persisted config that inverts two canonical defaults', () {
    // A hostile or corrupted row must not be able to smuggle in an ordering
    // the app itself refuses to produce.
    final raw = _validEncodedDefaults();
    final items = raw['items']! as List<Object?>;
    (items[1] as Map<String, Object?>)['order'] = 2;
    (items[2] as Map<String, Object?>)['order'] = 1;

    expect(
      () => MealCategoriesConfigCodec.decode(raw),
      throwsA(
        isA<MealCategoriesValidationException>().having(
          (error) => error.code,
          'code',
          MealCategoriesValidationCode.canonicalDefaultOrderViolated,
        ),
      ),
    );
  });

  test('rejects a persisted config with nothing active', () {
    final raw = _validEncodedDefaults();
    for (final item in raw['items']! as List<Object?>) {
      (item as Map<String, Object?>)['active'] = false;
    }

    expect(
      () => MealCategoriesConfigCodec.decode(raw),
      throwsA(
        isA<MealCategoriesValidationException>().having(
          (error) => error.code,
          'code',
          MealCategoriesValidationCode.tooFewActiveCategories,
        ),
      ),
    );
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

  test('accepts an explicit null default_key for a custom category', () {
    const customId = 'meal_slot_00000000-0000-4000-8000-000000000001';
    final raw = _validEncodedDefaults();
    final items = raw['items']! as List<Object?>;
    items.add(<String, Object?>{
      'id': customId,
      'default_key': null,
      'display_name': 'Pre Workout',
      'active': false,
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

  test('rejects missing, unknown, and wrongly typed item fields', () {
    final missingField = _validEncodedDefaults();
    _itemAt(missingField, 0).remove('display_name');

    final unknownField = _validEncodedDefaults();
    _itemAt(unknownField, 0)['future_field'] = true;

    expect(
      () => MealCategoriesConfigCodec.decode(missingField),
      _throwsCode(MealCategoriesValidationCode.malformedConfig),
    );
    expect(
      () => MealCategoriesConfigCodec.decode(unknownField),
      _throwsCode(MealCategoriesValidationCode.malformedConfig),
    );

    for (final invalidField in <String, Object?>{
      'id': 1,
      'display_name': false,
      'active': 'true',
      'order': 1.5,
      'default_key': 1,
    }.entries) {
      final raw = _validEncodedDefaults();
      _itemAt(raw, 0)[invalidField.key] = invalidField.value;

      expect(
        () => MealCategoriesConfigCodec.decode(raw),
        _throwsCode(MealCategoriesValidationCode.malformedConfig),
        reason: invalidField.key,
      );
    }
  });

  test('rejects non-string map keys and unknown default keys', () {
    final valid = _validEncodedDefaults();
    final nonStringKey = <Object?, Object?>{
      'schema_version': valid['schema_version'],
      'items': valid['items'],
      1: 'invalid',
    };
    final unknownDefaultKey = _validEncodedDefaults();
    _itemAt(unknownDefaultKey, 0)['default_key'] = 'brunch';

    expect(
      () => MealCategoriesConfigCodec.decode(nonStringKey),
      _throwsCode(MealCategoriesValidationCode.malformedConfig),
    );
    expect(
      () => MealCategoriesConfigCodec.decode(unknownDefaultKey),
      _throwsCode(MealCategoriesValidationCode.malformedConfig),
    );
  });

  test('applies shared order, default-key, and canonical-mapping policy', () {
    final duplicateOrder = _validEncodedDefaults();
    _itemAt(duplicateOrder, 1)['order'] = 0;

    final duplicateDefaultKey = _validEncodedDefaults();
    final duplicateItems = duplicateDefaultKey['items']! as List<Object?>;
    duplicateItems.add(<String, Object?>{
      'id': 'meal_slot_00000000-0000-4000-8000-000000000001',
      'default_key': 'breakfast',
      'display_name': 'Early Meal',
      'active': false,
      'order': 4,
    });

    final invalidMapping = _validEncodedDefaults();
    _itemAt(invalidMapping, 0)['id'] =
        'meal_slot_00000000-0000-4000-8000-000000000001';

    expect(
      () => MealCategoriesConfigCodec.decode(duplicateOrder),
      _throwsCode(MealCategoriesValidationCode.duplicateOrder),
    );
    expect(
      () => MealCategoriesConfigCodec.decode(duplicateDefaultKey),
      _throwsCode(MealCategoriesValidationCode.duplicateDefaultKey),
    );
    expect(
      () => MealCategoriesConfigCodec.decode(invalidMapping),
      _throwsCode(MealCategoriesValidationCode.invalidDefaultMapping),
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

  test('rejects a stored row holding more categories than may be kept', () {
    // The path that matters for a payload the app did not write. Archiving
    // never deletes, so a client writing straight to the API could otherwise
    // hand back a row that grows without limit.
    final oversized = _validEncodedDefaults();
    final items = oversized['items']! as List<Object?>;
    for (var index = 0; index < 512; index++) {
      items.add(<String, Object?>{
        'id':
            'meal_slot_00000000-0000-4000-8000-${(index + 1).toString().padLeft(12, '0')}',
        'default_key': null,
        'display_name': 'Archived ${index + 1}',
        // Archived, so the active cap is not what rejects this.
        'active': false,
        'order': index + 4,
      });
    }

    expect(
      () => MealCategoriesConfigCodec.decode(oversized),
      _throwsCode(MealCategoriesValidationCode.tooManyRetainedCategories),
    );
    expect(items, hasLength(516), reason: 'rejected, never trimmed to fit');
  });

  group('display name policy on decode', () {
    // Persisted state is not a trusted source. It can predate the policy, or
    // have been written straight to the row by a client talking to the API,
    // so decode has to be as strict as the editor — without owning a second
    // copy of the rule. `MealCategory`'s constructor is that single path.
    Map<String, Object?> configWith(String displayName) => <String, Object?>{
          'schema_version': 1,
          'items': <Object?>[
            for (final item
                in MealCategoriesConfig.canonicalDefaults().orderedItems)
              <String, Object?>{
                'id': item.id,
                'default_key': item.defaultKey?.storageValue,
                'display_name': item.displayName,
                'active': item.active,
                'order': item.order,
              },
            <String, Object?>{
              'id': 'meal_slot_00000000-0000-4000-8000-000000000001',
              'default_key': null,
              'display_name': displayName,
              'active': true,
              'order': 4,
            },
          ],
        };

    test('a stored name past the limit is rejected, not truncated', () {
      final overLong =
          'a' * (MealCategoryDisplayNamePolicy.maxLength + 1);

      expect(
        () => MealCategoriesConfigCodec.decode(configWith(overLong)),
        _throwsCode(MealCategoriesValidationCode.displayNameTooLong),
      );
    });

    test('a stored name carrying a control character is rejected', () {
      expect(
        () => MealCategoriesConfigCodec.decode(
          configWith('Pre${String.fromCharCode(0x09)}Workout'),
        ),
        _throwsCode(
          MealCategoriesValidationCode.invalidDisplayNameCharacters,
        ),
      );
    });

    test('a stored name wrapped in control characters is rejected', () {
      // Persisted state is the case the trim-first ordering would have let
      // through: a row written straight to the API as "Lunch\n" must not be
      // read back as a clean `Lunch`.
      for (final control in [
        0x0A, // LF
        0x0D, // CR
        0x09, // tab
        0x85, // NEL, a C1 control
        0x2028, // LINE SEPARATOR
        0x2029, // PARAGRAPH SEPARATOR
      ]) {
        final character = String.fromCharCode(control);

        expect(
          () => MealCategoriesConfigCodec.decode(
            configWith('${character}Pre Workout'),
          ),
          _throwsCode(
            MealCategoriesValidationCode.invalidDisplayNameCharacters,
          ),
          reason: 'leading U+${control.toRadixString(16).toUpperCase()}',
        );
        expect(
          () => MealCategoriesConfigCodec.decode(
            configWith('Pre Workout$character'),
          ),
          _throwsCode(
            MealCategoriesValidationCode.invalidDisplayNameCharacters,
          ),
          reason: 'trailing U+${control.toRadixString(16).toUpperCase()}',
        );
      }
    });

    test('a stored canonical default is held to the same rule', () {
      // Not only custom rows: a canonical default written directly to the API
      // goes through the same constructor.
      final raw = <String, Object?>{
        'schema_version': 1,
        'items': <Object?>[
          for (final item
              in MealCategoriesConfig.canonicalDefaults().orderedItems)
            <String, Object?>{
              'id': item.id,
              'default_key': item.defaultKey?.storageValue,
              'display_name': item.id == 'meal_slot_2'
                  ? 'Lunch${String.fromCharCode(0x0A)}'
                  : item.displayName,
              'active': item.active,
              'order': item.order,
            },
        ],
      };

      expect(
        () => MealCategoriesConfigCodec.decode(raw),
        _throwsCode(MealCategoriesValidationCode.invalidDisplayNameCharacters),
      );
    });

    test('a persisted zero-width space cannot be read back in', () {
      // A row written straight to the API. U+200B survives `trim()`, so
      // without its own rule this decoded into a category with an invisible
      // label.
      final zeroWidthSpace = String.fromCharCode(0x200B);

      for (final stored in [
        zeroWidthSpace,
        '${zeroWidthSpace}Pre Workout',
        'Pre Workout$zeroWidthSpace',
        'Pre${zeroWidthSpace}Workout',
      ]) {
        expect(
          () => MealCategoriesConfigCodec.decode(configWith(stored)),
          _throwsCode(
            MealCategoriesValidationCode.invalidDisplayNameCharacters,
          ),
        );
      }
    });

    test('a persisted ZWNJ or ZWJ is still read back', () {
      // The rule names one code point, not a class, so Hindi and Persian
      // names and emoji clusters keep decoding.
      final zeroWidthNonJoiner = String.fromCharCode(0x200C);
      final zeroWidthJoiner = String.fromCharCode(0x200D);

      for (final stored in [
        'Pre${zeroWidthNonJoiner}Workout',
        'Pre${zeroWidthJoiner}Workout',
      ]) {
        final decoded = MealCategoriesConfigCodec.decode(configWith(stored))!;

        expect(
          decoded
              .findById('meal_slot_00000000-0000-4000-8000-000000000001')!
              .displayName,
          stored,
        );
      }
    });

    test('a stored name is canonicalized on the way in', () {
      final decoded =
          MealCategoriesConfigCodec.decode(configWith('  Pre   Workout  '))!;

      expect(
        decoded
            .findById('meal_slot_00000000-0000-4000-8000-000000000001')!
            .displayName,
        'Pre Workout',
      );
      expect(
        MealCategoriesConfigCodec.encode(decoded),
        MealCategoriesConfigCodec.encode(
          MealCategoriesConfigCodec.decode(configWith('Pre Workout'))!,
        ),
        reason: 'the same name however it was spaced when it was stored',
      );
    });
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

Map<String, Object?> _itemAt(Map<String, Object?> raw, int index) =>
    (raw['items']! as List<Object?>)[index] as Map<String, Object?>;

Matcher _throwsCode(MealCategoriesValidationCode code) => throwsA(
      isA<MealCategoriesValidationException>()
          .having((error) => error.code, 'code', code),
    );
