import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/src/data/dto/workout_draft_save_dto.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

String _id(int value) =>
    '00000000-0000-4000-8000-${value.toRadixString(16).padLeft(12, '0')}';

void main() {
  test('Save-only v2 snapshot keeps Superset config and performed indexes', () {
    final started = DateTime.utc(2026, 11, 13, 8);
    final pausedAt = started.add(const Duration(minutes: 10));
    final groupId = _id(10);
    final firstExerciseId = _id(11);
    final firstSetId = _id(12);
    final draft = ActiveWorkoutDraft(
      id: _id(1),
      ownerId: _id(2),
      saveRequestId: _id(3),
      time: WorkoutTime.start(startedAtUtc: started).pause(pausedAt),
      submittedAtUtc: pausedAt,
      submittedTitle: 'Superset Day',
      workoutAtUtc: started,
      workoutUtcOffsetMinutes: 0,
      exercises: [
        ActiveWorkoutDraftExercise(
          id: firstExerciseId,
          supersetId: groupId,
          exerciseRef: ExerciseRef.catalog('ex_bench_press'),
          displayName: 'Bench Press',
          sets: [
            ActiveWorkoutDraftSet(
              id: firstSetId,
              prescription: SetPrescription(
                setType: RoutineSetType.warmUp,
                reps: 10,
                restSeconds: 30,
              ),
              reps: 10,
              loadKg: 40,
              loggedAtUtc: started.add(const Duration(minutes: 2)),
            ),
          ],
        ),
        ActiveWorkoutDraftExercise(
          id: _id(13),
          supersetId: groupId,
          exerciseRef: ExerciseRef.catalog('ex_squat'),
          displayName: 'Squat',
          sets: [
            ActiveWorkoutDraftSet(
              id: _id(14),
              prescription: SetPrescription(reps: 8, restSeconds: 45),
            ),
          ],
        ),
      ],
      supersets: [
        ActiveWorkoutDraftSuperset(
          id: groupId,
          restPreset: const RoutineRestTimerPreset(
            normalRestSeconds: 60,
            warmUpRestSeconds: 15,
          ),
        ),
      ],
    );

    final payload = WorkoutDraftSaveDto.payload(draft);
    final snapshot = payload['routine_snapshot'] as Map;
    final exercises = snapshot['exercises'] as List;
    final performed = payload['performed_sets'] as List;

    expect(snapshot['schema_version'], 2);
    expect(snapshot['superset_groups'], [
      {
        'id': groupId,
        'normal_rest_seconds': 60,
        'warm_up_rest_seconds': 15,
      },
    ]);
    expect(exercises.map((exercise) => exercise['superset_id']),
        [groupId, groupId]);
    expect(performed, hasLength(1));
    expect(performed.single['exercise_index'], 0);
    expect(performed.single['set_index'], 0);
    expect(performed.single['exercise_ref'], 'ex_bench_press');
  });
}
