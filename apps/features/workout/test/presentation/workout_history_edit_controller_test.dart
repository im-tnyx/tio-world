import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_feature_workout/src/presentation/controllers/workout_history_edit_controller.dart';
import 'package:tio_shared/shared.dart';

final _completed = DateTime.utc(2026, 11, 11, 21);
final _workoutAt = DateTime.utc(2026, 11, 11, 20, 30);
final _id = WorkoutSessionId('22222222-2222-4222-a222-222222222222');

WorkoutHistoryDetail _detail({bool skippedWithoutTime = false}) {
  final raw = <String, dynamic>{
    'schema_version': 2,
    'origin': 'ad_hoc',
    'captured_at_utc': '2026-11-11T20:00:00Z',
    'exercises': [
      {
        'exercise_ref': 'ex_bench_press',
        'display_name': 'Bench Press',
        'exercise_type': 'weight_reps',
        'occurrence_index': 0,
        'prescribed_sets': [
          {'set_type': 'normal', 'performed_rpe': 7.0},
          if (skippedWithoutTime) {'set_type': 'normal'},
        ],
      },
    ],
  };
  final sets = [
    PerformedSet(
      id: '33333333-3333-4333-a333-333333333333',
      exerciseRef: CatalogExerciseRef('ex_bench_press'),
      sessionExerciseIndex: 0,
      setIndex: 0,
      reps: 8,
      loadKg: 50,
      completedAtUtc: DateTime.utc(2026, 11, 11, 20, 40),
    ),
    if (skippedWithoutTime)
      PerformedSet(
        id: '44444444-4444-4444-a444-444444444444',
        exerciseRef: CatalogExerciseRef('ex_bench_press'),
        sessionExerciseIndex: 0,
        setIndex: 1,
        isSkipped: true,
      ),
  ];
  return WorkoutHistoryDetail(
    summary: WorkoutHistoryEntry(
      sessionId: _id,
      completedAtUtc: _completed,
      displayAt: DateTime(2026, 11, 12, 2, 30),
      title: 'Original',
      duration: const Duration(minutes: 44),
      exercises: const [],
      volumeKg: 400,
    ),
    exercises: const [],
    revision: 2,
    rawSnapshot: raw,
    snapshot: WorkoutSessionSnapshotDto.fromJson(raw),
    allPerformedSets: sets,
    workoutAtUtc: _workoutAt,
    utcOffsetMinutes: 330,
    activityType: 'Weight Training',
    overallRpe: 7,
  );
}

WorkoutHistoryEditRequest _request(
        WorkoutHistoryDetail source, WorkoutHistoryEditController controller) =>
    WorkoutHistoryEditRequest(
      source: source,
      title: 'Updated',
      description: '  Good session  ',
      workoutAtUtc: _workoutAt,
      utcOffsetMinutes: 330,
      durationSeconds: 2700,
      gymName: ' Test Gym ',
      activityType: 'Weight Training',
      overallRpe: 8,
      exercises: controller.exercises,
    );

void main() {
  test('actual logged values drive volume and Update payload', () {
    final source = _detail();
    final editor = WorkoutHistoryEditController(source);
    addTearDown(editor.dispose);
    expect(editor.completedSetCount, 1);
    expect(editor.volumeKg, 400);
    expect(editor.canUpdate, isTrue);
    expect(editor.exercises.first.sets.first.rpe, 7);

    editor.toggleLogged(0, 0);
    expect(editor.canUpdate, isFalse);
    editor.toggleLogged(0, 0, reps: 12, loadKg: 40);
    expect(editor.volumeKg, 480);
    final payload = WorkoutHistoryEditDto.payload(_request(source, editor));
    expect(payload['workout_title'], 'Updated');
    expect(payload['description'], 'Good session');
    expect(payload['gym_name'], 'Test Gym');
    expect(payload['selected_duration_seconds'], 2700);
    expect((payload['performed_sets'] as List).single['id'],
        '33333333-3333-4333-a333-333333333333');
    expect((payload['performed_sets'] as List).single['reps'], 12);
    expect(
        (payload['routine_snapshot'] as Map)['exercises'][0]['prescribed_sets']
            [0]['performed_rpe'],
        7.0);
  });

  test('add, replace and remove exercises keep performed order and slot count',
      () {
    final source = _detail();
    final editor = WorkoutHistoryEditController(source);
    addTearDown(editor.dispose);
    editor.addExercises([
      Exercise(
        ref: CatalogExerciseRef('ex_spinning'),
        displayName: 'Spinning',
        exerciseType: ExerciseType.duration,
        status: ExerciseStatus.active,
      ),
    ]);
    expect(editor.canUpdate, isFalse);
    editor.toggleLogged(1, 0, durationSeconds: 120);
    expect(editor.canUpdate, isTrue);
    editor.addSet(0);
    editor.toggleLogged(0, 1, reps: 5, loadKg: 40);
    expect(editor.completedSetCount, 3);
    var payload = WorkoutHistoryEditDto.payload(_request(source, editor));
    expect((payload['performed_sets'] as List).map((s) => s['exercise_index']),
        [0, 0, 1]);
    expect((payload['performed_sets'] as List)[1].containsKey('id'), isFalse);

    editor.replaceExercise(
        1,
        Exercise(
          ref: CatalogExerciseRef('ex_squat'),
          displayName: 'Squat',
          exerciseType: ExerciseType.weightReps,
          status: ExerciseStatus.active,
        ));
    expect(editor.canUpdate, isFalse);
    editor.toggleLogged(1, 0, reps: 8, loadKg: 20);
    editor.removeExercise(0);
    payload = WorkoutHistoryEditDto.payload(_request(source, editor));
    expect((payload['performed_sets'] as List).single['exercise_index'], 0);
    expect(
        (payload['performed_sets'] as List).single['exercise_ref'], 'ex_squat');
    expect((payload['routine_snapshot'] as Map)['exercises'].length, 1);
    editor.removeSet(0, 0);
    expect(editor.canUpdate, isFalse);
  });

  test('pre-existing skipped set without timestamp survives metadata edit', () {
    final source = _detail(skippedWithoutTime: true);
    final editor = WorkoutHistoryEditController(source);
    addTearDown(editor.dispose);
    final payload = WorkoutHistoryEditDto.payload(_request(source, editor));
    final rows = payload['performed_sets'] as List;
    expect(rows.length, 2);
    expect(rows.last['id'], '44444444-4444-4444-a444-444444444444');
    expect(rows.last['is_skipped'], isTrue);
    expect(rows.last['completed_at_utc'], isNull);
  });
}
