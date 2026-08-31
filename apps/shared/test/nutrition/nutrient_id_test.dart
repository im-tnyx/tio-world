import 'package:test/test.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const expectedRegistry = <NutrientId, (String, NutrientUnit)>{
    NutrientId.energy: ('energy', NutrientUnit.kcal),
    NutrientId.protein: ('protein', NutrientUnit.g),
    NutrientId.carbohydrate: ('carbohydrate', NutrientUnit.g),
    NutrientId.fat: ('fat', NutrientUnit.g),
    NutrientId.fiber: ('fiber', NutrientUnit.g),
    NutrientId.saturatedFat: ('saturated_fat', NutrientUnit.g),
    NutrientId.transFat: ('trans_fat', NutrientUnit.g),
    NutrientId.sodium: ('sodium', NutrientUnit.mg),
    NutrientId.vitaminD: ('vitamin_d', NutrientUnit.mcg),
  };

  group('NutrientId registry', () {
    test('uses the complete justified storage-value and unit contract', () {
      expect(NutrientId.values, hasLength(expectedRegistry.length));

      for (final entry in expectedRegistry.entries) {
        expect(entry.key.storageValue, entry.value.$1);
        expect(entry.key.canonicalUnit, entry.value.$2);
      }
    });

    test('round-trips every implemented storage value', () {
      for (final nutrient in NutrientId.values) {
        expect(
          NutrientId.fromStorageValue(nutrient.storageValue),
          nutrient,
        );
      }
    });

    test('keeps energy in the nutrient-fact namespace', () {
      expect(NutrientId.energy.storageValue, 'energy');
      expect(NutrientId.energy.storageValue, isNot('calories'));
    });

    test('keeps the first additional-goal subset in its canonical units', () {
      expect(NutrientId.saturatedFat.canonicalUnit, NutrientUnit.g);
      expect(NutrientId.transFat.canonicalUnit, NutrientUnit.g);
      expect(NutrientId.sodium.canonicalUnit, NutrientUnit.mg);
      expect(NutrientId.vitaminD.canonicalUnit, NutrientUnit.mcg);
    });

    test('leaves unknown future storage values unknown', () {
      expect(NutrientId.fromStorageValue('future_nutrient'), isNull);
      expect(NutrientId.fromStorageValue(null), isNull);
    });

    test('does not define duplicate storage values', () {
      final storageValues =
          NutrientId.values.map((nutrient) => nutrient.storageValue).toSet();

      expect(storageValues, hasLength(NutrientId.values.length));
    });
  });
}
