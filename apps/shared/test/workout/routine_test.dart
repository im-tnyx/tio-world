import 'package:test/test.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const routineUuid = '3f2c8e4a-9b1d-4c7e-8a5f-1d2e3f4a5b6c';
  const programUuid = '550e8400-e29b-41d4-a716-446655440000';
  const otherProgramUuid = '018f47a2-7b3c-7def-8abc-1234567890ab';

  group('Routine', () {
    test('stores stable identity, owning Program and supplied name', () {
      final routine = Routine(
        id: RoutineId(routineUuid),
        programId: ProgramId(programUuid),
        name: 'Routine 1',
      );

      expect(routine.id, RoutineId(routineUuid));
      expect(routine.programId, ProgramId(programUuid));
      expect(routine.name, 'Routine 1');
    });

    test('preserves meaningful surrounding whitespace', () {
      final routine = Routine(
        id: RoutineId(routineUuid),
        programId: ProgramId(programUuid),
        name: ' Routine 1 ',
      );

      expect(routine.name, ' Routine 1 ');
    });

    test('rejects blank and whitespace-only names', () {
      for (final name in ['', '   ', '\n\t']) {
        expect(
          () => Routine(
            id: RoutineId(routineUuid),
            programId: ProgramId(programUuid),
            name: name,
          ),
          throwsArgumentError,
          reason: name,
        );
      }
    });

    test('equality includes identity, owning Program and name', () {
      final a = Routine(
        id: RoutineId(routineUuid),
        programId: ProgramId(programUuid),
        name: 'Routine 1',
      );
      final b = Routine(
        id: RoutineId(routineUuid),
        programId: ProgramId(programUuid),
        name: 'Routine 1',
      );
      final moved = Routine(
        id: RoutineId(routineUuid),
        programId: ProgramId(otherProgramUuid),
        name: 'Routine 1',
      );
      final renamed = Routine(
        id: RoutineId(routineUuid),
        programId: ProgramId(programUuid),
        name: 'Strength',
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(moved));
      expect(a, isNot(renamed));
    });
  });
}
