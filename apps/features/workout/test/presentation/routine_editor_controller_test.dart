import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _p = '10000000-0000-4000-8000-000000000001';
const _otherP = '10000000-0000-4000-8000-000000000002';
const _r = '20000000-0000-4000-8000-000000000001';
const _e = '30000000-0000-4000-8000-000000000001';
const _s = '40000000-0000-4000-8000-000000000001';
const _newE = '30000000-0000-4000-8000-000000000009';
const _newS = '40000000-0000-4000-8000-000000000009';
const _m = '60000000-0000-4000-8000-000000000001';
const _ref = 'ex_bench_press';

Program get _program => Program(id: ProgramId(_p), name: 'Training');
Routine _routine([String program = _p]) =>
    Routine(id: RoutineId(_r), programId: ProgramId(program), name: 'Day 1');

RoutineCompositionSnapshot _snapshot({
  List<RoutineCompositionEntry> entries = const [],
  int revision = 4,
  String? mutationId,
}) => RoutineCompositionSnapshot(
  routineId: RoutineId(_r),
  revision: revision,
  lastMutationId: mutationId,
  entries: entries,
);

RoutineCompositionEntry _entry() => RoutineCompositionEntry(
  id: _e,
  exercise: ExerciseRef.catalog(_ref),
  sets: [
    RoutineCompositionSet(
      id: _s,
      prescription: SetPrescription(reps: 8, loadKg: 12.5, restSeconds: 30),
    ),
  ],
);

RoutineEditorController _make(
  _Routines routines,
  _Compositions compositions, {
  Routine? selected,
  List<String>? ids,
}) {
  final iterator = (ids ?? [_newE, _newS, _m]).iterator;
  return RoutineEditorController(
    program: _program,
    routine: selected ?? _routine(),
    routines: routines,
    compositions: compositions,
    newUuid: () {
      if (!iterator.moveNext()) throw StateError('Unexpected UUID request');
      return iterator.current;
    },
  );
}

void main() {
  test('Replace creates fresh blank Set and saves once without old targets',
      () async {
    final comp = _Compositions(_snapshot(entries: [_entry()]));
    final ctrl = _make(_Routines([_routine()]), comp);
    addTearDown(ctrl.dispose);
    await ctrl.load();
    final replacement = Exercise(
      ref: ExerciseRef.catalog('ex_run_on_treadmill'),
      displayName: 'Run on Treadmill',
      status: ExerciseStatus.active,
      exerciseType: ExerciseType.distanceDuration,
    );
    final id = ctrl.replacePickedExercise(_e, replacement);
    expect(id, _newE);
    expect(ctrl.replacePickedExercise(_newE, replacement), isNull);
    expect(ctrl.state.entries.single.id, _newE);
    expect(ctrl.state.entries.single.sets.single.id, _newS);
    expect(ctrl.state.entries.single.sets.single.prescription.reps, isNull);
    expect(ctrl.state.entries.single.sets.single.prescription.loadKg, isNull);
    expect(comp.saveCount, 0);
    expect(await ctrl.update(), isTrue);
    expect(comp.saveCount, 1);
    expect(comp.lastSave!.entries.single.exercise, replacement.ref);
    expect(comp.lastSave!.entries.single.sets.single.id, _newS);
  });

  test('Steps/Duration Custom cannot enter Edit or replace saved Exercise',
      () async {
    final comp = _Compositions(_snapshot(entries: [_entry()]));
    final ctrl = _make(_Routines([_routine()]), comp);
    addTearDown(ctrl.dispose);
    await ctrl.load();
    final steps = Exercise(
      ref: ExerciseRef.userCreated('70000000-0000-4000-8000-000000000123'),
      displayName: 'Step Mill',
      status: ExerciseStatus.active,
      exerciseType: ExerciseType.stepsDuration,
    );
    expect(ctrl.addPickedExercise(steps), isNull);
    expect(ctrl.replacePickedExercise(_e, steps), isNull);
    expect(ctrl.state.entries.single.id, _e);
    expect(ctrl.state.entries.single.exercise, ExerciseRef.catalog(_ref));
    expect(ctrl.state.dirty, isFalse);
    expect(comp.saveCount, 0);
  });

  test('Edit cannot add a ninth Set to the same Exercise', () async {
    final ids = [
      for (var index = 0; index < 7; index++)
        '50000000-0000-4000-8000-${index.toString().padLeft(12, '0')}',
      _m,
    ];
    final repository = _Compositions(_snapshot(entries: [_entry()]));
    final controller = _make(_Routines([_routine()]), repository, ids: ids);
    addTearDown(controller.dispose);
    await controller.load();
    for (var index = 1; index < 8; index++) {
      expect(controller.addSet(_e, SetPrescription()), isNotNull);
    }
    expect(controller.state.entries.single.sets, hasLength(8));
    expect(controller.addSet(_e, SetPrescription()), isNull);
    expect(controller.state.entries.single.sets, hasLength(8));
    // No silent ninth Set persists after the rejected operation.
    expect(await controller.update(), isTrue);
    expect(repository.lastSave!.entries.single.sets, hasLength(8));
  });

  test('historical nine Sets load intact but cannot Update until reduced',
      () async {
    final oldSets = [
      for (var index = 0; index < 9; index++)
        RoutineCompositionSet(
          id: '50000000-0000-4000-8000-${index.toString().padLeft(12, '0')}',
          prescription: SetPrescription(reps: 8),
        ),
    ];
    final historical = RoutineCompositionEntry(
      id: _e, exercise: ExerciseRef.catalog(_ref), sets: oldSets,
    );
    final comp = _Compositions(_snapshot(entries: [historical]));
    final ctrl = _make(_Routines([_routine()]), comp, ids: [_m]);
    addTearDown(ctrl.dispose);
    await ctrl.load();
    expect(ctrl.state.entries.single.sets, hasLength(9));
    expect(ctrl.exceedsSetLimit, isTrue);
    expect(ctrl.editSet(_e, oldSets.first.id, SetPrescription(reps: 10)),
        isTrue);
    expect(await ctrl.update(), isFalse);
    expect(ctrl.state.status, RoutineEditorStatus.ready);
    expect(ctrl.state.message, contains('at most 8 Sets'));
    expect(comp.saveCount, 0);
    expect(ctrl.removeSet(_e, oldSets.last.id), isTrue);
    expect(ctrl.exceedsSetLimit, isFalse);
    expect(ctrl.state.entries.single.sets, hasLength(8));
    expect(await ctrl.update(), isTrue);
    expect(comp.saveCount, 1);
    expect(comp.lastSave!.entries.single.sets, hasLength(8));
    expect(comp.lastSave!.entries.single.sets.first.prescription.reps, 10);
    expect(oldSets.first.id, comp.lastSave!.entries.single.sets.first.id);
  });

  test('wrong owning Program refuses metadata and composition reads', () async {
    final routines = _Routines([_routine()]);
    final compositions = _Compositions(_snapshot());
    final ctrl = _make(routines, compositions, selected: _routine(_otherP));
    addTearDown(ctrl.dispose);
    await ctrl.load();
    expect(ctrl.state.status, RoutineEditorStatus.notFound);
    expect(routines.readCount, 0);
    expect(compositions.readCount, 0);
    expect(await ctrl.update(), isFalse);
    expect(compositions.saveCount, 0);
  });

  test('missing or cross-owner Routine cannot expose private data', () async {
    final routines = _Routines([_routine(_otherP)]);
    final comp = _Compositions(_snapshot());
    final ctrl = _make(routines, comp);
    addTearDown(ctrl.dispose);
    await ctrl.load();
    expect(ctrl.state.status, RoutineEditorStatus.loadFailed);
    expect(ctrl.state.entries, isEmpty);
    expect(comp.readCount, 0);
  });

  test('draft edit retains persisted IDs, duplicates canonical refs and saves once', () async {
    final comp = _Compositions(_snapshot(entries: [_entry()]));
    final ctrl = _make(_Routines([_routine()]), comp);
    addTearDown(ctrl.dispose);
    await ctrl.load();
    expect(ctrl.state.status, RoutineEditorStatus.ready);
    expect(ctrl.state.dirty, isFalse);

    expect(ctrl.editSet(_e, _s, SetPrescription(
      reps: 10,
      loadKg: 20,
      restSeconds: 45,
    )), isTrue);
    expect(ctrl.addPickedExercise(Exercise(
      ref: ExerciseRef.catalog(_ref),
      displayName: 'Bench',
      status: ExerciseStatus.active,
    )), _newE);
    expect(ctrl.addSet(_newE, SetPrescription(reps: 6)), _newS);
    expect(ctrl.moveExercise(1, 0), isTrue);
    expect(ctrl.state.entries.map((entry) => entry.id), [_newE, _e]);
    expect(ctrl.state.entries[1].sets.single.id, _s);
    expect(ctrl.state.entries[1].sets.single.prescription.reps, 10);
    expect(ctrl.state.entries[0].sets.single.id, _newS);
    expect(ctrl.state.dirty, isTrue);

    expect(await ctrl.update(), isTrue);
    expect(comp.saveCount, 1);
    expect(comp.lastSave?.expectedRevision, 4);
    expect(comp.lastSave?.mutationId, _m);
    expect(comp.lastSave?.routineId, RoutineId(_r));
    expect(comp.lastSave?.entries[0].exercise, ExerciseRef.catalog(_ref));
    expect(comp.lastSave?.entries[1].exercise, ExerciseRef.catalog(_ref));
    expect(ctrl.state.status, RoutineEditorStatus.saved);
    expect(ctrl.state.revision, 5);
    expect(await ctrl.update(), isFalse);
    expect(comp.saveCount, 1);
  });

  test('existing Edit preserves rich type/range and new Set adopts mode',
      () async {
    final enriched = RoutineCompositionEntry(
      id: _e,
      exercise: ExerciseRef.catalog(_ref),
      sets: [
        RoutineCompositionSet(
          id: _s,
          prescription: SetPrescription(
            reps: 8, repsMax: 12, setType: RoutineSetType.warmUp,
            loadKg: 12.5, restSeconds: 30,
          ),
        ),
      ],
    );
    final comp = _Compositions(_snapshot(entries: [enriched]));
    final ctrl = _make(_Routines([_routine()]), comp,
        ids: [_newS, _m]);
    addTearDown(ctrl.dispose);
    await ctrl.load();
    expect(ctrl.addSet(_e, SetPrescription(reps: 5)), _newS);
    expect(ctrl.state.entries.single.sets[1].prescription.repsMax, 5);
    expect(ctrl.state.entries.single.sets[1].prescription.setType,
        RoutineSetType.normal);
    expect(ctrl.editSet(_e, _s, SetPrescription(
      reps: 9, repsMax: 13, setType: RoutineSetType.warmUp,
      loadKg: 12.5, restSeconds: 30,
    )), isTrue);
    expect(await ctrl.update(), isTrue);
    expect(comp.lastSave!.entries.single.sets.first.prescription.setType,
        RoutineSetType.warmUp);
    expect(comp.lastSave!.entries.single.sets.first.prescription.repsMax, 13);
    expect(comp.lastSave!.entries.single.sets.last.prescription.repsMax, 5);
  });

  test('add/remove/reorder sets and cancel never write before Update', () async {
    final comp = _Compositions(_snapshot(entries: [_entry()]));
    final ctrl = _make(_Routines([_routine()]), comp, ids: [_newS]);
    await ctrl.load();
    expect(ctrl.addSet(_e, SetPrescription(reps: 12)), _newS);
    expect(ctrl.moveSet(_e, 1, 0), isTrue);
    expect(ctrl.state.entries.single.sets.first.id, _newS);
    expect(ctrl.removeSet(_e, _newS), isTrue);
    expect(ctrl.state.dirty, isFalse);
    expect(ctrl.removeExercise(_e), isTrue);
    expect(ctrl.state.entries, isEmpty);
    ctrl.dispose();
    expect(comp.saveCount, 0);
  });

  test('revision conflict locks draft and never rebases or retries RPC', () async {
    final comp = _Compositions(_snapshot(entries: [_entry()]))
      ..saveError = const RoutineCompositionException(
        RoutineCompositionFailureKind.revisionConflict,
      );
    final ctrl = _make(_Routines([_routine()]), comp, ids: [_m]);
    addTearDown(ctrl.dispose);
    await ctrl.load();
    expect(ctrl.removeExercise(_e), isTrue);
    expect(await ctrl.update(), isFalse);
    expect(ctrl.state.status, RoutineEditorStatus.revisionConflict);
    expect(await ctrl.update(), isFalse);
    expect(comp.saveCount, 1);
  });

  test('unconfirmed write is frozen; read-only reconciliation confirms same mutation', () async {
    final comp = _Compositions(_snapshot(entries: [_entry()]))
      ..saveError = const RoutineCompositionSaveOutcomeUnknown();
    final ctrl = _make(_Routines([_routine()]), comp, ids: [_m]);
    addTearDown(ctrl.dispose);
    await ctrl.load();
    expect(ctrl.removeExercise(_e), isTrue);
    expect(await ctrl.update(), isFalse);
    expect(ctrl.state.status, RoutineEditorStatus.outcomeUnknown);
    expect(await ctrl.update(), isFalse);
    expect(comp.saveCount, 1);
    comp.snapshot = _snapshot(entries: const [], revision: 5, mutationId: _m);
    expect(await ctrl.reconcileUnknown(), isTrue);
    expect(ctrl.state.status, RoutineEditorStatus.saved);
    expect(comp.saveCount, 1);
    expect(comp.readCount, 2);
  });

  test('Custom draft cannot save without current-owner repository capability',
      () async {
    final custom = RoutineCompositionEntry(
      id: _e,
      exercise: UserCreatedExerciseRef(
          '70000000-0000-4000-8000-000000000001'),
      sets: [
        RoutineCompositionSet(
          id: _s,
          prescription: SetPrescription(reps: 8),
        ),
      ],
    );
    final comp = _Compositions(_snapshot(entries: [custom]));
    final ctrl = _make(_Routines([_routine()]), comp, ids: [_m]);
    addTearDown(ctrl.dispose);
    await ctrl.load();
    expect(ctrl.editSet(_e, _s, SetPrescription(reps: 10)), isTrue);
    expect(await ctrl.update(), isFalse);
    expect(ctrl.state.status, RoutineEditorStatus.ready);
    expect(ctrl.state.message, contains('cannot be verified'));
    expect(comp.saveCount, 0);
  });

  test('Edit preflight blocks remotely retyped Custom STEPS/TIME', () async {
    final custom = RoutineCompositionEntry(
      id: _e,
      exercise: ExerciseRef.userCreated(
          '90000000-0000-4000-8000-000000000001'),
      sets: [RoutineCompositionSet(id: _s,
        prescription: SetPrescription(reps: 8))],
    );
    final comp = _Compositions(_snapshot(entries: [custom]));
    final ctrl = RoutineEditorController(
      program: _program, routine: _routine(),
      routines: _Routines([_routine()]), compositions: comp,
      userExercises: _StepExerciseRepository(), newUuid: () => _m,
    );
    addTearDown(ctrl.dispose);
    await ctrl.load();
    expect(ctrl.editSet(_e, _s, SetPrescription(reps: 9)), isTrue);
    expect(await ctrl.update(), isFalse);
    expect(ctrl.state.status, RoutineEditorStatus.ready);
    expect(ctrl.state.message, contains('Steps & Duration'));
    expect(comp.saveCount, 0);
  });

  test('Edit historical KG/REPS Custom cannot Update under new duration',
      () async {
    final historical = RoutineCompositionEntry(
      id: _e,
      exercise: ExerciseRef.userCreated(
        '90000000-0000-4000-8000-000000000001',
      ),
      sets: [RoutineCompositionSet(
        id: _s, prescription: SetPrescription(reps: 8, loadKg: 12),
      )],
    );
    final comp = _Compositions(_snapshot(entries: [historical]));
    final ctrl = RoutineEditorController(
      program: _program, routine: _routine(),
      routines: _Routines([_routine()]), compositions: comp,
      userExercises: _StepExerciseRepository(
        exerciseType: ExerciseType.duration,
      ),
      newUuid: () => _m,
    );
    addTearDown(ctrl.dispose);
    await ctrl.load();
    expect(ctrl.editSet(_e, _s, SetPrescription(reps: 9)), isTrue);
    expect(await ctrl.update(), isFalse);
    expect(ctrl.state.status, RoutineEditorStatus.ready);
    expect(ctrl.state.message, contains('type changed'));
    expect(comp.saveCount, 0);
    expect(ctrl.state.entries.single.sets.single.prescription.reps, 9);
  });

  test('Edit newly picked Custom KM/TIME cannot write after weightReps change',
      () async {
    final comp = _Compositions(_snapshot(entries: const []));
    final ids = [_newE, _newS, _m].iterator;
    final ctrl = RoutineEditorController(
      program: _program, routine: _routine(),
      routines: _Routines([_routine()]), compositions: comp,
      userExercises: _StepExerciseRepository(
        exerciseType: ExerciseType.weightReps,
      ),
      newUuid: () {
        if (!ids.moveNext()) throw StateError('Unexpected UUID');
        return ids.current;
      },
    );
    addTearDown(ctrl.dispose);
    await ctrl.load();
    final added = ctrl.addPickedExercise(Exercise(
      ref: ExerciseRef.userCreated(
        '90000000-0000-4000-8000-000000000001',
      ),
      displayName: 'Custom Run', status: ExerciseStatus.active,
      exerciseType: ExerciseType.distanceDuration,
    ))!;
    expect(ctrl.addSet(added, SetPrescription(
      distanceMeters: 1500, durationSeconds: 600,
    )), _newS);
    expect(await ctrl.update(), isFalse);
    expect(ctrl.state.message, contains('type changed'));
    expect(comp.saveCount, 0);
    expect(ctrl.state.entries.single.sets.single.prescription.distanceMeters,
        1500);
  });

  test('Edit preserves metric targets when Custom type became null, no RPC',
      () async {
    final metric = RoutineCompositionEntry(
      id: _e,
      exercise: ExerciseRef.userCreated(
        '90000000-0000-4000-8000-000000000001',
      ),
      sets: [RoutineCompositionSet(
        id: _s, prescription: SetPrescription(
          distanceMeters: 3000, durationSeconds: 900,
        ),
      )],
    );
    final comp = _Compositions(_snapshot(entries: [metric]));
    final ctrl = RoutineEditorController(
      program: _program, routine: _routine(),
      routines: _Routines([_routine()]), compositions: comp,
      userExercises: _StepExerciseRepository(exerciseType: null),
      newUuid: () => _m,
    );
    addTearDown(ctrl.dispose);
    await ctrl.load();
    expect(ctrl.editSet(_e, _s, SetPrescription(
      distanceMeters: 4000, durationSeconds: 900,
    )), isTrue);
    expect(await ctrl.update(), isFalse);
    expect(ctrl.state.message, contains('type changed'));
    expect(ctrl.state.status, RoutineEditorStatus.ready);
    expect(comp.saveCount, 0);
    expect(ctrl.state.entries.single.sets.single.prescription.distanceMeters,
        4000);
  });

  test('legacy untyped Custom Reps/Load remains editable without guessing',
      () async {
    final legacy = RoutineCompositionEntry(
      id: _e,
      exercise: ExerciseRef.userCreated(
        '90000000-0000-4000-8000-000000000001',
      ),
      sets: [RoutineCompositionSet(
        id: _s, prescription: SetPrescription(reps: 8, loadKg: 10),
      )],
    );
    final comp = _Compositions(_snapshot(entries: [legacy]));
    final ctrl = RoutineEditorController(
      program: _program, routine: _routine(),
      routines: _Routines([_routine()]), compositions: comp,
      userExercises: _StepExerciseRepository(exerciseType: null),
      newUuid: () => _m,
    );
    addTearDown(ctrl.dispose);
    await ctrl.load();
    expect(ctrl.editSet(_e, _s, SetPrescription(reps: 9, loadKg: 10)),
        isTrue);
    expect(await ctrl.update(), isTrue);
    expect(comp.saveCount, 1);
    expect(comp.lastSave!.entries.single.sets.single.prescription.reps, 9);
  });

  test('archived unchanged Custom stays while unrelated Set is edited',
      () async {
    final archived = RoutineCompositionEntry(
      id: _newE,
      exercise: ExerciseRef.userCreated(
        '90000000-0000-4000-8000-000000000001',
      ),
      sets: [
        RoutineCompositionSet(
          id: _newS,
          prescription: SetPrescription(
            reps: 6,
            loadKg: 10,
            setType: RoutineSetType.warmUp,
            restSeconds: 30,
          ),
        ),
      ],
    );
    final repo = _StepExerciseRepository(
      exerciseType: ExerciseType.stepsDuration,
      status: ExerciseStatus.archived,
    );
    final comp = _Compositions(_snapshot(entries: [_entry(), archived]));
    final ctrl = RoutineEditorController(
      program: _program,
      routine: _routine(),
      routines: _Routines([_routine()]),
      compositions: comp,
      userExercises: repo,
      newUuid: () => _m,
    );
    addTearDown(ctrl.dispose);
    await ctrl.load();
    expect(ctrl.editSet(
      _e, _s, SetPrescription(reps: 10, loadKg: 12.5, restSeconds: 30),
    ), isTrue);
    expect(ctrl.moveExercise(1, 0), isTrue);
    expect(await ctrl.update(), isTrue);
    expect(comp.saveCount, 1);
    expect(repo.archivedInclusiveReads, 1);
    expect(comp.lastSave!.entries.first, archived,
      reason: 'Set ID/order/targets for archived Custom must be untouched');
    expect(comp.lastSave!.entries.last.sets.first.prescription.reps, 10);
  });

  test('archived Custom Set edits fail closed with zero RPC writes', () async {
    final historical = RoutineCompositionEntry(
      id: _e,
      exercise: ExerciseRef.userCreated(
        '90000000-0000-4000-8000-000000000001',
      ),
      sets: [
        RoutineCompositionSet(
          id: _s,
          prescription: SetPrescription(reps: 8, loadKg: 12),
        ),
      ],
    );
    final repo = _StepExerciseRepository(status: ExerciseStatus.archived);
    final comp = _Compositions(_snapshot(entries: [historical]));
    final ctrl = RoutineEditorController(
      program: _program, routine: _routine(),
      routines: _Routines([_routine()]), compositions: comp,
      userExercises: repo, newUuid: () => _m,
    );
    addTearDown(ctrl.dispose);
    await ctrl.load();
    expect(ctrl.editSet(
      _e, _s, SetPrescription(reps: 9, loadKg: 12),
    ), isTrue);
    expect(await ctrl.update(), isFalse);
    expect(ctrl.state.status, RoutineEditorStatus.ready);
    expect(ctrl.state.message, contains('archived Custom Exercise'));
    expect(comp.saveCount, 0);
    expect(repo.archivedInclusiveReads, 1);
    expect(ctrl.state.entries.single.sets.single.prescription.reps, 9);
  });

  test('newly selected Custom archived remotely cannot be submitted',
      () async {
    final repo = _StepExerciseRepository(
      exerciseType: ExerciseType.weightReps,
      status: ExerciseStatus.archived,
    );
    final comp = _Compositions(_snapshot(entries: [_entry()]));
    final ids = [_newE, _newS, _m].iterator;
    final ctrl = RoutineEditorController(
      program: _program, routine: _routine(),
      routines: _Routines([_routine()]), compositions: comp,
      userExercises: repo,
      newUuid: () {
        if (!ids.moveNext()) throw StateError('Unexpected UUID');
        return ids.current;
      },
    );
    addTearDown(ctrl.dispose);
    await ctrl.load();
    final newEntry = ctrl.addPickedExercise(Exercise(
      ref: ExerciseRef.userCreated(
        '90000000-0000-4000-8000-000000000001',
      ),
      displayName: 'Picked before archive',
      status: ExerciseStatus.active,
      exerciseType: ExerciseType.weightReps,
    ));
    expect(newEntry, _newE);
    expect(ctrl.addSet(_newE, SetPrescription(reps: 10)), _newS);
    expect(await ctrl.update(), isFalse);
    expect(ctrl.state.message, contains('archived Custom Exercise'));
    expect(comp.saveCount, 0);
    expect(repo.archivedInclusiveReads, 1);
  });

  test('historical archived Custom entry may be removed', () async {
    final archived = RoutineCompositionEntry(
      id: _newE,
      exercise: ExerciseRef.userCreated(
        '90000000-0000-4000-8000-000000000001',
      ),
      sets: [
        RoutineCompositionSet(
          id: _newS, prescription: SetPrescription(reps: 8),
        ),
      ],
    );
    final comp = _Compositions(_snapshot(entries: [archived, _entry()]));
    final ctrl = _make(_Routines([_routine()]), comp, ids: [_m]);
    addTearDown(ctrl.dispose);
    await ctrl.load();
    expect(ctrl.removeExercise(_newE), isTrue);
    expect(await ctrl.update(), isTrue);
    expect(comp.saveCount, 1);
    expect(comp.lastSave!.entries.single.id, _e);
    expect(comp.lastSave!.entries.single.exercise, ExerciseRef.catalog(_ref));
  });

  test('Edit compatible Custom definition still updates without conversion',
      () async {
    final persisted = RoutineCompositionEntry(
      id: _e,
      exercise: ExerciseRef.userCreated(
        '90000000-0000-4000-8000-000000000001',
      ),
      sets: [RoutineCompositionSet(
        id: _s, prescription: SetPrescription(reps: 8, loadKg: 12),
      )],
    );
    final comp = _Compositions(_snapshot(entries: [persisted]));
    final ctrl = RoutineEditorController(
      program: _program, routine: _routine(),
      routines: _Routines([_routine()]), compositions: comp,
      userExercises: _StepExerciseRepository(
        exerciseType: ExerciseType.weightReps,
      ),
      newUuid: () => _m,
    );
    addTearDown(ctrl.dispose);
    await ctrl.load();
    expect(ctrl.editSet(_e, _s, SetPrescription(reps: 11, loadKg: 12)),
        isTrue);
    expect(await ctrl.update(), isTrue);
    expect(comp.saveCount, 1);
    expect(comp.lastSave!.entries.single.sets.single.prescription.reps, 11);
  });

  test('old pending save cannot submit twice even with repeated Update', () async {
    final comp = _Compositions(_snapshot(entries: [_entry()]));
    comp.saveGate = Completer<void>();
    final ctrl = _make(_Routines([_routine()]), comp, ids: [_m]);
    addTearDown(ctrl.dispose);
    await ctrl.load();
    expect(ctrl.removeExercise(_e), isTrue);
    final first = ctrl.update();
    expect(ctrl.state.status, RoutineEditorStatus.saving);
    expect(await ctrl.update(), isFalse);
    comp.saveGate!.complete();
    expect(await first, isTrue);
    expect(comp.saveCount, 1);
  });
}

final class _Routines implements RoutineRepository {
  _Routines(this.rows);
  final List<Routine> rows;
  int readCount = 0;

  @override
  Future<List<Routine>> list(ProgramId programId) async {
    readCount++;
    return rows;
  }

  @override
  Future<void> create(Routine routine) async => throw UnimplementedError();

  @override
  Future<void> rename({required RoutineId id, required String name}) async =>
      throw UnimplementedError();
}

final class _Compositions implements RoutineCompositionRepository {
  _Compositions(this.snapshot);
  RoutineCompositionSnapshot? snapshot;
  int saveCount = 0;
  int readCount = 0;
  RoutineCompositionSave? lastSave;
  Object? saveError;
  Completer<void>? saveGate;

  @override
  Future<RoutineCompositionSnapshot?> read(RoutineId id) async {
    readCount++;
    return snapshot;
  }

  @override
  Future<int> save(RoutineCompositionSave command) async {
    saveCount++;
    lastSave = command;
    if (saveGate != null) await saveGate!.future;
    if (saveError case final error?) throw error;
    return command.expectedRevision + 1;
  }
}

final class _StepExerciseRepository extends Fake
    implements UserExerciseRepository {
  _StepExerciseRepository({
    this.exerciseType = ExerciseType.stepsDuration,
    this.status = ExerciseStatus.active,
  });
  final ExerciseType? exerciseType;
  final ExerciseStatus status;
  int archivedInclusiveReads = 0;

  @override
  Future<List<Exercise>> list({bool includeArchived = false}) async {
    if (includeArchived) archivedInclusiveReads++;
    if (status == ExerciseStatus.archived && !includeArchived) return [];
    return [
      Exercise(
        ref: ExerciseRef.userCreated(
          '90000000-0000-4000-8000-000000000001',
        ),
        displayName: 'Custom Exercise',
        status: status,
        exerciseType: exerciseType,
      ),
    ];
  }
}
