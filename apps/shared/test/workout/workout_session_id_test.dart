import 'package:test/test.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const uuidV4 = '3f2c8e4a-9b1d-4c7e-8a5f-1d2e3f4a5b6c';
  const uuidV7 = '01920f3e-7c4a-7b2d-9e1f-2a3b4c5d6e7f';
  const uuidV1 = 'c232ab00-9414-11ec-b3c8-9f6bdeced846';

  group('WorkoutSessionId', () {
    test('accepts canonical UUIDs of any version', () {
      for (final value in [uuidV4, uuidV7, uuidV1]) {
        expect(WorkoutSessionId(value).value, value, reason: value);
      }
    });

    test('stores an uppercase UUID in lowercase canonical form', () {
      final id = WorkoutSessionId(uuidV4.toUpperCase());

      expect(id.value, uuidV4);
      expect(id.toString(), uuidV4);
      expect(id, WorkoutSessionId(uuidV4));
    });

    test('rejects blank, whitespace-wrapped and malformed values', () {
      for (final value in [
        '',
        '   ',
        ' $uuidV4',
        '$uuidV4 ',
        '$uuidV4\n',
        '3f2c8e4a9b1d4c7e8a5f1d2e3f4a5b6c',
        '3f2c8e4a-9b1d-4c7e-8a5f-1d2e3f4a5b6',
        'zf2c8e4a-9b1d-4c7e-8a5f-1d2e3f4a5b6c',
        'tp_$uuidV4',
        'ex_barbell_bench_press',
      ]) {
        expect(() => WorkoutSessionId(value), throwsArgumentError,
            reason: value);
      }
    });

    test('equal for the same canonical value with a consistent hash', () {
      final a = WorkoutSessionId(uuidV4);
      final b = WorkoutSessionId(uuidV4.toUpperCase());

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect({a, b}, hasLength(1));
    });

    test('unequal for different values', () {
      expect(WorkoutSessionId(uuidV4), isNot(WorkoutSessionId(uuidV7)));
    });

    test('is not equal to another Workout identity with the same UUID', () {
      final Object id = WorkoutSessionId(uuidV4);

      expect(id, isNot(PlannedWorkoutId(uuidV4)));
      expect(id, isNot(ExerciseRef.userCreated(uuidV4)));
    });
  });
}
