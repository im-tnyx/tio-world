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
  Completer<void>? loadGate;

  @override
  Future<ActiveWorkoutDraft?> load() async {
    if (failLoad) throw StateError('secure draft unavailable');
    await loadGate?.future;
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

  test('Routine seed survives a failed first write and empty page restore',
      () async {
    final store = _Store()..failSave = true;
    var nextId = 1000;
    final controller = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
      clock: () => DateTime.utc(2026, 11, 11, 8),
      newUuid: () => _id(nextId++),
    );
    addTearDown(controller.dispose);
    final exercise = _exercise('ex_routine_bench', 'Bench Press');
    const routineId = '20000000-0000-4000-8000-000000000001';
    final request = WorkoutRoutineStartRequest(
      routine: Routine(
        id: RoutineId(routineId),
        programId: ProgramId('10000000-0000-4000-8000-000000000001'),
        name: 'Day One',
      ),
      composition: RoutineCompositionSnapshot(
        routineId: RoutineId(routineId),
        revision: 1,
        entries: [
          RoutineCompositionEntry(
            id: '30000000-0000-4000-8000-000000000001',
            exercise: exercise.ref,
            sets: [
              RoutineCompositionSet(
                id: '40000000-0000-4000-8000-000000000001',
                prescription: SetPrescription(reps: 8, repsMax: 12),
              ),
            ],
          ),
        ],
      ),
      exercises: {exercise.ref: exercise},
    );

    expect(await controller.startFromRoutine(request), isTrue);
    final seeded = controller.draft!;
    expect(store.saved, isNull);
    expect(seeded.workoutTitle, 'Day One');
    expect(seeded.exercises.single.sets.single.prescription.reps, 8);
    expect(seeded.exercises.single.sets.single.reps, isNull);

    // ActiveWorkoutPage calls restoreOrStart on entry. The store still reads
    // empty, and its retry writes still fail.
    expect(await controller.restoreOrStart(), isTrue);
    expect(identical(controller.draft, seeded), isTrue);
    expect(store.saved, isNull);

    store.failSave = false;
    expect(await controller.restoreOrStart(), isTrue);
    expect(identical(controller.draft, seeded), isTrue);
    expect(store.saved!.id, seeded.id);
    expect(store.saved!.saveRequestId, seeded.saveRequestId);
    expect(store.saved!.workoutTitle, 'Day One');
    expect(store.saved!.exercises.single.sets.single.reps, isNull);
  });

  test('two-day background gap pauses at two hours and preserves the draft',
      () async {
    final store = _Store();
    var now = DateTime.utc(2026, 11, 10, 8);
    final first = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
      clock: () => now,
      newUuid: () => _id(100),
    );
    expect(await first.restoreOrStart(), isTrue);
    final draftId = first.draft!.id;
    now = now.add(const Duration(minutes: 10));
    expect(await first.markBackgrounded(), isTrue);
    expect(store.saved!.backgroundedAtUtc, now);
    first.dispose();

    now = now.add(const Duration(days: 2));
    final reopened = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
      clock: () => now,
    );
    expect(await reopened.restoreExisting(), isTrue);
    expect(reopened.draft!.id, draftId);
    expect(reopened.draft!.time.isPaused, isTrue);
    expect(
        reopened.draft!.time.pausedAtUtc, DateTime.utc(2026, 11, 10, 10, 10));
    expect(reopened.draft!.time.elapsedActiveDuration(now),
        const Duration(hours: 2, minutes: 10));
    expect(reopened.draft!.backgroundedAtUtc, isNull);
    expect(store.saved!.time.isPaused, isTrue);
    expect(await reopened.resume(), isTrue);
    expect(reopened.draft!.time.isPaused, isFalse);
    expect(reopened.draft!.id, draftId);
    reopened.dispose();
  });

  test('short background gap keeps running and clears the durable marker',
      () async {
    final store = _Store();
    var now = DateTime.utc(2026, 11, 10, 8);
    final controller = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
      clock: () => now,
      newUuid: () => _id(101),
    );
    expect(await controller.restoreOrStart(), isTrue);
    now = now.add(const Duration(minutes: 5));
    expect(await controller.markBackgrounded(), isTrue);
    now = now.add(const Duration(minutes: 30));
    expect(await controller.restoreExisting(), isTrue);
    expect(controller.draft!.time.isPaused, isFalse);
    expect(controller.draft!.backgroundedAtUtc, isNull);
    expect(store.saved!.backgroundedAtUtc, isNull);
    controller.dispose();
  });

  test('backgrounding during restore still caps unattended active time',
      () async {
    final store = _Store()
      ..saved = ActiveWorkoutDraft(
        id: _id(110),
        ownerId: owner,
        saveRequestId: _id(111),
        time: WorkoutTime.start(startedAtUtc: DateTime.utc(2026, 11, 10, 8)),
      );
    var now = DateTime.utc(2026, 11, 10, 8, 5);
    final loadGate = Completer<void>();
    store.loadGate = loadGate;
    final controller = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
      clock: () => now,
    );
    final restore = controller.restoreExisting();
    await Future<void>.delayed(Duration.zero);
    expect(controller.draft, isNull);
    expect(await controller.markBackgrounded(), isTrue);
    now = now.add(const Duration(hours: 3));
    loadGate.complete();
    expect(await restore, isTrue);
    expect(controller.draft!.time.isPaused, isTrue);
    expect(
      controller.draft!.time.pausedAtUtc,
      DateTime.utc(2026, 11, 10, 10, 5),
    );
    controller.dispose();
  });

  test('stale pending backgrounding does not break a later fresh Play start',
      () async {
    final store = _Store();
    var now = DateTime.utc(2026, 11, 10, 8);
    final loadGate = Completer<void>();
    store.loadGate = loadGate;
    final controller = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
      clock: () => now,
      newUuid: () => _id(112),
    );
    final emptyRestore = controller.restoreExisting();
    await Future<void>.delayed(Duration.zero);
    expect(await controller.markBackgrounded(), isTrue);
    now = now.add(const Duration(hours: 3));
    loadGate.complete();
    expect(await emptyRestore, isTrue);
    expect(controller.draft, isNull);

    store.loadGate = null;
    expect(await controller.restoreOrStart(), isTrue);
    expect(controller.draft, isNotNull);
    expect(controller.draft!.time.isPaused, isFalse);
    expect(controller.draft!.backgroundedAtUtc, isNull);
    controller.dispose();
  });

  test('pending backgrounding is ignored for an already-paused restored draft',
      () async {
    final started = DateTime.utc(2026, 11, 10, 8);
    final pausedAt = DateTime.utc(2026, 11, 10, 8, 20);
    final store = _Store()
      ..saved = ActiveWorkoutDraft(
        id: _id(113),
        ownerId: owner,
        saveRequestId: _id(114),
        time: WorkoutTime.start(startedAtUtc: started).pause(pausedAt),
      );
    var now = pausedAt;
    final loadGate = Completer<void>();
    store.loadGate = loadGate;
    final controller = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
      clock: () => now,
    );
    final restore = controller.restoreExisting();
    await Future<void>.delayed(Duration.zero);
    expect(await controller.markBackgrounded(), isTrue);
    now = now.add(const Duration(hours: 3));
    loadGate.complete();
    expect(await restore, isTrue);
    expect(controller.draft, isNotNull);
    expect(controller.draft!.time.isPaused, isTrue);
    expect(controller.draft!.time.pausedAtUtc, pausedAt);
    expect(controller.draft!.backgroundedAtUtc, isNull);
    controller.dispose();
  });

  test(
      'backgrounding during busy restore still caps an in-memory running draft',
      () async {
    final store = _Store();
    var now = DateTime.utc(2026, 11, 10, 8);
    final controller = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
      clock: () => now,
      newUuid: () => _id(115),
    );
    expect(await controller.restoreOrStart(), isTrue);
    final draftId = controller.draft!.id;
    now = now.add(const Duration(minutes: 10));
    final loadGate = Completer<void>();
    store.loadGate = loadGate;
    final restore = controller.restoreExisting();
    await Future<void>.delayed(Duration.zero);
    expect(controller.isBusy, isTrue);
    expect(await controller.markBackgrounded(), isTrue);
    expect(store.saved!.backgroundedAtUtc, isNull);
    now = now.add(const Duration(hours: 3));
    loadGate.complete();
    expect(await restore, isTrue);
    expect(controller.draft!.id, draftId);
    expect(controller.draft!.time.isPaused, isTrue);
    expect(
      controller.draft!.time.pausedAtUtc,
      DateTime.utc(2026, 11, 10, 10, 10),
    );
    controller.dispose();
  });

  test('oversized Save title is rejected before the submission freezes',
      () async {
    final store = _Store();
    final backend = _SaveRepository()..fail = false;
    var now = DateTime.utc(2026, 11, 9, 10);
    var nextId = 120;
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
    expect(
        await controller.toggleLogged(exercise.id, exercise.sets.single.id,
            reps: 8),
        isTrue);
    expect(await controller.pause(), isTrue);
    expect(
        await controller.updateSaveMetadata(
          title: 'ok',
          description: null,
          workoutAtUtc: DateTime.utc(2026, 11, 9, 10),
          workoutUtcOffsetMinutes: 0,
          selectedDurationSeconds: 60,
          gymName: null,
          activityType: 'Weight Training',
          overallRpe: null,
        ),
        isTrue);
    final huge = 'x' * 2001;
    expect(await controller.save(resolvedTitle: huge), isFalse);
    expect(controller.draft!.submittedAtUtc, isNull);
    expect(backend.submissions, isEmpty);
    expect(
        await controller.updateSaveMetadata(
          title: 'Fixed title',
          description: null,
          workoutAtUtc: DateTime.utc(2026, 11, 9, 10),
          workoutUtcOffsetMinutes: 0,
          selectedDurationSeconds: 60,
          gymName: null,
          activityType: 'Weight Training',
          overallRpe: null,
        ),
        isTrue);
    expect(await controller.save(resolvedTitle: 'Fixed title'), isTrue);
    controller.dispose();
  });

  test('cold restore caps an active draft when background event was missed',
      () async {
    final store = _Store();
    var now = DateTime.utc(2026, 11, 10, 8);
    final first = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
      clock: () => now,
      newUuid: () => _id(102),
    );
    expect(await first.restoreOrStart(), isTrue);
    now = now.add(const Duration(minutes: 25));
    expect(await first.addExercises([_exercise('ex_first', 'First')]), isTrue);
    first.dispose();

    now = now.add(const Duration(days: 2));
    final reopened = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
      clock: () => now,
    );
    expect(await reopened.restoreExisting(), isTrue);
    expect(
        reopened.draft!.time.pausedAtUtc, DateTime.utc(2026, 11, 10, 10, 25));
    expect(reopened.draft!.exercises.single.displayName, 'First');
    reopened.dispose();
  });

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

  test('subtracting beyond remaining rest cancels without expired deadline',
      () async {
    final store = _Store();
    var now = DateTime.utc(2026, 11, 12, 10);
    var nextId = 400;
    final controller = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
      clock: () => now,
      newUuid: () => _id(nextId++),
    );
    addTearDown(controller.dispose);
    expect(await controller.restoreOrStart(), isTrue);
    expect(
        await controller.addExercises(
          [_exercise('ex_first', 'First')],
          initialRestPreset:
              const RoutineRestTimerPreset(normalRestSeconds: 60),
        ),
        isTrue);
    final exercise = controller.draft!.exercises.single;
    expect(
        await controller.toggleLogged(
          exercise.id,
          exercise.sets.single.id,
          reps: 8,
        ),
        isTrue);
    expect(controller.draft!.activeRest, isNotNull);
    now = now.add(const Duration(seconds: 50));
    expect(await controller.adjustRest(-15), isTrue);
    expect(controller.draft!.activeRest, isNull);
    expect(store.saved!.activeRest, isNull);
  });

  test('new Exercise rest default snapshots, recovers, and drives countdown',
      () async {
    final store = _Store();
    var nextId = 200;
    var now = DateTime.utc(2026, 11, 12, 10);
    final controller = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
      clock: () => now,
      newUuid: () => _id(nextId++),
    );
    expect(await controller.restoreOrStart(), isTrue);

    expect(
      await controller.addExercises(
        [_exercise('ex_first', 'First')],
        initialRestPreset: const RoutineRestTimerPreset(normalRestSeconds: 60),
      ),
      isTrue,
    );
    final first = controller.draft!.exercises.single;
    expect(first.hasRestOverride, isTrue);
    expect(first.restPreset.normalRestSeconds, 60);
    expect(await controller.addSet(first.id), isTrue);
    final secondSet = controller.draft!.exercises.single.sets.last;

    expect(
      await controller.addExercises(
        [_exercise('ex_second', 'Second')],
        initialRestPreset: const RoutineRestTimerPreset(normalRestSeconds: 90),
      ),
      isTrue,
    );
    expect(controller.draft!.exercises.first.restPreset.normalRestSeconds, 60);
    expect(controller.draft!.exercises.last.restPreset.normalRestSeconds, 90);
    expect(
      await controller.setRestPreset(
        first.id,
        const RoutineRestTimerPreset(normalRestSeconds: 120),
      ),
      isTrue,
    );

    expect(
      await controller.toggleLogged(
        first.id,
        first.sets.first.id,
        reps: 8,
      ),
      isTrue,
    );
    expect(controller.draft!.activeRest?.totalDurationSeconds, 120);
    expect(
      await controller.setRestPreset(
        first.id,
        const RoutineRestTimerPreset(),
      ),
      isTrue,
    );
    expect(await controller.skipRest(), isTrue);
    expect(
      await controller.toggleLogged(first.id, secondSet.id, reps: 8),
      isTrue,
    );
    expect(controller.draft!.activeRest, isNull);
    controller.dispose();

    final recovered = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
    );
    expect(await recovered.restoreExisting(), isTrue);
    final recoveredFirst = recovered.draft!.exercises.first;
    expect(recoveredFirst.hasRestOverride, isTrue);
    expect(recoveredFirst.restPreset.isOff, isTrue);
    expect(recovered.draft!.exercises.last.restPreset.normalRestSeconds, 90);
    expect(recovered.draft!.activeRest, isNull);
    recovered.dispose();

    final offController = ActiveWorkoutDraftController(
      store: _Store(),
      ownerId: owner,
      newUuid: () => _id(nextId++),
    );
    expect(await offController.restoreOrStart(), isTrue);
    expect(
      await offController.addExercises(
        [_exercise('ex_off', 'OFF Exercise')],
        initialRestPreset: const RoutineRestTimerPreset(),
      ),
      isTrue,
    );
    final offExercise = offController.draft!.exercises.single;
    expect(offExercise.hasRestOverride, isTrue);
    expect(offExercise.restPreset.isOff, isTrue);
    expect(
      await offController.toggleLogged(
        offExercise.id,
        offExercise.sets.single.id,
        reps: 8,
      ),
      isTrue,
    );
    expect(offController.draft!.activeRest, isNull);
    offController.dispose();
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

  test('secure read failure fails closed instead of starting a new workout',
      () async {
    final store = _Store()..failLoad = true;
    final controller = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
      clock: () => DateTime.utc(2026, 11, 9),
    );
    // Unreadable owner-bound slot is unknown, not empty.
    expect(await controller.restoreOrStart(), isFalse);
    expect(controller.draft, isNull);
    expect(controller.error, isA<StateError>());
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

  test('removing an unrelated ungrouped exercise preserves active rest',
      () async {
    final now = DateTime.utc(2026, 11, 13, 10);
    final store = _Store();
    var nextId = 200;
    final controller = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
      clock: () => now,
      newUuid: () => _id(nextId++),
    );
    addTearDown(controller.dispose);
    expect(await controller.restoreOrStart(), isTrue);
    expect(
        await controller.addExercises([
          _exercise('ex_first', 'First'),
          _exercise('ex_second', 'Second'),
        ],
            initialRestPreset:
                const RoutineRestTimerPreset(normalRestSeconds: 60)),
        isTrue);
    final first = controller.draft!.exercises.first;
    final second = controller.draft!.exercises.last;
    expect(
        await controller.toggleLogged(first.id, first.sets.single.id, reps: 8),
        isTrue);
    final rest = controller.draft!.activeRest;
    expect(rest, isNotNull);
    expect(await controller.removeExercise(second.id), isTrue);
    expect(controller.draft!.activeRest!.setId, rest!.setId);
    expect(await controller.removeExercise(first.id), isTrue);
    expect(controller.draft!.activeRest, isNull);
  });

  test('Superset round timer waits for all available members and restores',
      () async {
    var now = DateTime.utc(2026, 11, 12, 8);
    var nextId = 1000;
    final store = _Store();
    var controller = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
      clock: () => now,
      newUuid: () => _id(nextId++),
    );
    addTearDown(() => controller.dispose());
    expect(await controller.restoreOrStart(), isTrue);
    expect(
      await controller.addExercises(
        [_exercise('ex_first', 'First'), _exercise('ex_second', 'Second')],
        initialRestPreset: const RoutineRestTimerPreset(
          normalRestSeconds: 45,
          warmUpRestSeconds: 15,
        ),
      ),
      isTrue,
    );
    var first = controller.draft!.exercises[0];
    final second = controller.draft!.exercises[1];
    expect(await controller.addSet(first.id), isTrue);
    expect(await controller.addSet(first.id), isTrue);
    first = controller.draft!.exercises[0];
    expect(
        await controller.setType(
            first.id, first.sets[0].id, RoutineSetType.warmUp),
        isTrue);
    expect(await controller.createSuperset(first.id, second.id), isTrue);
    final groupId = controller.draft!.exercises.first.supersetId!;

    first = controller.draft!.exercises.first;
    final secondSet = controller.draft!.exercises
        .firstWhere((exercise) => exercise.id == second.id)
        .sets
        .single;
    expect(await controller.toggleLogged(first.id, first.sets[0].id), isTrue);
    expect(controller.draft!.activeRest, isNull);
    expect(
      await controller.toggleLogged(second.id, secondSet.id, isSkipped: true),
      isTrue,
    );
    expect(controller.draft!.activeRest!.supersetId, groupId);
    expect(controller.draft!.activeRest!.roundIndex, 0);
    expect(controller.draft!.activeRest!.totalDurationSeconds, 15);

    controller.dispose();
    controller = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
      clock: () => now,
      newUuid: () => _id(nextId++),
    );
    expect(await controller.restoreOrStart(), isTrue);
    expect(controller.draft!.supersets.single.id, groupId);
    expect(controller.draft!.activeRest!.remaining(now),
        const Duration(seconds: 15));
    expect(
      await controller.configureSupersetRestTimer(
        groupId,
        normalRestSeconds: 60,
        warmUpRestSeconds: 20,
      ),
      isTrue,
    );
    // An active countdown retains the duration captured when it started.
    expect(controller.draft!.activeRest!.totalDurationSeconds, 15);

    expect(await controller.skipRest(), isTrue);
    first = controller.draft!.exercises.first;
    final secondRound = first.sets[1];
    expect(
        await controller.setType(
            first.id, secondRound.id, RoutineSetType.failure),
        isTrue);
    expect(await controller.toggleLogged(first.id, secondRound.id), isTrue);
    expect(controller.draft!.activeRest!.roundIndex, 1);
    expect(controller.draft!.activeRest!.totalDurationSeconds, 60);
    expect(await controller.removeFromSuperset(first.id), isFalse);
    expect(await controller.removeSet(first.id, first.sets[2].id), isFalse);

    expect(await controller.skipRest(), isTrue);
    first = controller.draft!.exercises.first;
    expect(await controller.toggleLogged(first.id, first.sets[2].id), isTrue);
    expect(controller.draft!.activeRest, isNull, reason: 'no final rest');

    // Unlogging every completed set reopens membership editing and cancels rest.
    first = controller.draft!.exercises.first;
    for (final set in first.sets) {
      expect(await controller.toggleLogged(first.id, set.id), isTrue);
    }
    expect(await controller.toggleLogged(second.id, secondSet.id), isTrue);
    expect(controller.draft!.activeRest, isNull);
    expect(await controller.removeFromSuperset(first.id), isTrue);
    expect(controller.draft!.supersets, isEmpty);
    expect(
        controller.draft!.exercises
            .every((exercise) => exercise.supersetId == null),
        isTrue);
  });

  test('discardForReplacement clears durable draft for Play replacement',
      () async {
    final store = _Store();
    final controller = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
      newUuid: () => _id(50),
    );
    expect(await controller.restoreOrStart(), isTrue);
    expect(store.saved, isNotNull);
    expect(await controller.discardForReplacement(), isTrue);
    expect(controller.draft, isNull);
    expect(store.saved, isNull);
    controller.dispose();
  });

  test('removing the last set drops the empty exercise from the draft',
      () async {
    final store = _Store();
    var nextId = 60;
    final controller = ActiveWorkoutDraftController(
      store: store,
      ownerId: owner,
      newUuid: () => _id(nextId++),
    );
    expect(await controller.restoreOrStart(), isTrue);
    expect(
      await controller.addExercises([
        _exercise('ex_a', 'A'),
        _exercise('ex_b', 'B'),
      ]),
      isTrue,
    );
    final first = controller.draft!.exercises.first;
    final second = controller.draft!.exercises.last;
    expect(await controller.removeSet(first.id, first.sets.single.id), isTrue);
    expect(controller.draft!.exercises.map((e) => e.id), [second.id]);
    expect(controller.draft!.exercises.single.sets, isNotEmpty);
    controller.dispose();
  });

  test('removeSet keeps activeRest when a different set is removed', () async {
    var now = DateTime.utc(2026, 11, 10, 9);
    final store = _Store()
      ..saved = ActiveWorkoutDraft(
        id: _id(70),
        ownerId: owner,
        saveRequestId: _id(71),
        time: WorkoutTime.start(startedAtUtc: now),
        exercises: [
          ActiveWorkoutDraftExercise(
            id: _id(72),
            exerciseRef: ExerciseRef.catalog('ex_rest'),
            displayName: 'Rest keep',
            sets: [
              ActiveWorkoutDraftSet(
                id: _id(73),
                prescription: SetPrescription(reps: 8),
              ),
              ActiveWorkoutDraftSet(
                id: _id(74),
                prescription: SetPrescription(reps: 8, restSeconds: 45),
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
    expect(await controller.toggleLogged(_id(72), _id(74), reps: 8), isTrue);
    expect(controller.draft!.activeRest!.setId, _id(74));
    expect(await controller.removeSet(_id(72), _id(73)), isTrue);
    expect(controller.draft!.activeRest!.setId, _id(74));
    expect(await controller.removeSet(_id(72), _id(74)), isTrue);
    expect(controller.draft!.activeRest, isNull);
    controller.dispose();
  });
}
