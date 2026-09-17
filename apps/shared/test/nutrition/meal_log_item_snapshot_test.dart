import 'package:test/test.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('MealLogItemSnapshot', () {
    NutritionSnapshot nutrition({Map<NutrientId, num>? nutrients}) {
      return NutritionSnapshot(
        schemaVersion: 1,
        nutrients: nutrients ??
            const <NutrientId, num>{
              NutrientId.energy: 250,
              NutrientId.protein: 12,
            },
      );
    }

    MealLogItemSnapshot build({
      String id = 'item-1',
      String mealLogEntryId = 'meal-1',
      String displayName = 'Paneer tikka',
      String? brandName = 'Local Kitchen',
      num quantity = 150,
      String servingUnit = 'g',
      NutritionSnapshot? snapshot,
    }) {
      return MealLogItemSnapshot(
        id: id,
        mealLogEntryId: mealLogEntryId,
        displayName: displayName,
        brandName: brandName,
        quantity: quantity,
        servingUnit: servingUnit,
        nutritionSnapshot: snapshot ?? nutrition(),
      );
    }

    test('preserves confirmed provider-independent consumed facts', () {
      final snapshot = nutrition(
        nutrients: const <NutrientId, num>{
          NutrientId.energy: 0,
          NutrientId.protein: 12,
        },
      );
      final item = build(snapshot: snapshot);

      expect(item.id, 'item-1');
      expect(item.mealLogEntryId, 'meal-1');
      expect(item.displayName, 'Paneer tikka');
      expect(item.brandName, 'Local Kitchen');
      expect(item.quantity, 150);
      expect(item.servingUnit, 'g');
      expect(item.nutritionSnapshot, same(snapshot));
      expect(item.nutritionSnapshot.amountFor(NutrientId.energy), 0);
      expect(item.nutritionSnapshot.amountFor(NutrientId.fat), isNull);
    });

    test('normalizes blank optional brand to absent without fabricating data', () {
      expect(build(brandName: null).brandName, isNull);
      expect(build(brandName: '').brandName, isNull);
      expect(build(brandName: '   \t').brandName, isNull);
      expect(build(brandName: '  Brand  ').brandName, '  Brand  ');
    });

    test('rejects blank required text and ambiguous identities', () {
      expect(() => build(id: ''), throwsArgumentError);
      expect(() => build(id: ' item-1 '), throwsArgumentError);
      expect(() => build(mealLogEntryId: ''), throwsArgumentError);
      expect(() => build(mealLogEntryId: ' meal-1 '), throwsArgumentError);
      expect(() => build(displayName: '   \t'), throwsArgumentError);
      expect(() => build(servingUnit: '   \t'), throwsArgumentError);
    });

    test('rejects non-positive and non-finite consumed quantity', () {
      expect(() => build(quantity: 0), throwsArgumentError);
      expect(() => build(quantity: -1), throwsArgumentError);
      expect(() => build(quantity: double.nan), throwsArgumentError);
      expect(() => build(quantity: double.infinity), throwsArgumentError);
      expect(() => build(quantity: double.negativeInfinity), throwsArgumentError);
    });

    test('keeps an empty current-registry nutrition view representable', () {
      final empty = NutritionSnapshot(
        schemaVersion: 99,
        nutrients: const <NutrientId, num>{},
      );

      final item = build(snapshot: empty);

      expect(item.nutritionSnapshot, same(empty));
      expect(item.nutritionSnapshot.nutrients, isEmpty);
    });

    test('has deterministic value semantics', () {
      final first = build();
      final second = build();
      final different = build(quantity: 151);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(different));
    });
  });
}
