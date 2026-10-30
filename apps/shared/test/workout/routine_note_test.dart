import 'package:test/test.dart';
import 'package:tio_shared/shared.dart';

const _user = '11111111-1111-4111-8111-111111111111';
const _routine = '22222222-2222-4222-8222-222222222222';
const _note = '33333333-3333-4333-8333-333333333333';

void main() {
  test('RoutineNote preserves canonical Routine and Exercise scopes', () {
    final routine = RoutineNote.fromJson({
      'id': _note,
      'user_id': _user,
      'routine_id': _routine,
      'exercise_ref': null,
      'note_type': 'pinned_routine',
      'body': '  keep this text  ',
      'created_at': '2026-10-29T10:00:00Z',
      'updated_at': '2026-10-29T10:00:00Z',
      'revision': 0,
      'last_mutation_id': null,
    });
    final exercise = RoutineNote.fromJson({
      ...routineJson(routine),
      'routine_id': null,
      'exercise_ref': '3f2c8e4a-9b1d-4c7e-8a5f-1d2e3f4a5b6c',
      'note_type': 'pinned_exercise',
    });

    expect(routine.scope, RoutineNoteScope.routine(RoutineId(_routine)));
    expect(routine.body, 'keep this text');
    expect(routine.type, RoutineNoteType.pinnedRoutine);
    expect(exercise.scope.type, RoutineNoteType.pinnedExercise);
    expect(
        exercise.exerciseRef,
        ExerciseRef.userCreated(
          '3f2c8e4a-9b1d-4c7e-8a5f-1d2e3f4a5b6c',
        ));
  });

  test('ExerciseRef catalog and Custom values round-trip without overlap', () {
    expect(
      ExerciseRef.parse('ex_barbell_bench_press'),
      ExerciseRef.catalog('ex_barbell_bench_press'),
    );
    expect(
      ExerciseRef.parse('3F2C8E4A-9B1D-4C7E-8A5F-1D2E3F4A5B6C'),
      ExerciseRef.userCreated('3f2c8e4a-9b1d-4c7e-8a5f-1d2e3f4a5b6c'),
    );
  });

  test('body validation rejects blank and over-limit values', () {
    expect(() => RoutineNote.normalizeBody('   '), throwsArgumentError);
    expect(() => RoutineNote.normalizeBody('x' * 501), throwsArgumentError);
    expect(RoutineNote.normalizeBody('  valid  '), 'valid');
  });

  test('body normalization matches Unicode whitespace and scalar-value limits', () {
    expect(
      RoutineNote.normalizeBody('\u00a0\tvalid\u2028'),
      'valid',
    );

    final fiveHundredScalars = '\u{1f600}' * 500;
    expect(
      RoutineNote.normalizeBody(fiveHundredScalars).runes.length,
      500,
    );
    expect(
      () => RoutineNote.normalizeBody('\u{1f600}' * 501),
      throwsArgumentError,
    );
  });
}

Map<String, dynamic> routineJson(RoutineNote note) => {
      'id': note.id,
      'user_id': note.userId,
      'routine_id': note.routineId?.value,
      'exercise_ref': note.exerciseRef?.value,
      'note_type': note.type.value,
      'body': note.body,
      'created_at': note.createdAt.toIso8601String(),
      'updated_at': note.updatedAt.toIso8601String(),
      'revision': note.revision,
      'last_mutation_id': note.lastMutationId,
    };
