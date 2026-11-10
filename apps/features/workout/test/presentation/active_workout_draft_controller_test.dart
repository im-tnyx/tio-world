import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

final class _Store implements ActiveWorkoutDraftStore {
  ActiveWorkoutDraft? saved;
  bool failSave = false;
  bool failAfterWrite = false;
  bool failLoad = false;
  int writes = 0;
  Completer<void>? writeGate;

  @override
  Future<ActiveWorkoutDraft?> load() async {
    if (failLoad) throw StateError('secure draft unavailable');
    return saved;
  }

  @override
  Future<void> save(ActiveWorkoutDraft draft) async {
    if (failSave) throw StateError('secure write failed');
    await writeGate?.future;
    saved = draft;
    writes++;
    if (failAfterWrite) {
      failAfterWrite = false;
      throw StateError('commit pointer write failed');
    }
  }

  @override
  Future<void> delete() async => saved = null;
}

final class _SaveRepository implements WorkoutDraftSaveRepository {
  final submissions = <ActiveWorkoutDraft>[];
  bool fail = true;

  @override
  Future<SavedWorkoutDraftRecord> saveDraft(ActiveWorkoutDraft draft) async {
    submissions.add(draft);
    if (fail) throw StateError('unknown transport outcome');
    return SavedWorkoutDraftRecord(
      sessionId: WorkoutSessionId(_id(900)),
      ownerId: draft.ownerId,
      saveRequestId: draft.saveRequestId,
      revision: 2,
      title: draft.submittedTitle!,
      workoutAtUtc: draft.workoutAtUtc!,
      utcOffsetMinutes: draft.workoutUtcOffsetMinutes!,
      localDate: '2026-11-09',
      description: draft.description,
      activityType: draft.activityType,
      gymName: draft.gymName,
      overallRpe: draft.overallRpe,
      durationSeconds: draft.selectedDurationSeconds!,
      snapshot: const {},
      performedSets: const [],
    );
  }

  @override
  Future<SavedWorkoutDraftRecord?> getSavedDraft(WorkoutSessionId id) async =>
      null;
}

String _id(int n) =>
    '00000000-0000-4000-8000-${n.toRadixString(16).padLeft(12, '0')}';

Exercise _exercise(String ref, String name) => Exercise(
      ref: ExerciseRef.catalog(ref),
      displayName: name,
      exerciseType: ExerciseType.weightReps,
      status: ExerciseStatus.active,
    );

void main() {
  const owner = '00000000-0000-4000-8000-000000000001';

  test('local actions retain stable identities, actual values and paused time',
      () async {
    final store = _Store();
    var now = DateTime.utc(2026, 11, 9, 10);
    var nextId = 10;
    final controller = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
      clock: () => now,
      newUuid: () => _id(nextId++),
    );
    expect(await controller.restoreOrStart(), isTrue);
    final draftId = controller.draft!.id;
    final saveRequestId = controller.draft!.saveRequestId;
    expect(draftId, isNot(saveRequestId));
    expect(
        await controller.addExercises([
          _exercise('ex_first', 'First'),
          _exercise('ex_second', 'Second'),
        ]),
        isTrue);
    final first = controller.draft!.exercises.first;
    final second = controller.draft!.exercises.last;
    final secondSetId = second.sets.single.id;
    expect(await controller.setRpe(second.id, secondSetId, 8.5), isTrue);
    expect(
        await controller.setRestPreset(
          second.id,
          const RoutineRestTimerPreset(normalRestSeconds: 40),
        ),
        isTrue);
    now = now.add(const Duration(minutes: 1));
    expect(
        await controller.toggleLogged(
          second.id,
          secondSetId,
          reps: 12,
          loadKg: 40,
        ),
        isTrue);
    expect(await controller.removeExercise(first.id), isTrue);
    expect(await controller.addSet(second.id), isTrue);
    expect(controller.draft!.exercises.single.sets.first.id, secondSetId);
    expect(controller.draft!.exercises.single.sets.last.id, isNot(secondSetId));

    now = now.add(const Duration(minutes: 1));
    expect(await controller.pause(), isTrue);
    now = now.add(const Duration(minutes: 5));
    expect(await controller.resume(), isTrue);
    now = now.add(const Duration(minutes: 1));
    expect(controller.draft!.time.elapsedActiveDuration(now),
        const Duration(minutes: 3));
    expect(
        await controller.updateSaveMetadata(
          title: '  Custom  Title  ',
          description: 'Description',
          workoutAtUtc: DateTime.utc(2026, 11, 8, 23, 30),
          workoutUtcOffsetMinutes: 330,
          selectedDurationSeconds: 180,
          gymName: 'Gym',
          activityType: 'Weight Training',
          overallRpe: 7.5,
        ),
        isTrue);
    controller.dispose();

    final reopened = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
      clock: () => now,
    );
    expect(await reopened.restoreOrStart(), isTrue);
    expect(reopened.draft!.id, draftId);
    expect(reopened.draft!.saveRequestId, saveRequestId);
    expect(reopened.draft!.exercises.single.id, second.id);
    expect(reopened.draft!.exercises.single.sets.first.reps, 12);
    expect(reopened.draft!.exercises.single.sets.first.loadKg, 40);
    expect(reopened.draft!.exercises.single.sets.first.rpe, 8.5);
    expect(reopened.draft!.exercises.single.restPreset.normalRestSeconds, 40);
    expect(reopened.draft!.time.elapsedActiveDuration(now),
        const Duration(minutes: 3));
    expect(reopened.draft!.workoutTitle, '  Custom  Title  ');
    expect(reopened.draft!.workoutAtUtc, DateTime.utc(2026, 11, 8, 23, 30));
    expect(reopened.draft!.workoutUtcOffsetMinutes, 330);
    expect(await reopened.discard(), isTrue);
    expect(store.saved, isNull);
    reopened.dispose();
  });

  test('failed mutation retains last durable draft and stable retry identity',
      () async {
    final store = _Store();
    var nextId = 10;
    final controller = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
      clock: () => DateTime.utc(2026, 11, 9),
      newUuid: () => _id(nextId++),
    );
    expect(await controller.restoreOrStart(), isTrue);
    final requestId = controller.draft!.saveRequestId;
    store.failSave = true;
    expect(await controller.addExercises([_exercise('ex_first', 'First')]),
        isFalse);
    expect(controller.error, isA<StateError>());
    expect(controller.draft!.exercises, isEmpty);
    expect(store.saved!.exercises, isEmpty);
    store.failSave = false;
    expect(await controller.addExercises([_exercise('ex_first', 'First')]),
        isTrue);
    expect(controller.draft!.saveRequestId, requestId);
    controller.dispose();
  });

  test('secure read failure never starts a replacement workout', () async {
    final store = _Store()..failLoad = true;
    final controller = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
      clock: () => DateTime.utc(2026, 11, 9),
    );
    expect(await controller.restoreOrStart(), isFalse);
    expect(controller.draft, isNull);
    expect(store.writes, 0);
    controller.dispose();
  });

  test('restoreExisting recovers a draft without creating an empty one',
      () async {
    final store = _Store();
    final controller = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
      clock: () => DateTime.utc(2026, 11, 9),
    );
    expect(await controller.restoreExisting(), isTrue);
    expect(controller.draft, isNull);
    expect(store.writes, 0);
    expect(await controller.restoreOrStart(), isTrue);
    final draftId = controller.draft!.id;
    controller.dispose();

    final reopened = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
      clock: () => DateTime.utc(2026, 11, 9),
    );
    expect(await reopened.restoreExisting(), isTrue);
    expect(reopened.draft!.id, draftId);
    expect(store.writes, 1);
    reopened.dispose();
  });

  test('rapid enabled mutations are serialized onto the latest draft',
      () async {
    final store = _Store();
    var nextId = 10;
    final controller = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
      clock: () => DateTime.utc(2026, 11, 9),
      newUuid: () => _id(nextId++),
    );
    expect(await controller.restoreOrStart(), isTrue);
    expect(await controller.addExercises([_exercise('ex_first', 'First')]),
        isTrue);
    final exerciseId = controller.draft!.exercises.single.id;
    store.writeGate = Completer<void>();
    final first = controller.addSet(exerciseId);
    final second = controller.addSet(exerciseId);
    expect(controller.isBusy, isTrue);
    store.writeGate!.complete();
    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(controller.draft!.exercises.single.sets.length, 3);
    expect(store.saved!.exercises.single.sets.length, 3);
    expect(controller.draft!.exercises.single.sets.map((set) => set.id).toSet(),
        hasLength(3));
    controller.dispose();
  });

  test('interrupted first write recovers the durable candidate on restore',
      () async {
    final store = _Store()..failAfterWrite = true;
    final controller = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
      clock: () => DateTime.utc(2026, 11, 9, 10),
      newUuid: () => _id(10),
    );
    expect(await controller.restoreOrStart(), isTrue);
    expect(controller.draft?.id, _id(10));
    expect(store.saved?.id, _id(10));
    expect(store.writes, 1);
    controller.dispose();
  });

  test('failed Save freezes title and retry identity until confirmed readback',
      () async {
    final store = _Store();
    final backend = _SaveRepository();
    var now = DateTime.utc(2026, 11, 9, 10);
    var nextId = 10;
    final controller = ActiveWorkoutDraftController(
      store: store,
      saveRepository: backend,
      ownerId: owner,
      clock: () => now,
      newUuid: () => _id(nextId++),
    );
    expect(await controller.restoreOrStart(), isTrue);
    expect(await controller.addExercises([_exercise('ex_first', 'First')]),
        isTrue);
    final exercise = controller.draft!.exercises.single;
    now = now.add(const Duration(minutes: 1));
    expect(
        await controller.toggleLogged(exercise.id, exercise.sets.single.id,
            reps: 10),
        isTrue);
    now = now.add(const Duration(minutes: 1));
    expect(await controller.pause(), isTrue);
    expect(
        await controller.updateSaveMetadata(
          title: '',
          description: null,
          workoutAtUtc: DateTime.utc(2026, 11, 9, 10),
          workoutUtcOffsetMinutes: 0,
          selectedDurationSeconds: 120,
          gymName: null,
          activityType: 'Weight Training',
          overallRpe: null,
        ),
        isTrue);
    now = now.add(const Duration(minutes: 1));
    expect(await controller.save(resolvedTitle: 'Morning Workout'), isFalse);
    final frozen = store.saved!;
    expect(frozen.submittedTitle, 'Morning Workout');
    expect(frozen.workoutTitle, isEmpty);
    expect(await controller.resume(), isFalse);
    expect(await controller.discard(), isFalse);
    expect(
        await controller.updateSaveMetadata(
          title: 'Changed',
          description: null,
          workoutAtUtc: DateTime.utc(2026, 11, 9, 10),
          workoutUtcOffsetMinutes: 0,
          selectedDurationSeconds: 120,
          gymName: null,
          activityType: 'Weight Training',
          overallRpe: null,
        ),
        isFalse);
    controller.dispose();

    final reopened = ActiveWorkoutDraftController(
      store: store,
      saveRepository: backend,
      ownerId: owner,
      clock: () => now.add(const Duration(hours: 1)),
    );
    expect(await reopened.restoreExisting(), isTrue);
    backend.fail = false;
    expect(await reopened.save(resolvedTitle: 'Morning Workout'), isTrue);
    expect(backend.submissions.last.saveRequestId, frozen.saveRequestId);
    expect(backend.submissions.last.submittedAtUtc, frozen.submittedAtUtc);
    expect(store.saved, isNull);
    expect(reopened.draft, isNull);
    reopened.dispose();
  });

  test('rest starts only when configured and survives restart by UTC deadline',
      () async {
    var now = DateTime.utc(2026, 11, 9, 10);
    final store = _Store()
      ..saved = ActiveWorkoutDraft(
        id: _id(4),
        ownerId: owner,
        saveRequestId: _id(5),
        time: WorkoutTime.start(startedAtUtc: now),
        exercises: [
          ActiveWorkoutDraftExercise(
            id: _id(6),
            exerciseRef: ExerciseRef.catalog('ex_first'),
            displayName: 'First',
            sets: [
              ActiveWorkoutDraftSet(
                id: _id(7),
                prescription: SetPrescription(restSeconds: 60),
              ),
            ],
          ),
        ],
      );
    final controller = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
      clock: () => now,
    );
    expect(await controller.restoreOrStart(), isTrue);
    expect(await controller.toggleLogged(_id(6), _id(7), reps: 10), isTrue);
    expect(controller.draft!.activeRest!.remaining(now),
        const Duration(seconds: 60));
    expect(await controller.adjustRest(15), isTrue);
    now = now.add(const Duration(seconds: 30));
    controller.dispose();
    final reopened = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
      clock: () => now,
    );
    expect(await reopened.restoreOrStart(), isTrue);
    expect(reopened.draft!.activeRest!.remaining(now),
        const Duration(seconds: 45));
    expect(await reopened.skipRest(), isTrue);
    expect(reopened.draft!.activeRest, isNull);
    expect(
        await reopened.setRestPreset(
          _id(6),
          const RoutineRestTimerPreset(),
        ),
        isTrue);
    expect(await reopened.toggleLogged(_id(6), _id(7)), isTrue);
    expect(await reopened.toggleLogged(_id(6), _id(7), reps: 9), isTrue);
    expect(reopened.draft!.activeRest, isNull);
    reopened.dispose();
  });
}
