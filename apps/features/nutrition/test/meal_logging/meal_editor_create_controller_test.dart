import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

void main() {
  test('derives complete meal totals from all current draft items', () {
    final controller = MealEditorCreateController(
      initialDraft: _draft(
        items: [
          _item(
            name: 'Roti',
            quantity: 2,
            unit: 'piece',
            energy: 200,
            protein: 8,
            carbs: 36,
            fat: 4,
          ),
          _item(
            name: 'Curd',
            quantity: 150,
            unit: 'g',
            energy: 90,
            protein: 5,
            carbs: 7,
            fat: 4,
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    final summary = controller.nutritionSummary;
    expect(summary.energyKcal, 290);
    expect(summary.proteinGrams, 13);
    expect(summary.carbohydrateGrams, 43);
    expect(summary.fatGrams, 8);
  });

  test('unknown nutrient makes the meal total unknown while explicit zero stays known',
      () {
    final controller = MealEditorCreateController(
      initialDraft: _draft(
        items: [
          _item(
            name: 'Cucumber',
            quantity: 1,
            unit: 'piece',
            energy: 20,
            protein: 0,
            carbs: 4,
            fat: 0,
          ),
          MealLoggingDraftItem(
            displayName: 'Unresolved sauce',
            quantity: 1,
            servingUnit: 'serving',
            consumedNutritionSnapshot: NutritionSnapshot(
              schemaVersion: 1,
              nutrients: const {
                NutrientId.energy: 50,
                NutrientId.carbohydrate: 3,
                NutrientId.fat: 2,
              },
            ),
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    final summary = controller.nutritionSummary;
    expect(summary.energyKcal, 70);
    expect(summary.proteinGrams, isNull);
    expect(summary.carbohydrateGrams, 7);
    expect(summary.fatGrams, 2);
  });

  test('same-unit quantity correction rescales consumed-total nutrition', () {
    final controller = MealEditorCreateController(
      initialDraft: _draft(
        items: [
          _item(
            name: 'Roti',
            quantity: 2,
            unit: 'piece',
            energy: 200,
            protein: 8,
            carbs: 36,
            fat: 4,
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    expect(controller.incrementQuantity(0), isTrue);
    expect(controller.items.single.quantity, 3);
    var snapshot = controller.items.single.consumedNutritionSnapshot!;
    expect(snapshot.amountFor(NutrientId.energy), 300);
    expect(snapshot.amountFor(NutrientId.protein), 12);
    expect(controller.nutritionSummary.energyKcal, 300);

    expect(controller.decrementQuantity(0), isTrue);
    expect(controller.items.single.quantity, 2);
    snapshot = controller.items.single.consumedNutritionSnapshot!;
    expect(snapshot.amountFor(NutrientId.energy), 200);
    expect(snapshot.amountFor(NutrientId.protein), 8);
  });

  test('unknown quantity is never fabricated by step controls', () {
    final controller = MealEditorCreateController(
      initialDraft: _draft(
        items: [
          MealLoggingDraftItem(
            displayName: 'Dal',
            consumedNutritionSnapshot: NutritionSnapshot(
              schemaVersion: 1,
              nutrients: const {NutrientId.energy: 180},
            ),
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    expect(controller.canIncrementQuantity(0), isFalse);
    expect(controller.canDecrementQuantity(0), isFalse);
    expect(controller.incrementQuantity(0), isFalse);
    expect(controller.decrementQuantity(0), isFalse);
    expect(controller.items.single.quantity, isNull);
    expect(
      controller.items.single.consumedNutritionSnapshot!
          .amountFor(NutrientId.energy),
      180,
    );
  });

  test('remove updates totals but refuses to create an empty valid draft', () {
    final controller = MealEditorCreateController(
      initialDraft: _draft(
        items: [
          _item(
            name: 'Roti',
            quantity: 1,
            unit: 'piece',
            energy: 100,
            protein: 4,
            carbs: 18,
            fat: 2,
          ),
          _item(
            name: 'Curd',
            quantity: 100,
            unit: 'g',
            energy: 60,
            protein: 4,
            carbs: 5,
            fat: 3,
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    expect(controller.removeItem(0), isTrue);
    expect(controller.items.single.displayName, 'Curd');
    expect(controller.nutritionSummary.energyKcal, 60);
    expect(controller.canRemoveItem(0), isFalse);
    expect(controller.removeItem(0), isFalse);
    expect(controller.items, hasLength(1));
    expect(controller.draft.items, hasLength(1));
  });

  test('meal-name edits remain draft-only and preserve capture provenance', () {
    final controller = MealEditorCreateController(
      initialDraft: _draft(
        mealName: 'Original meal',
        items: [
          _item(
            name: 'Roti',
            quantity: 1,
            unit: 'piece',
            energy: 100,
            protein: 4,
            carbs: 18,
            fat: 2,
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    controller.updateMealName('Edited meal');
    expect(controller.draft.mealName, 'Edited meal');
    expect(controller.draft.captureSource, MealLogCaptureSource.text);

    controller.updateMealName('   ');
    expect(controller.draft.mealName, isNull);
  });
}

MealLoggingDraft _draft({
  String? mealName = 'Lunch',
  required List<MealLoggingDraftItem> items,
}) {
  return MealLoggingDraft(
    mealName: mealName,
    captureSource: MealLogCaptureSource.text,
    items: items,
  );
}

MealLoggingDraftItem _item({
  required String name,
  required num quantity,
  required String unit,
  required num energy,
  required num protein,
  required num carbs,
  required num fat,
}) {
  return MealLoggingDraftItem(
    displayName: name,
    quantity: quantity,
    servingUnit: unit,
    consumedNutritionSnapshot: NutritionSnapshot(
      schemaVersion: 1,
      nutrients: {
        NutrientId.energy: energy,
        NutrientId.protein: protein,
        NutrientId.carbohydrate: carbs,
        NutrientId.fat: fat,
      },
    ),
  );
}
