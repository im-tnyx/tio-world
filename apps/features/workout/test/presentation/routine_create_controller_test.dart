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

RoutineCreateController _controller(_Creates repo, {String name = 'Routine 1'}) {
  final ids = [_entry1, _set1, _entry2, _set2, _routineId, _mutation].iterator;
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
    expect(entry.sets.single.prescription.reps, 1);
    expect(entry.sets.single.prescription.loadKg, isNull);
    expect(entry.sets.single.prescription.restSeconds, isNull);
    expect(c.removeExercise(_entry1), isTrue);
    expect(c.state.canSave, isFalse);
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
    expect(c.changeSetType(_entry1, _set1, RoutineSetType.warmUp), isTrue);
    expect(c.changeRepetitionMode(_entry1, range: true), isTrue);
    final warm = c.state.entries.single.sets.single;
    expect(warm.id, before.id);
    expect(warm.prescription.setType, RoutineSetType.warmUp);
    expect(warm.prescription.reps, 1);
    expect(warm.prescription.repsMax, 1);

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
    final c = _controller(repo);
    addTearDown(c.dispose);
    c.addPickedExercise(_exercise);
    expect(await c.save(), isTrue);
    expect(repo.calls, 1);
    expect(repo.command!.routine.id.value, _routineId);
    expect(repo.command!.routine.programId, ProgramId(_programId));
    expect(repo.command!.mutationId, _mutation);
    expect(repo.command!.entries.single.sets.single.prescription.reps, 1);
    expect(await c.save(), isFalse);
    expect(repo.calls, 1);
  });

  test('unknown Create outcome freezes exact command and blocks second write',
      () async {
    final repo = _Creates()..error = StateError('transport lost');
    final c = _controller(repo);
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
