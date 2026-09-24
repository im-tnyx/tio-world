import 'package:test/test.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const uuid = '3f2c8e4a-9b1d-4c7e-8a5f-1d2e3f4a5b6c';
  const uppercaseUuid = '3F2C8E4A-9B1D-4C7E-8A5F-1D2E3F4A5B6C';

  const invalidCatalogIds = <String>[
    '',
    '   ',
    ' ex_barbell_bench_press',
    'ex_barbell_bench_press ',
    'ex_barbell_bench_press\n',
    '1643',
    '116',
    'bench-press',
    'cable-one-arm-lateral-raise',
    'Bench Press',
    'ex_',
    'ex__a',
    'ex_a_',
    'EX_A',
    'ex_Bench',
    'ex-a',
    'exercise_bench',
  ];

  const invalidUuids = <String>[
    '',
    '   ',
    ' $uuid',
    '$uuid ',
    '3f2c8e4a9b1d4c7e8a5f1d2e3f4a5b6c',
    '3f2c8e4a-9b1d-4c7e-8a5f-1d2e3f4a5b6',
    '3f2c8e4a-9b1d-4c7e-8a5f-1d2e3f4a5b6cc',
    'zf2c8e4a-9b1d-4c7e-8a5f-1d2e3f4a5b6c',
    '{3f2c8e4a-9b1d-4c7e-8a5f-1d2e3f4a5b6c}',
    'ex_barbell_bench_press',
  ];

  group('CatalogExerciseRef', () {
    test('accepts stable ex_* identities', () {
      for (final id in [
        'ex_barbell_bench_press',
        'ex_dumbbell_one_arm_shoulder_press_v2',
        'ex_a',
        'ex_2',
      ]) {
        expect(ExerciseRef.catalog(id).value, id, reason: id);
      }
    });

    test('accepts a well-formed identity unknown to any catalog', () {
      final ref = ExerciseRef.catalog('ex_future_movement');

      expect(ref, isA<CatalogExerciseRef>());
      expect(ref.value, 'ex_future_movement');
    });

    test('rejects blank, legacy, slug, title and malformed values', () {
      for (final id in invalidCatalogIds) {
        expect(
          () => ExerciseRef.catalog(id),
          throwsArgumentError,
          reason: id,
        );
      }
    });

    test('rejects a UUID as a catalog identity', () {
      expect(() => CatalogExerciseRef(uuid), throwsArgumentError);
    });
  });

  group('UserCreatedExerciseRef', () {
    test('accepts a canonical UUID', () {
      final ref = ExerciseRef.userCreated(uuid);

      expect(ref, isA<UserCreatedExerciseRef>());
      expect(ref.value, uuid);
    });

    test('stores an uppercase UUID in lowercase canonical form', () {
      expect(ExerciseRef.userCreated(uppercaseUuid).value, uuid);
      expect(
        ExerciseRef.userCreated(uppercaseUuid),
        ExerciseRef.userCreated(uuid),
      );
    });

    test('rejects blank, whitespace-wrapped and malformed UUIDs', () {
      for (final value in invalidUuids) {
        expect(
          () => ExerciseRef.userCreated(value),
          throwsArgumentError,
          reason: value,
        );
      }
    });
  });

  group('ExerciseRef.parse', () {
    test('selects the catalog variant for ex_* values', () {
      final ref = ExerciseRef.parse('ex_barbell_bench_press');

      expect(ref, isA<CatalogExerciseRef>());
      expect(ref, ExerciseRef.catalog('ex_barbell_bench_press'));
    });

    test('selects the user-created variant for UUID values', () {
      final ref = ExerciseRef.parse(uppercaseUuid);

      expect(ref, isA<UserCreatedExerciseRef>());
      expect(ref.value, uuid);
    });

    test('round-trips value for both variants', () {
      for (final ref in [
        ExerciseRef.catalog('ex_future_movement'),
        ExerciseRef.userCreated(uuid),
      ]) {
        expect(ExerciseRef.parse(ref.value), ref);
        expect(ref.toString(), ref.value);
      }
    });

    test('throws FormatException for values that are neither format', () {
      for (final value in {...invalidCatalogIds, ...invalidUuids}
          .where((value) => value != 'ex_barbell_bench_press')) {
        expect(
          () => ExerciseRef.parse(value),
          throwsFormatException,
          reason: value,
        );
      }
    });
  });

  group('equality', () {
    test('equal within a variant for the same canonical value', () {
      final a = ExerciseRef.catalog('ex_barbell_bench_press');
      final b = ExerciseRef.parse('ex_barbell_bench_press');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect({a, b}, hasLength(1));
    });

    test('unequal within a variant for different values', () {
      expect(
        ExerciseRef.catalog('ex_barbell_bench_press'),
        isNot(ExerciseRef.catalog('ex_barbell_row')),
      );
      expect(
        ExerciseRef.userCreated(uuid),
        isNot(
          ExerciseRef.userCreated('00000000-0000-0000-0000-000000000000'),
        ),
      );
    });

    test('catalog and user-created references are never equal', () {
      final catalog = ExerciseRef.catalog('ex_barbell_bench_press');
      final userCreated = ExerciseRef.userCreated(uuid);

      expect(catalog, isNot(userCreated));
      expect(userCreated, isNot(catalog));
    });
  });
}
