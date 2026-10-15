import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _programId = '11111111-1111-4111-8111-111111111111';
const _routineId = '22222222-2222-4222-8222-222222222222';
const _mutation = '33333333-3333-4333-8333-333333333333';
const _entry1 = '44444444-4444-4444-8444-444444444444';
const _set1 = '55555555-5555-4555-8555-555555555555';
const _entry2 = '66666666-6666-4666-8666-666666666666';
const _set2 = '77777777-7777-4777-8777-777777777777';

RoutineCreateController _controller(
  _Creates repo, {
  String name = 'Routine 1',
  bool saveAfterOneExercise = false,
  bool retryAfterDefiniteFailure = false,
}) {
  // Create gives every picked Exercise its own Set ID before allocating
  // Routine/mutation IDs. Keep the test fixture's allocation order explicit.
  final ids = [
    _entry1, _set1,
    if (!saveAfterOneExercise) ...[_entry2, _set2],
    _routineId, _mutation,
    if (retryAfterDefiniteFailure) ...[
      '88888888-8888-4888-8888-888888888888',
      '99999999-9999-4999-8999-999999999999',
    ],
  ].iterator;
  return RoutineCreateController(
    program: Program(id: ProgramId(_programId), name: 'Program 1'),
    initialName: name,
    repository: repo,
    newUuid: () {
      if (!ids.moveNext()) throw StateError('No UUID available');
      return ids.current;
    },
  );
}

Exercise get _exercise => Exercise(
  ref: ExerciseRef.catalog('ex_bench_press'),
  displayName: 'Bench Press',
  status: ExerciseStatus.active,
);

void main() {
  test('Replace keeps order, never carries old targets, and ignores same selection',
      () {
    var next = 0;
    final draft = RoutineCreateController(
      program: Program(id: ProgramId(_programId), name: 'Program 1'),
      initialName: 'Routine 1',
      repository: _Creates(),
      newUuid: () {
        next++;
        return '90000000-0000-4000-8000-${next.toString().padLeft(12, '0')}';
      },
    );
    addTearDown(draft.dispose);
    final first = draft.addPickedExercise(_exercise)!;
    final originalSet = draft.state.entries.first.sets.single.id;
    final second = draft.addPickedExercise(_exercise)!;
    expect(draft.editSet(first, originalSet,
        SetPrescription(reps: 10, loadKg: 20)), isTrue);
    final replacement = Exercise(
      ref: ExerciseRef.catalog('ex_run_on_treadmill'),
      displayName: 'Run on Treadmill',
      status: ExerciseStatus.active,
      exerciseType: ExerciseType.distanceDuration,
    );
    final newId = draft.replacePickedExercise(first, replacement)!;
    expect(draft.state.entries.map((e) => e.id), [newId, second]);
    expect(newId, isNot(first));
    final newSet = draft.state.entries.first.sets.single;
    expect(newSet.id, isNot(originalSet));
    expect(newSet.prescription.reps, isNull);
    expect(newSet.prescription.loadKg, isNull);
    expect(newSet.prescription.distanceMeters, isNull);
    final allocated = next;
    expect(draft.replacePickedExercise(newId, replacement), isNull);
    expect(draft.replacePickedExercise('missing', replacement), isNull);
    expect(next, allocated);
  });

  test('at most 8 Sets per Exercise; a ninth does not allocate or mutate',
      () {
    var next = 0;
    final draft = RoutineCreateController(
      program: Program(id: ProgramId(_programId), name: 'Program 1'),
      initialName: 'Routine 1',
      repository: _Creates(),
      newUuid: () {
        next++;
        return '00000000-0000-4000-8000-${next.toString().padLeft(12, '0')}';
      },
    );
    addTearDown(draft.dispose);
    final first = draft.addPickedExercise(_exercise)!;
    for (var index = 1; index < 8; index++) {
      expect(draft.addSet(first, SetPrescription()), isNotNull);
    }
    expect(draft.state.entries.single.sets, hasLength(8));
    final allocated = next;
    expect(draft.addSet(first, SetPrescription()), isNull);
    expect(next, allocated);
    expect(draft.state.entries.single.sets, hasLength(8));
    final separate = draft.addPickedExercise(_exercise)!;
    expect(draft.state.entries.last.sets, hasLength(1));
    expect(draft.addSet(separate, SetPrescription()), isNotNull);
    expect(draft.state.entries.last.sets, hasLength(2));
  });

  test('STEPS/TIME Custom cannot enter Create draft or replace a Set', () {
    final draft = _controller(_Creates(), saveAfterOneExercise: true);
    addTearDown(draft.dispose);
    final steps = Exercise(
      ref: ExerciseRef.userCreated('10000000-0000-4000-8000-000000000123'),
      displayName: 'Step Mill',
      status: ExerciseStatus.active,
      exerciseType: ExerciseType.stepsDuration,
    );
    expect(draft.addPickedExercise(steps), isNull);
    expect(draft.state.entries, isEmpty);
    expect(draft.state.canSave, isFalse);
    final entry = draft.addPickedExercise(_exercise)!;
    expect(entry, _entry1, reason: 'Unsupported pick must allocate no UUIDs');
    expect(draft.replacePickedExercise(entry, steps), isNull);
    expect(draft.state.entries.single.id, _entry1);
    expect(draft.state.entries.single.exercise, _exercise.ref);
  });

  test('empty and name-only cannot save, no persistence', () async {
    final repo = _Creates();
    final c = _controller(repo);
    addTearDown(c.dispose);
    expect(c.state.canSave, isFalse);
    c.rename('Routine 2');
    expect(c.state.canSave, isFalse);
    expect(await c.save(), isFalse);
    expect(repo.calls, 0);
  });

  test('adding an Exercise auto-creates distinct Set 1 with valid prescription', () {
    final c = _controller(_Creates());
    addTearDown(c.dispose);
    expect(c.addPickedExercise(_exercise), _entry1);
    expect(c.state.canSave, isTrue);
    final entry = c.state.entries.single;
    expect(entry.id, _entry1);
    expect(entry.sets, hasLength(1));
    expect(entry.sets.single.id, _set1);
    expect(entry.sets.single.prescription.reps, isNull);
    expect(entry.sets.single.prescription.loadKg, isNull);
    expect(entry.sets.single.prescription.restSeconds, isNull);
    expect(c.removeExercise(_entry1), isTrue);
    expect(c.state.canSave, isFalse);
  });

  test('blank targets remain valid across Create Save as an identified Set',
      () async {
    final repo = _Creates();
    final c = _controller(repo, saveAfterOneExercise: true);
    addTearDown(c.dispose);
    c.addPickedExercise(_exercise);
    expect(c.state.canSave, isTrue);
    final set = c.state.entries.single.sets.single;
    expect(set.prescription.reps, isNull);
    expect(set.prescription.loadKg, isNull);
    expect(await c.save(), isTrue);
    final saved = repo.command!.entries.single.sets.single;
    expect(saved.id, _set1);
    expect(saved.prescription.reps, isNull);
    expect(saved.prescription.loadKg, isNull);
  });

  test('two copies of same canonical Exercise have independent Set identities', () {
    final c = _controller(_Creates());
    addTearDown(c.dispose);
    c.addPickedExercise(_exercise);
    c.addPickedExercise(_exercise);
    expect(c.state.entries.map((e) => e.id), [_entry1, _entry2]);
    expect(c.state.entries.map((e) => e.sets.single.id), [_set1, _set2]);
    expect(c.moveExercise(0, 1), isTrue);
    expect(c.state.entries.map((e) => e.id), [_entry2, _entry1]);
  });

  test('Set Type and Rep Range preserve UUID/load/rest and mode', () {
    final c = _controller(_Creates());
    addTearDown(c.dispose);
    c.addPickedExercise(_exercise);
    final before = c.state.entries.single.sets.single;
    expect(c.editSet(_entry1, _set1, SetPrescription(reps: 8)), isTrue);
    expect(c.changeSetType(_entry1, _set1, RoutineSetType.warmUp), isTrue);
    expect(c.changeRepetitionMode(_entry1, range: true), isTrue);
    final warm = c.state.entries.single.sets.single;
    expect(warm.id, before.id);
    expect(warm.prescription.setType, RoutineSetType.warmUp);
    expect(warm.prescription.reps, 8);
    expect(warm.prescription.repsMax, 8);

    final second = c.addSet(_entry1, SetPrescription(reps: 1));
    expect(second, _entry2);
    final added = c.state.entries.single.sets.last;
    expect(added.prescription.setType, RoutineSetType.normal);
    expect(added.prescription.repsMax, 1);

    expect(c.changeRepetitionMode(_entry1, range: false), isTrue);
    expect(c.state.entries.single.sets.every(
      (s) => s.prescription.repsMax == null), isTrue);
    expect(c.state.entries.single.sets.first.prescription.setType,
      RoutineSetType.warmUp);
    expect(c.state.entries.single.sets.map((s) => s.id), [_set1, _entry2]);
  });

  test('removing the final Set removes its Exercise and cannot Save',
      () async {
    final repo = _Creates();
    final c = _controller(repo);
    addTearDown(c.dispose);
    expect(c.addPickedExercise(_exercise), _entry1);
    expect(c.state.canSave, isTrue);
    expect(c.removeSet(_entry1, _set1), isTrue);
    expect(c.state.entries, isEmpty);
    expect(c.state.canSave, isFalse);
    expect(c.removeSet(_entry1, _set1), isFalse);
    expect(await c.save(), isFalse);
    expect(repo.calls, 0);
  });

  test('cancel/dispose never calls repository, confirmed Save once', () async {
    final noWrite = _Creates();
    final abandoned = _controller(noWrite);
    abandoned.addPickedExercise(_exercise);
    abandoned.dispose();
    expect(noWrite.calls, 0);

    final repo = _Creates();
    final c = _controller(repo, saveAfterOneExercise: true);
    addTearDown(c.dispose);
    c.addPickedExercise(_exercise);
    expect(await c.save(), isTrue);
    expect(repo.calls, 1);
    expect(repo.command!.routine.id.value, _routineId);
    expect(repo.command!.routine.programId, ProgramId(_programId));
    expect(repo.command!.mutationId, _mutation);
    expect(repo.command!.entries.single.sets.single.prescription.reps, isNull);
    expect(await c.save(), isFalse);
    expect(repo.calls, 1);
  });

  test('definite Create rejection retains editable draft for explicit retry',
      () async {
    final repo = _Creates()
      ..error = const RoutineCompositionException(
        RoutineCompositionFailureKind.invalidRequest,
      );
    final c = _controller(
      repo,
      saveAfterOneExercise: true,
      retryAfterDefiniteFailure: true,
    );
    addTearDown(c.dispose);
    c.addPickedExercise(_exercise);

    expect(await c.save(), isFalse);
    expect(c.state.status, RoutineCreateStatus.ready);
    expect(c.state.canSave, isTrue);
    expect(c.state.entries.single.sets.single.id, _set1);
    expect(c.state.message, contains('try again'));
    expect(repo.calls, 1);
    final firstRoutineId = repo.command!.routine.id.value;

    // A definite SQL rejection did not commit, unlike transport uncertainty.
    repo.error = null;
    c.rename('Revised Routine');
    expect(await c.save(), isTrue);
    expect(repo.calls, 2);
    expect(repo.command!.routine.id.value, isNot(firstRoutineId));
    expect(repo.command!.routine.name, 'Revised Routine');
    expect(repo.command!.entries.single.sets.single.id, _set1);
    expect(c.state.status, RoutineCreateStatus.saved);
  });

  test('Create preflight blocks a Custom switched remotely to STEPS/TIME',
      () async {
    final repo = _Creates();
    final ids = [_entry1, _set1, _routineId, _mutation].iterator;
    final draft = RoutineCreateController(
      program: Program(id: ProgramId(_programId), name: 'Program 1'),
      initialName: 'Routine 1',
      repository: repo,
      userExercises: _StepExerciseRepository(),
      newUuid: () {
        if (!ids.moveNext()) throw StateError('Unexpected UUID');
        return ids.current;
      },
    );
    addTearDown(draft.dispose);
    final custom = Exercise(
      ref: ExerciseRef.userCreated('90000000-0000-4000-8000-000000000001'),
      displayName: 'Custom', status: ExerciseStatus.active,
      exerciseType: ExerciseType.weightReps,
    );
    expect(draft.addPickedExercise(custom), _entry1);
    expect(await draft.save(), isFalse);
    expect(draft.state.status, RoutineCreateStatus.ready);
    expect(draft.state.message, contains('Steps & Duration'));
    expect(repo.calls, 0);
  });

  test('unknown Create reconcile accepts a renamed committed Routine', () async {
    final repo = _Creates()..error = StateError('lost ACK');
    final draft = _controller(repo, saveAfterOneExercise: true);
    addTearDown(draft.dispose);
    draft.addPickedExercise(_exercise);
    expect(await draft.save(), isFalse);
    final command = repo.command!;
    expect(await draft.reconcileUnknown(
      routines: _RenamedRoutineRepository(Routine(
        id: command.routine.id, programId: command.routine.programId,
        name: 'Renamed on another device',
      )),
      compositions: _CommittedCompositionRepository(
        RoutineCompositionSnapshot(
          routineId: command.routine.id, revision: 1,
          lastMutationId: command.mutationId, entries: command.entries,
        ),
      ),
    ), isTrue);
    expect(draft.state.status, RoutineCreateStatus.saved);
    expect(repo.calls, 1);
  });

  test('unknown Create confirms later revised Routine without retrying RPC',
      () async {
    final repo = _Creates()..error = StateError('lost ACK');
    final draft = _controller(repo, saveAfterOneExercise: true);
    addTearDown(draft.dispose);
    draft.addPickedExercise(_exercise);
    expect(await draft.save(), isFalse);
    final command = repo.command!;
    final changedEntry = RoutineCompositionEntry(
      id: command.entries.single.id,
      exercise: command.entries.single.exercise,
      sets: [RoutineCompositionSet(
        id: command.entries.single.sets.single.id,
        prescription: SetPrescription(reps: 16),
      )],
    );
    expect(await draft.reconcileUnknown(
      routines: _RenamedRoutineRepository(command.routine),
      compositions: _CommittedCompositionRepository(
        RoutineCompositionSnapshot(
          routineId: command.routine.id, revision: 2,
          lastMutationId: '90000000-0000-4000-8000-000000000001',
          entries: [changedEntry],
        ),
      ),
    ), isTrue);
    expect(draft.state.status, RoutineCreateStatus.saved);
    expect(repo.calls, 1);
  });

  test('unknown Create outcome freezes exact command and blocks second write',
      () async {
    final repo = _Creates()..error = StateError('transport lost');
    final c = _controller(repo, saveAfterOneExercise: true);
    addTearDown(c.dispose);
    c.addPickedExercise(_exercise);
    expect(await c.save(), isFalse);
    expect(c.state.status, RoutineCreateStatus.outcomeUnknown);
    expect(c.state.canSave, isFalse);
    expect(await c.save(), isFalse);
    expect(repo.calls, 1);
    expect(repo.command!.routine.id.value, _routineId);
  });

  test('initial blank name stays blocked until renamed', () {
    final c = _controller(_Creates(), name: '   ');
    addTearDown(c.dispose);
    c.addPickedExercise(_exercise);
    expect(c.state.canSave, isFalse);
    c.rename('Day A');
    expect(c.state.canSave, isTrue);
  });
}

final class _Creates implements RoutineCreateRepository {
  int calls = 0;
  Object? error;
  RoutineCreateCommand? command;

  @override
  Future<int> create(RoutineCreateCommand request) async {
    calls++;
    command = request;
    if (error != null) throw error!;
    return 1;
  }
}

final class _StepExerciseRepository extends Fake
    implements UserExerciseRepository {
  @override
  Future<List<Exercise>> list({bool includeArchived = false}) async => [
    Exercise(
      ref: ExerciseRef.userCreated('90000000-0000-4000-8000-000000000001'),
      displayName: 'Step Mill', status: ExerciseStatus.active,
      exerciseType: ExerciseType.stepsDuration,
    ),
  ];
}

final class _RenamedRoutineRepository extends Fake
    implements RoutineRepository {
  _RenamedRoutineRepository(this.row);
  final Routine row;
  @override
  Future<List<Routine>> list(ProgramId id) async => [row];
}

final class _CommittedCompositionRepository extends Fake
    implements RoutineCompositionRepository {
  _CommittedCompositionRepository(this.snapshot);
  final RoutineCompositionSnapshot snapshot;
  @override
  Future<RoutineCompositionSnapshot?> read(RoutineId id) async => snapshot;
}
