import 'package:characters/characters.dart';
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

    test('a custom category reorders without renumbering default IDs', () {
      // Corrected by owner decision: canonical defaults hold a fixed relative
      // order, so what may move is a custom category — around and between the
      // anchors, never through them.
      final defaults = MealCategoriesConfig.canonicalDefaults();
      const customId = 'meal_slot_dddddddd-dddd-4ddd-8ddd-dddddddddddd';

      final withCustom = MealCategoriesConfig(
        items: [
          ...defaults.items,
          MealCategory(
            id: customId,
            defaultKey: null,
            displayName: 'Pre Workout',
            active: true,
            order: 4,
          ),
        ],
      );
      expect(withCustom.items.last.id, customId, reason: 'starts after Snacks');

      // Move it between Breakfast and Lunch.
      final moved = MealCategoriesConfig(
        items: [
          for (final item in withCustom.items)
            if (item.id == customId)
              item.reordered(1)
            else if (item.order >= 1)
              item.reordered(item.order + 1)
            else
              item,
        ],
      );

      moved.validate();
      expect(
        moved.items.map((item) => item.id),
        [
          'meal_slot_1',
          customId,
          'meal_slot_2',
          'meal_slot_3',
          'meal_slot_4',
        ],
      );
      expect(
        moved.findById('meal_slot_2')!.defaultKey,
        MealCategoryDefaultKey.lunch,
        reason: 'identity is untouched by a neighbour moving',
      );
    });

    test('rejects inverting two canonical defaults', () {
      final defaults = MealCategoriesConfig.canonicalDefaults();

      expect(
        () => MealCategoriesConfig(
          items: [
            for (final item in defaults.items)
              if (item.id == 'meal_slot_2')
                item.reordered(2)
              else if (item.id == 'meal_slot_3')
                item.reordered(1)
              else
                item,
          ],
        ),
        _throwsCode(
          MealCategoriesValidationCode.canonicalDefaultOrderViolated,
        ),
      );
    });

    test('ordering follows identity rather than display name', () {
      // Renaming Lunch to something alphabetically earlier must not move it.
      final defaults = MealCategoriesConfig.canonicalDefaults();
      final renamed = MealCategoriesConfig(
        items: [
          for (final item in defaults.items)
            if (item.id == 'meal_slot_2') item.renamed('Aaa Pre Workout') else item,
        ],
      );

      renamed.validate();
      expect(
        renamed.items.map((item) => item.id),
        ['meal_slot_1', 'meal_slot_2', 'meal_slot_3', 'meal_slot_4'],
      );
      expect(
        renamed.findById('meal_slot_2')!.defaultKey,
        MealCategoryDefaultKey.lunch,
      );
    });

    test('stores a defensive copy in canonical semantic order', () {
      final source =
          MealCategoriesConfig.canonicalDefaults().items.reversed.toList();

      final config = MealCategoriesConfig(items: source);
      source.clear();

      expect(config.items.map((item) => item.id), [
        'meal_slot_1',
        'meal_slot_2',
        'meal_slot_3',
        'meal_slot_4',
      ]);
      expect(
        () => config.items.add(config.items.first),
        throwsUnsupportedError,
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

    test('rejects an invalid injected UUID deterministically', () {
      final generator = UuidMealCategoryIdGenerator(
        uuidV4: () => 'not-a-uuid',
      );

      expect(
        () => generator.generate(const []),
        _throwsCode(MealCategoriesValidationCode.invalidGeneratedId),
      );
    });

    test('fails after the configured collision-attempt bound', () {
      var calls = 0;
      final generator = UuidMealCategoryIdGenerator(
        uuidV4: () {
          calls++;
          return '00000000-0000-4000-8000-000000000001';
        },
        maxAttempts: 2,
      );

      expect(
        () => generator.generate(const [
          'meal_slot_00000000-0000-4000-8000-000000000001',
        ]),
        _throwsCode(MealCategoriesValidationCode.idGenerationExhausted),
      );
      expect(calls, 2);
    });

    test('requires a positive collision-attempt bound', () {
      expect(
        () => UuidMealCategoryIdGenerator(maxAttempts: 0),
        throwsArgumentError,
      );
    });
  });

  group('policy validation', () {
    test('rejects zero active categories even with defaults retained', () {
      // Corrected by owner decision: every meal has to be filed under
      // something, so a configuration with nothing active is not a state the
      // app can be in. Retaining the identities does not make it valid.
      final defaults = MealCategoriesConfig.canonicalDefaults();

      expect(
        () => MealCategoriesConfig(
          items: defaults.items.map((item) => item.withActive(false)),
        ),
        _throwsCode(MealCategoriesValidationCode.tooFewActiveCategories),
      );
    });

    test('accepts exactly one active category', () {
      final defaults = MealCategoriesConfig.canonicalDefaults();
      final config = MealCategoriesConfig(
        items: [
          defaults.items.first,
          for (final item in defaults.items.skip(1)) item.withActive(false),
        ],
      );

      config.validate();
      expect(config.activeItems, hasLength(1));
      expect(config.items, hasLength(4), reason: 'identities all retained');
    });

    test('accepts exactly eight active categories', () {
      final config = _configWithCustomCategories(
        customCount: 4,
        activeCustomCount: 4,
      );

      expect(config.activeItems, hasLength(8));
    });

    test('rejects a ninth active category without truncating state', () {
      final items = _itemsWithCustomCategories(
        customCount: 5,
        activeCustomCount: 5,
      );

      expect(items, hasLength(9));
      expect(
        () => MealCategoriesConfig(items: items),
        _throwsCode(MealCategoriesValidationCode.tooManyActiveCategories),
      );
      expect(items, hasLength(9));
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

    test('accepts a retained set exactly at the ceiling', () {
      // Four canonical defaults plus twenty-eight customs, four of them still
      // active, so the active cap is not what is being exercised here.
      final config = _configWithCustomCategories(
        customCount: 28,
        activeCustomCount: 4,
      );

      config.validate();
      expect(config.items, hasLength(32));
      expect(config.activeItems, hasLength(8));
    });

    test('rejects one retained category past the ceiling', () {
      final items = _itemsWithCustomCategories(
        customCount: 29,
        activeCustomCount: 4,
      );

      expect(items, hasLength(33));
      expect(
        () => MealCategoriesConfig(items: items),
        _throwsCode(MealCategoriesValidationCode.tooManyRetainedCategories),
      );
    });

    test('rejects an unbounded archived set rather than truncating it', () {
      // The case the ceiling exists for: archiving never deletes, so without
      // one the retained set grows forever and every later write rescans it.
      final items = _itemsWithCustomCategories(
        customCount: 512,
        activeCustomCount: 4,
      );

      expect(
        () => MealCategoriesConfig(items: items),
        _throwsCode(MealCategoriesValidationCode.tooManyRetainedCategories),
      );
      expect(items, hasLength(516), reason: 'nothing was truncated');
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
      expect(
        () => MealCategoriesConfig(
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
        ),
        _throwsCode(
          MealCategoriesValidationCode.duplicateActiveDisplayName,
        ),
      );
    });

    test('allows duplicate normalized names when both items are inactive', () {
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
          MealCategory(
            id: 'meal_slot_00000000-0000-4000-8000-000000000002',
            defaultKey: null,
            displayName: '  pre   WORKOUT  ',
            active: false,
            order: 5,
          ),
        ],
      );

      expect(config.items, hasLength(6));
      expect(config.activeItems, hasLength(4));
    });

    test('rejects custom IDs outside the lowercase UUID-v4 contract', () {
      expect(
        () => MealCategoriesConfig(
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
        ),
        _throwsCode(MealCategoriesValidationCode.invalidId),
      );
    });

    test('rejects duplicate durable IDs', () {
      expect(
        () => MealCategoriesConfig(
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
        ),
        _throwsCode(MealCategoriesValidationCode.duplicateId),
      );
    });

    test('rejects duplicate canonical default keys', () {
      expect(
        () => MealCategoriesConfig(
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
        ),
        _throwsCode(MealCategoriesValidationCode.duplicateDefaultKey),
      );
    });

    test('rejects a custom ID pretending to be a canonical default', () {
      final defaults = MealCategoriesConfig.canonicalDefaults();
      expect(
        () => MealCategoriesConfig(
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
        ),
        _throwsCode(MealCategoriesValidationCode.invalidDefaultMapping),
      );
    });

    test('rejects a config that drops a canonical default identity', () {
      final defaults = MealCategoriesConfig.canonicalDefaults();
      expect(
        () => MealCategoriesConfig(
          items: defaults.items.where(
            (item) => item.defaultKey != MealCategoryDefaultKey.snacks,
          ),
        ),
        _throwsCode(MealCategoriesValidationCode.missingCanonicalDefault),
      );
    });

    test('rejects duplicate ordering', () {
      expect(
        () => MealCategoriesConfig(
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
        ),
        _throwsCode(MealCategoriesValidationCode.duplicateOrder),
      );
    });

    test('rejects an unsupported schema version', () {
      expect(
        () => MealCategoriesConfig(
          schemaVersion: 2,
          items: MealCategoriesConfig.canonicalDefaults().items,
        ),
        _throwsCode(MealCategoriesValidationCode.unsupportedSchemaVersion),
      );
    });
  });

  group('display name policy', () {
    // Every case below is written in graphemes, because that is what the
    // reader counts and what the contract names.
    const limit = MealCategoryDisplayNamePolicy.maxLength;

    // Built from code points rather than pasted, so what each case exercises
    // is readable in the source instead of hiding inside a string literal.
    final tab = String.fromCharCode(0x09);
    final newline = String.fromCharCode(0x0A);
    final carriageReturn = String.fromCharCode(0x0D);
    final unitSeparator = String.fromCharCode(0x1F);
    final del = String.fromCharCode(0x7F);
    final nextLine = String.fromCharCode(0x85);
    final lineSeparator = String.fromCharCode(0x2028);
    final paragraphSeparator = String.fromCharCode(0x2029);
    final noBreakSpace = String.fromCharCode(0xA0);
    final zeroWidthSpace = String.fromCharCode(0x200B);
    final zeroWidthNonJoiner = String.fromCharCode(0x200C);
    final zeroWidthJoiner = String.fromCharCode(0x200D);

    // One grapheme, seven code points, held together by zero-width joiners.
    // Counted in UTF-16 code units it is eleven.
    final family = String.fromCharCodes([
      0x1F468,
      0x200D,
      0x1F469,
      0x200D,
      0x1F467,
      0x200D,
      0x1F466,
    ]);

    // A base letter and a combining acute: two code points, one grapheme.
    final combining = 'e${String.fromCharCode(0x0301)}';

    MealCategory custom(String displayName) => MealCategory(
          id: 'meal_slot_00000000-0000-4000-8000-000000000001',
          defaultKey: null,
          displayName: displayName,
          active: true,
          order: 4,
        );

    Matcher throwsInvalidCharacters() =>
        _throwsCode(MealCategoriesValidationCode.invalidDisplayNameCharacters);

    Matcher throwsTooLong() =>
        _throwsCode(MealCategoriesValidationCode.displayNameTooLong);

    test('the owner-locked limit is 24', () {
      expect(limit, 24);
    });

    test('accepts exactly 24 ASCII graphemes', () {
      final name = 'a' * limit;

      expect(name.characters.length, limit);
      expect(custom(name).displayName, name);
    });

    test('rejects 25 ASCII graphemes', () {
      expect(() => custom('a' * (limit + 1)), throwsTooLong());
    });

    test('counts a ZWJ emoji as one grapheme, not as its code units', () {
      final name = family * limit;

      expect(name.characters.length, limit);
      expect(
        name.length,
        greaterThan(limit),
        reason: 'a code-unit limit would have refused this name',
      );
      expect(custom(name).displayName, name);
    });

    test('rejects 25 ZWJ emoji graphemes', () {
      expect(() => custom(family * (limit + 1)), throwsTooLong());
    });

    test('a joiner inside a valid emoji is not a control-character failure',
        () {
      // The ZWJ is non-printing, but rejecting non-printing code points as a
      // class would tear this grapheme into four.
      expect(custom(family).displayName, family);
    });

    test('counts a combining mark as part of its grapheme', () {
      expect(combining.characters.length, 1);
      expect(combining.length, 2);

      expect(custom(combining * limit).displayName, combining * limit);
      expect(() => custom(combining * (limit + 1)), throwsTooLong());
    });

    test('refuses an over-long name rather than cutting it to fit', () {
      final tooLong = 'a' * (limit + 1);

      expect(() => custom(tooLong), throwsTooLong());
      expect(tooLong, hasLength(limit + 1), reason: 'nothing was truncated');
    });

    test('canonicalizes outer and repeated inner whitespace', () {
      expect(custom('  Pre   Workout  ').displayName, 'Pre Workout');
      expect(
        custom('Pre$noBreakSpace${noBreakSpace}Workout').displayName,
        'Pre Workout',
        reason: 'a pasted no-break space stands in for an ordinary space',
      );
    });

    test('preserves the case the reader typed', () {
      expect(custom('  pre   WORKOUT ').displayName, 'pre WORKOUT');
    });

    test('rejects a line break inside a non-blank name', () {
      for (final breaker in [
        newline,
        carriageReturn,
        nextLine,
        lineSeparator,
      ]) {
        expect(() => custom('Pre${breaker}Workout'), throwsInvalidCharacters());
      }
    });

    test('rejects a tab or other control character inside a name', () {
      for (final control in [tab, unitSeparator, del]) {
        expect(() => custom('Pre${control}Workout'), throwsInvalidCharacters());
      }
    });

    test('rejects a forbidden character at the start of a name', () {
      // The bug this guards: `trim()` deletes every one of these, so checking
      // a trimmed copy would hand back an accepted `Lunch` for input the
      // contract says is refused.
      for (final control in [
        newline,
        carriageReturn,
        tab,
        nextLine,
        unitSeparator,
        del,
        lineSeparator,
        paragraphSeparator,
      ]) {
        expect(() => custom('${control}Lunch'), throwsInvalidCharacters());
      }
    });

    test('rejects a forbidden character at the end of a name', () {
      for (final control in [
        newline,
        carriageReturn,
        tab,
        nextLine,
        unitSeparator,
        del,
        lineSeparator,
        paragraphSeparator,
      ]) {
        expect(() => custom('Lunch$control'), throwsInvalidCharacters());
      }
    });

    test('an outer forbidden character is never converted away', () {
      // Stated as the outcome rather than as the mechanism: whatever the
      // implementation does internally, these must not end up stored as
      // `Lunch`.
      for (final value in [
        'Lunch$newline',
        '${tab}Lunch',
        'Lunch$carriageReturn',
        '${nextLine}Lunch',
        'Lunch$lineSeparator',
      ]) {
        expect(() => custom(value), throwsInvalidCharacters());
      }
    });

    test('an outer forbidden character survives surrounding spaces', () {
      // Spaces around the control are legitimately trimmable, and trimming
      // them must not carry the control out with them.
      expect(() => custom('  Lunch$newline  '), throwsInvalidCharacters());
      expect(() => custom('  ${tab}Lunch  '), throwsInvalidCharacters());
    });

    test('ordinary outer whitespace is still trimmed', () {
      expect(custom('  Lunch  ').displayName, 'Lunch');
      expect(
        custom('$noBreakSpace Lunch $noBreakSpace').displayName,
        'Lunch',
        reason: 'a space separator is not a control character',
      );
    });

    test('rejects a name made of nothing but zero-width spaces', () {
      // The sharpest case. U+200B is not matched by `\s` and is not Unicode
      // White_Space, so `trim()` leaves it and the blank check never sees it.
      // Without a rule of its own this stored a category with an invisible
      // label.
      expect(() => custom(zeroWidthSpace), throwsInvalidCharacters());
      expect(() => custom(zeroWidthSpace * 4), throwsInvalidCharacters());
      expect(
        zeroWidthSpace.trim(),
        isNotEmpty,
        reason: 'this is why the blank check cannot catch it',
      );
    });

    test('rejects a zero-width space at either end of a name', () {
      expect(() => custom('${zeroWidthSpace}Lunch'), throwsInvalidCharacters());
      expect(() => custom('Lunch$zeroWidthSpace'), throwsInvalidCharacters());
      expect(
        () => custom('  ${zeroWidthSpace}Lunch  '),
        throwsInvalidCharacters(),
        reason: 'trimmable spaces around it do not carry it out',
      );
    });

    test('rejects a zero-width space embedded in a name', () {
      expect(
        () => custom('Pre${zeroWidthSpace}Workout'),
        throwsInvalidCharacters(),
      );
      expect(
        () => custom('Pre$zeroWidthSpace Workout'),
        throwsInvalidCharacters(),
        reason: 'an invisible break beside a real space is still refused',
      );
    });

    test('a canonical default rename cannot take a zero-width space either',
        () {
      final lunch =
          MealCategoriesConfig.canonicalDefaults().findById('meal_slot_2')!;

      expect(
        () => lunch.renamed('Pre${zeroWidthSpace}Workout'),
        throwsInvalidCharacters(),
      );
    });

    test('ZWNJ stays accepted where the name is otherwise valid', () {
      // U+200C is required for correct Hindi and Persian text. The rule names
      // one code point rather than a class precisely so this keeps working.
      expect(
        custom('Pre${zeroWidthNonJoiner}Workout').displayName,
        'Pre${zeroWidthNonJoiner}Workout',
      );
      expect(
        custom('अ$zeroWidthNonJoinerआ').displayName,
        'अ$zeroWidthNonJoinerआ',
      );
    });

    test('ZWJ stays accepted, inside an emoji and on its own', () {
      // The owner contract keeps U+200D allowed. The family emoji regressions
      // above cover the cluster; this pins the code point itself.
      expect(
        custom('Pre${zeroWidthJoiner}Workout').displayName,
        'Pre${zeroWidthJoiner}Workout',
      );
      expect(custom(family * limit).displayName, family * limit);
    });

    test('the rejection is one named code point, not a class of them', () {
      // U+2060 WORD JOINER sits outside the boundary the owner locked. Pinned
      // so widening the rule to "all format characters" fails here and gets
      // an owner decision rather than arriving by accident.
      final wordJoiner = String.fromCharCode(0x2060);

      expect(
        custom('Pre${wordJoiner}Workout').displayName,
        'Pre${wordJoiner}Workout',
      );
    });

    test('whitespace-only input still reads as blank, not as a control', () {
      for (final value in ['', '   ', '$newline$tab']) {
        expect(
          () => custom(value),
          _throwsCode(MealCategoriesValidationCode.blankDisplayName),
        );
      }
    });

    test('a canonical default rename obeys the same rules as a custom add', () {
      final lunch =
          MealCategoriesConfig.canonicalDefaults().findById('meal_slot_2')!;

      expect(lunch.renamed('  Pre   Workout  ').displayName, 'Pre Workout');
      expect(lunch.renamed(family * limit).displayName, family * limit);
      expect(() => lunch.renamed('a' * (limit + 1)), throwsTooLong());
      expect(
        () => lunch.renamed('Pre${tab}Workout'),
        throwsInvalidCharacters(),
      );
    });

    test('duplicate comparison and storage share one whitespace rule', () {
      expect(
        MealCategoriesPolicy.normalizeDisplayName('  Pre   Workout  '),
        MealCategoriesPolicy.normalizeDisplayName('pre workout'),
      );
      expect(
        MealCategoryDisplayNamePolicy.comparisonKey(
          MealCategoryDisplayNamePolicy.canonicalize('  PRE   workout '),
        ),
        MealCategoriesPolicy.normalizeDisplayName('Pre Workout'),
      );
    });

    test('an active duplicate is still refused after canonicalization', () {
      expect(
        () => MealCategoriesConfig(
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
        ),
        _throwsCode(MealCategoriesValidationCode.duplicateActiveDisplayName),
      );
    });
  });
}

MealCategoriesConfig _configWithCustomCategories({
  required int customCount,
  required int activeCustomCount,
}) =>
    MealCategoriesConfig(
      items: _itemsWithCustomCategories(
        customCount: customCount,
        activeCustomCount: activeCustomCount,
      ),
    );

List<MealCategory> _itemsWithCustomCategories({
  required int customCount,
  required int activeCustomCount,
}) =>
    [
      ...MealCategoriesConfig.canonicalDefaults().items,
      for (var index = 0; index < customCount; index++)
        MealCategory(
          id: 'meal_slot_00000000-0000-4000-8000-${(index + 1).toString().padLeft(12, '0')}',
          defaultKey: null,
          displayName: 'Custom ${index + 1}',
          active: index < activeCustomCount,
          order: index + 4,
        ),
    ];

Matcher _throwsCode(MealCategoriesValidationCode code) => throwsA(
      isA<MealCategoriesValidationException>()
          .having((error) => error.code, 'code', code),
    );
