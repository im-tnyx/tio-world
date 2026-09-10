import 'dart:convert';

import 'package:test/test.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('NutritionSnapshot', () {
    test('creates and reads known canonical nutrient values', () {
      final snapshot = NutritionSnapshot(
        schemaVersion: 1,
        nutrients: const <NutrientId, num>{
          NutrientId.energy: 425,
          NutrientId.protein: 32.5,
        },
      );

      expect(snapshot.schemaVersion, 1);
      expect(snapshot.amountFor(NutrientId.energy), 425);
      expect(snapshot.amountFor(NutrientId.protein), 32.5);
    });

    test('keeps an absent nutrient unknown', () {
      final snapshot = NutritionSnapshot(
        schemaVersion: 1,
        nutrients: const <NutrientId, num>{
          NutrientId.energy: 425,
        },
      );

      expect(snapshot.containsNutrient(NutrientId.fiber), isFalse);
      expect(snapshot.amountFor(NutrientId.fiber), isNull);
    });

    test('keeps explicit zero present', () {
      final snapshot = NutritionSnapshot(
        schemaVersion: 1,
        nutrients: const <NutrientId, num>{
          NutrientId.fiber: 0,
        },
      );

      expect(snapshot.containsNutrient(NutrientId.fiber), isTrue);
      expect(snapshot.amountFor(NutrientId.fiber), 0);
    });

    test('rejects negative values', () {
      expect(
        () => NutritionSnapshot(
          schemaVersion: 1,
          nutrients: const <NutrientId, num>{NutrientId.fat: -0.1},
        ),
        throwsArgumentError,
      );
    });

    test('rejects NaN', () {
      expect(
        () => NutritionSnapshot(
          schemaVersion: 1,
          nutrients: const <NutrientId, num>{NutrientId.fat: double.nan},
        ),
        throwsArgumentError,
      );
    });

    test('rejects positive and negative infinity', () {
      for (final amount in <double>[
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => NutritionSnapshot(
            schemaVersion: 1,
            nutrients: <NutrientId, num>{NutrientId.fat: amount},
          ),
          throwsArgumentError,
        );
      }
    });

    test('round-trips canonical NutrientId keys', () {
      final snapshot = NutritionSnapshot(
        schemaVersion: 3,
        nutrients: const <NutrientId, num>{
          NutrientId.energy: 0,
          NutrientId.protein: 18.25,
          NutrientId.sodium: 410,
        },
      );

      final decoded = NutritionSnapshot.fromJson(
        jsonDecode(jsonEncode(snapshot.toJson())) as Map<String, Object?>,
      );

      expect(decoded, snapshot);
    });

    test('ignores unknown future nutrient identities without remapping', () {
      final snapshot = NutritionSnapshot.fromJson(<String, Object?>{
        'schemaVersion': 2,
        'nutrients': <String, Object?>{
          'protein': 20,
          'future_nutrient': 99,
        },
      });

      expect(snapshot.nutrients, <NutrientId, num>{NutrientId.protein: 20});
      expect(snapshot.nutrients, hasLength(1));
    });

    test('serialization preserves missing versus zero', () {
      final snapshot = NutritionSnapshot(
        schemaVersion: 1,
        nutrients: const <NutrientId, num>{NutrientId.energy: 0},
      );

      final json = snapshot.toJson();
      final nutrients = json['nutrients']! as Map<String, num>;

      expect(nutrients, containsPair('energy', 0));
      expect(nutrients, isNot(contains('fiber')));

      final decoded = NutritionSnapshot.fromJson(json);
      expect(decoded.containsNutrient(NutrientId.energy), isTrue);
      expect(decoded.containsNutrient(NutrientId.fiber), isFalse);
    });

    test('has deterministic map-order-independent value semantics', () {
      final first = NutritionSnapshot(
        schemaVersion: 1,
        nutrients: const <NutrientId, num>{
          NutrientId.energy: 425,
          NutrientId.protein: 32.5,
        },
      );
      final second = NutritionSnapshot(
        schemaVersion: 1,
        nutrients: const <NutrientId, num>{
          NutrientId.protein: 32.5,
          NutrientId.energy: 425,
        },
      );

      expect(second, first);
      expect(second.hashCode, first.hashCode);
      expect(
        NutritionSnapshot(
          schemaVersion: 2,
          nutrients: first.nutrients,
        ),
        isNot(first),
      );
    });

    test('defensively copies and exposes an unmodifiable nutrient map', () {
      final input = <NutrientId, num>{NutrientId.energy: 425};
      final snapshot = NutritionSnapshot(
        schemaVersion: 1,
        nutrients: input,
      );

      input[NutrientId.energy] = 900;

      expect(snapshot.amountFor(NutrientId.energy), 425);
      expect(
        () => snapshot.nutrients[NutrientId.protein] = 1,
        throwsUnsupportedError,
      );
    });

    test('serializes only the frozen value-object fields', () {
      final snapshot = NutritionSnapshot(
        schemaVersion: 1,
        nutrients: const <NutrientId, num>{NutrientId.energy: 425},
      );

      expect(snapshot.toJson().keys, <String>{'schemaVersion', 'nutrients'});
      expect(
        NutrientId.values.every((nutrient) => !nutrient.derivedOnly),
        isTrue,
        reason: 'Every currently justified NutrientId is a source fact.',
      );
    });
  });
}
