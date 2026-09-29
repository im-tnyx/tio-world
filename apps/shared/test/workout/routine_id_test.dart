import 'package:test/test.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const uuidV4 = '3f2c8e4a-9b1d-4c7e-8a5f-1d2e3f4a5b6c';
  const uuidV7 = '018f47a2-7b3c-7def-8abc-1234567890ab';
  const uuidV1 = '550e8400-e29b-11d4-a716-446655440000';

  group('RoutineId', () {
    test('accepts canonical UUID text independent of UUID version', () {
      expect(RoutineId(uuidV4).value, uuidV4);
      expect(RoutineId(uuidV7).value, uuidV7);
      expect(RoutineId(uuidV1).value, uuidV1);
    });

    test('normalizes uppercase UUID text to lowercase', () {
      expect(RoutineId(uuidV4.toUpperCase()).value, uuidV4);
    });

    test('rejects blank, whitespace-wrapped, malformed and prefixed IDs', () {
      for (final value in ['', ' $uuidV4 ', 'not-a-uuid', 'routine_$uuidV4']) {
        expect(() => RoutineId(value), throwsArgumentError, reason: value);
      }
    });

    test('supports value equality and stable hashing', () {
      final a = RoutineId(uuidV4);
      final b = RoutineId(uuidV4.toUpperCase());

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.toString(), uuidV4);
    });

    test('does not equal another Workout identity with the same UUID', () {
      expect(RoutineId(uuidV4), isNot(ProgramId(uuidV4)));
      expect(RoutineId(uuidV4), isNot(TrainingPlanId(uuidV4)));
      expect(RoutineId(uuidV4), isNot(WorkoutSessionId(uuidV4)));
    });
  });
}
