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
    NutrientId.addedSugar: ('added_sugar', NutrientUnit.g),
    NutrientId.sodium: ('sodium', NutrientUnit.mg),
    NutrientId.calcium: ('calcium', NutrientUnit.mg),
    NutrientId.phosphorus: ('phosphorus', NutrientUnit.mg),
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

    test('keeps the Additional Nutrition subset in its canonical units', () {
      expect(NutrientId.saturatedFat.canonicalUnit, NutrientUnit.g);
      expect(NutrientId.transFat.canonicalUnit, NutrientUnit.g);
      expect(NutrientId.addedSugar.canonicalUnit, NutrientUnit.g);
      expect(NutrientId.sodium.canonicalUnit, NutrientUnit.mg);
      expect(NutrientId.calcium.canonicalUnit, NutrientUnit.mg);
      expect(NutrientId.phosphorus.canonicalUnit, NutrientUnit.mg);
      expect(NutrientId.vitaminD.canonicalUnit, NutrientUnit.mcg);
    });

    test('identity stays separate from unit', () {
      // Three of the seven share the milligram unit; none of them share an
      // identity, and a unit change must never imply a new nutrient.
      final milligramIds = NutrientId.values
          .where((nutrient) => nutrient.canonicalUnit == NutrientUnit.mg)
          .map((nutrient) => nutrient.storageValue)
          .toSet();

      expect(milligramIds, containsAll(['sodium', 'calcium', 'phosphorus']));
      expect(milligramIds, hasLength(3));
    });

    test('the registry stays bounded to currently justified consumers', () {
      // Deliberately not exhaustive. Potassium, iron, magnesium, zinc, the
      // remaining vitamins, cholesterol and the fat sub-types need their own
      // bounded audit before they earn an identity here.
      for (final speculative in [
        'potassium',
        'iron',
        'magnesium',
        'zinc',
        'vitamin_a',
        'vitamin_c',
        'cholesterol',
        'total_sugar',
        'monounsaturated_fat',
        'polyunsaturated_fat',
      ]) {
        expect(
          NutrientId.fromStorageValue(speculative),
          isNull,
          reason: '$speculative is not approved as an identity yet.',
        );
      }
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
