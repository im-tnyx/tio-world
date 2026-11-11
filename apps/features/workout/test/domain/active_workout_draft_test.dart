import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

String _id(int n) =>
    '00000000-0000-4000-8000-${n.toRadixString(16).padLeft(12, '0')}';

void main() {
  final started = DateTime.utc(2026, 11, 9, 21);

  test('versioned draft round trips timing, metadata and actual set values',
      () {
    final time = WorkoutTime.start(startedAtUtc: started)
        .pause(started.add(const Duration(minutes: 2)))
        .resume(started.add(const Duration(minutes: 3)));
    final draft = ActiveWorkoutDraft(
      id: _id(1),
      ownerId: _id(2),
      saveRequestId: _id(3),
      revision: 4,
      time: time,
      backgroundedAtUtc: started.add(const Duration(minutes: 4)),
      lastActivityAtUtc: started.add(const Duration(minutes: 4)),
      workoutTitle: '  Custom  Title  ',
      description: 'Save screen description',
      workoutAtUtc: DateTime.utc(2026, 11, 8, 23, 30),
      workoutUtcOffsetMinutes: 330,
      selectedDurationSeconds: 3671,
      gymName: 'Gym',
      activityType: 'strength',
      overallRpe: 7.5,
      activeRest: ActiveWorkoutDraftRest(
        targetAtUtc: started.add(const Duration(minutes: 4)),
        totalDurationSeconds: 40,
        exerciseId: _id(4),
        setId: _id(5),
      ),
      exercises: [
        ActiveWorkoutDraftExercise(
          id: _id(4),
          exerciseRef: ExerciseRef.catalog('ex_test'),
          displayName: 'Test Exercise',
          exerciseType: ExerciseType.weightReps,
          thumbnailUrl: Uri.parse('https://example.com/bench.png'),
          restPreset: const RoutineRestTimerPreset(normalRestSeconds: 40),
          sets: [
            ActiveWorkoutDraftSet(
              id: _id(5),
              prescription: SetPrescription(
                reps: 8,
                repsMax: 12,
                restSeconds: 40,
                setType: RoutineSetType.warmUp,
              ),
              reps: 10,
              loadKg: 42.5,
              rpe: 8.5,
              loggedAtUtc: started.add(const Duration(minutes: 1)),
            ),
          ],
        ),
      ],
    );

    final restored = ActiveWorkoutDraft.fromJson(draft.toJson());
    expect(restored.id, draft.id);
    expect(restored.saveRequestId, draft.saveRequestId);
    expect(restored.revision, 4);
    expect(restored.time, time);
    expect(restored.workoutTitle, '  Custom  Title  ');
    expect(restored.workoutAtUtc, DateTime.utc(2026, 11, 8, 23, 30));
    expect(restored.workoutUtcOffsetMinutes, 330);
    expect(restored.exercises.single.sets.single.reps, 10);
    expect(restored.exercises.single.sets.single.prescription.repsMax, 12);
    expect(restored.exercises.single.sets.single.rpe, 8.5);
    expect(restored.exercises.single.restPreset.normalRestSeconds, 40);
    expect(restored.exercises.single.thumbnailUrl,
        Uri.parse('https://example.com/bench.png'));
    expect(restored.activeRest!.setId, _id(5));
    expect(restored.backgroundedAtUtc, started.add(const Duration(minutes: 4)));
    expect(restored.lastActivityAtUtc, started.add(const Duration(minutes: 4)));
    expect(draft.toJson().toString(), isNot(contains('notes')));
  });

  test('500 sets survive serialization without losing order or identity', () {
    final draft = ActiveWorkoutDraft(
      id: _id(1),
      ownerId: _id(2),
      saveRequestId: _id(3),
      time: WorkoutTime.start(startedAtUtc: started),
      exercises: [
        for (var i = 0; i < 100; i++)
          ActiveWorkoutDraftExercise(
            id: _id(1000 + i),
            exerciseRef: ExerciseRef.catalog('ex_test'),
            displayName: 'Exercise $i',
            sets: [
              for (var j = 0; j < 5; j++)
                ActiveWorkoutDraftSet(
                  id: _id(2000 + i * 5 + j),
                  prescription: SetPrescription(),
                  reps: j,
                  loggedAtUtc: started,
                ),
            ],
          ),
      ],
    );
    final restored = ActiveWorkoutDraft.fromJson(draft.toJson());
    expect(restored.exercises.length, 100);
    expect(restored.exercises.expand((e) => e.sets).length, 500);
    expect(restored.exercises.last.sets.last.id, _id(2499));
  });

  test('unknown version and duplicate set IDs fail closed', () {
    final empty = ActiveWorkoutDraft(
      id: _id(1),
      ownerId: _id(2),
      saveRequestId: _id(3),
      time: WorkoutTime.start(startedAtUtc: started),
    );
    expect(() => ActiveWorkoutDraft.fromJson({...empty.toJson(), 'version': 2}),
        throwsFormatException);
    expect(
      () => ActiveWorkoutDraft(
        id: _id(1),
        ownerId: _id(2),
        saveRequestId: _id(3),
        time: WorkoutTime.start(startedAtUtc: started),
        exercises: [
          for (var n = 0; n < 2; n++)
            ActiveWorkoutDraftExercise(
              id: _id(4 + n),
              exerciseRef: ExerciseRef.catalog('ex_test'),
              displayName: 'Exercise',
              sets: [
                ActiveWorkoutDraftSet(
                    id: _id(10), prescription: SetPrescription())
              ],
            ),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('skipped completion survives restoration without fabricated metrics',
      () {
    final skipped = ActiveWorkoutDraftSet(
      id: _id(9),
      prescription: SetPrescription(),
      loggedAtUtc: started,
      isSkipped: true,
    );
    final restored = ActiveWorkoutDraftSet.fromJson(skipped.toJson());
    expect(restored.isSkipped, isTrue);
    expect(restored.reps, isNull);
    expect(restored.loggedAtUtc, started);
  });
}
