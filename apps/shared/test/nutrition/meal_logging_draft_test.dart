import 'package:test/test.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('MealLoggingDraftItem', () {
    test('keeps provider-neutral editable item facts', () {
      final nutrition = NutritionSnapshot(
        schemaVersion: 1,
        nutrients: const <NutrientId, num>{
          NutrientId.energy: 210,
          NutrientId.protein: 7.5,
        },
      );
      final item = MealLoggingDraftItem(
        displayName: 'Dahi',
        quantity: 150,
        servingUnit: 'g',
        consumedNutritionSnapshot: nutrition,
      );

      expect(item.displayName, 'Dahi');
      expect(item.quantity, 150);
      expect(item.servingUnit, 'g');
      expect(item.consumedNutritionSnapshot, nutrition);
    });

    test('defines nutrition as the current consumed-total snapshot', () {
      final twoRoti = MealLoggingDraftItem(
        displayName: 'Roti',
        quantity: 2,
        servingUnit: 'piece',
        consumedNutritionSnapshot: NutritionSnapshot(
          schemaVersion: 1,
          nutrients: const <NutrientId, num>{NutrientId.energy: 200},
        ),
      );
      final oneRoti = MealLoggingDraftItem(
        displayName: 'Roti',
        quantity: 1,
        servingUnit: 'piece',
        consumedNutritionSnapshot: NutritionSnapshot(
          schemaVersion: 1,
          nutrients: const <NutrientId, num>{NutrientId.energy: 100},
        ),
      );
      final unresolvedAfterAmountEdit = MealLoggingDraftItem(
        displayName: 'Roti',
        quantity: 1,
        servingUnit: 'piece',
      );

      expect(
        twoRoti.consumedNutritionSnapshot!.amountFor(NutrientId.energy),
        200,
        reason: 'the snapshot is the total for the current quantity of two',
      );
      expect(
        oneRoti.consumedNutritionSnapshot!.amountFor(NutrientId.energy),
        100,
        reason: 'changing quantity requires a corrected consumed total',
      );
      expect(
        unresolvedAfterAmountEdit.consumedNutritionSnapshot,
        isNull,
        reason: 'an amount edit may clear nutrition until a new total is known',
      );
    });

    test('allows partial parse facts to remain unknown independently', () {
      final quantityOnly = MealLoggingDraftItem(
        displayName: 'Roti',
        quantity: 2,
      );
      final unitOnly = MealLoggingDraftItem(
        displayName: 'Milk',
        servingUnit: 'ml',
      );
      final nameOnly = MealLoggingDraftItem(displayName: 'Dal');

      expect(quantityOnly.quantity, 2);
      expect(quantityOnly.servingUnit, isNull);
      expect(quantityOnly.consumedNutritionSnapshot, isNull);

      expect(unitOnly.quantity, isNull);
      expect(unitOnly.servingUnit, 'ml');
      expect(unitOnly.consumedNutritionSnapshot, isNull);

      expect(nameOnly.quantity, isNull);
      expect(nameOnly.servingUnit, isNull);
      expect(nameOnly.consumedNutritionSnapshot, isNull);
    });

    test('preserves unknown nutrient versus explicit zero', () {
      final item = MealLoggingDraftItem(
        displayName: 'Cucumber',
        consumedNutritionSnapshot: NutritionSnapshot(
          schemaVersion: 1,
          nutrients: const <NutrientId, num>{NutrientId.energy: 0},
        ),
      );

      final nutrition = item.consumedNutritionSnapshot!;
      expect(nutrition.containsNutrient(NutrientId.energy), isTrue);
      expect(nutrition.amountFor(NutrientId.energy), 0);
      expect(nutrition.containsNutrient(NutrientId.protein), isFalse);
      expect(nutrition.amountFor(NutrientId.protein), isNull);
    });

    test('normalizes a blank serving unit to unknown', () {
      final item = MealLoggingDraftItem(
        displayName: 'Roti',
        servingUnit: '   ',
      );

      expect(item.servingUnit, isNull);
    });

    test('rejects a blank display name', () {
      expect(
        () => MealLoggingDraftItem(displayName: '   '),
        throwsArgumentError,
      );
    });

    test('rejects non-positive or non-finite present quantities', () {
      for (final quantity in <num>[
        0,
        -1,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => MealLoggingDraftItem(
            displayName: 'Roti',
            quantity: quantity,
          ),
          throwsArgumentError,
          reason: '$quantity is not a meaningful consumed quantity',
        );
      }
    });

    test('has deterministic value semantics', () {
      final first = MealLoggingDraftItem(
        displayName: 'Dal',
        quantity: 1,
        servingUnit: 'bowl',
        consumedNutritionSnapshot: NutritionSnapshot(
          schemaVersion: 1,
          nutrients: const <NutrientId, num>{NutrientId.energy: 180},
        ),
      );
      final second = MealLoggingDraftItem(
        displayName: 'Dal',
        quantity: 1,
        servingUnit: 'bowl',
        consumedNutritionSnapshot: NutritionSnapshot(
          schemaVersion: 1,
          nutrients: const <NutrientId, num>{NutrientId.energy: 180},
        ),
      );

      expect(second, first);
      expect(second.hashCode, first.hashCode);
    });
  });

  group('MealLoggingDraft', () {
    test('represents natural-language capture without provider identity', () {
      final draft = MealLoggingDraft(
        mealName: 'Lunch',
        captureSource: MealLogCaptureSource.text,
        items: <MealLoggingDraftItem>[
          MealLoggingDraftItem(
            displayName: 'Roti with ghee',
            quantity: 2,
            servingUnit: 'piece',
          ),
          MealLoggingDraftItem(
            displayName: 'Dahi',
            quantity: 150,
            servingUnit: 'g',
          ),
        ],
      );

      expect(draft.mealName, 'Lunch');
      expect(draft.captureSource, MealLogCaptureSource.text);
      expect(draft.items, hasLength(2));
      expect(draft.items.first.displayName, 'Roti with ghee');
    });

    test('normalizes a blank optional meal name to unknown', () {
      final draft = MealLoggingDraft(
        mealName: '   ',
        captureSource: MealLogCaptureSource.text,
        items: <MealLoggingDraftItem>[
          MealLoggingDraftItem(displayName: 'Dal'),
        ],
      );

      expect(draft.mealName, isNull);
    });

    test('rejects an empty successful draft', () {
      expect(
        () => MealLoggingDraft(
          captureSource: MealLogCaptureSource.text,
          items: const <MealLoggingDraftItem>[],
        ),
        throwsArgumentError,
      );
    });

    test('defensively copies and exposes an unmodifiable item list', () {
      final input = <MealLoggingDraftItem>[
        MealLoggingDraftItem(displayName: 'Dal'),
      ];
      final draft = MealLoggingDraft(
        captureSource: MealLogCaptureSource.text,
        items: input,
      );

      input.add(MealLoggingDraftItem(displayName: 'Rice'));

      expect(draft.items, hasLength(1));
      expect(
        () => draft.items.add(MealLoggingDraftItem(displayName: 'Roti')),
        throwsUnsupportedError,
      );
    });

    test('has ordered draft value semantics', () {
      MealLoggingDraft build() => MealLoggingDraft(
            mealName: 'Dinner',
            captureSource: MealLogCaptureSource.text,
            items: <MealLoggingDraftItem>[
              MealLoggingDraftItem(displayName: 'Dal'),
              MealLoggingDraftItem(displayName: 'Rice'),
            ],
          );

      final first = build();
      final second = build();
      final reversed = MealLoggingDraft(
        mealName: 'Dinner',
        captureSource: MealLogCaptureSource.text,
        items: first.items.reversed.toList(),
      );

      expect(second, first);
      expect(second.hashCode, first.hashCode);
      expect(reversed, isNot(first));
    });
  });
}
