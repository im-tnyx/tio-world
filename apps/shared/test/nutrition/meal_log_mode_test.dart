import 'package:test/test.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const expectedModes = <MealLogMode, String>{
    MealLogMode.manual: 'manual',
    MealLogMode.detailed: 'detailed',
  };

  group('MealLogMode', () {
    test('defines exactly the two canonical meal-log modes', () {
      expect(MealLogMode.values, hasLength(2));
      expect(MealLogMode.values, containsAll(expectedModes.keys));

      for (final entry in expectedModes.entries) {
        expect(entry.key.storageValue, entry.value);
      }
    });

    test('round-trips every canonical storage value', () {
      for (final mode in MealLogMode.values) {
        expect(MealLogMode.fromStorageValue(mode.storageValue), mode);
      }
    });

    test('does not define duplicate storage values', () {
      final storageValues = MealLogMode.values
          .map((mode) => mode.storageValue)
          .toSet();

      expect(storageValues, hasLength(MealLogMode.values.length));
    });

    test('leaves unknown future identities unknown without remapping', () {
      for (final unknown in ['future_mode', 'MANUAL', 'Detailed', '']) {
        expect(
          MealLogMode.fromStorageValue(unknown),
          isNull,
          reason: '$unknown must not be remapped to an existing mode.',
        );
      }

      expect(MealLogMode.fromStorageValue(null), isNull);
    });

    test('never falls back to manual or detailed', () {
      final decoded = MealLogMode.fromStorageValue('something_else');

      expect(decoded, isNull);
      expect(decoded, isNot(MealLogMode.manual));
      expect(decoded, isNot(MealLogMode.detailed));
    });

    test('keeps manual and detailed as distinct first-class identities', () {
      expect(MealLogMode.manual, isNot(MealLogMode.detailed));
      expect(
        MealLogMode.manual.storageValue,
        isNot(MealLogMode.detailed.storageValue),
      );
    });

    test('uses deterministic enum identity and value semantics', () {
      expect(
        MealLogMode.manual,
        same(MealLogMode.fromStorageValue('manual')),
      );
      expect(
        MealLogMode.detailed,
        same(MealLogMode.fromStorageValue('detailed')),
      );
      expect(
        MealLogMode.manual.hashCode,
        MealLogMode.fromStorageValue('manual').hashCode,
      );
    });
  });
}
