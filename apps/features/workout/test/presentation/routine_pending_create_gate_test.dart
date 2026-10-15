import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const owner = 'test-user';
const cycle = 'cycle-1';
final programId = ProgramId('10000000-0000-4000-8000-000000000001');
final routineId = RoutineId('20000000-0000-4000-8000-000000000001');
final command = RoutineCreateCommand(
  routine: Routine(id: routineId, programId: programId, name: 'Routine 1'),
  mutationId: '30000000-0000-4000-8000-000000000001',
  entries: [
    RoutineCompositionEntry(
      id: '40000000-0000-4000-8000-000000000001',
      exercise: ExerciseRef.catalog('ex_bench_press'),
      sets: [
        RoutineCompositionSet(
          id: '50000000-0000-4000-8000-000000000001',
          prescription: SetPrescription(),
        ),
      ],
    ),
  ],
);

void main() {
  test('negative early read stays locked; exact late commit unlocks', () async {
    final gate = RoutinePendingCreateGate()
      ..bindSession(owner: owner, loginCycle: cycle);
    gate.retain(owner: owner, loginCycle: cycle, command: command);
    final routines = _Routines();
    final compositions = _Compositions();
    Future<bool> verify() => gate.verify(
      owner: owner, loginCycle: cycle, programId: programId,
      routines: routines, compositions: compositions, canWrite: () => true,
    );
    expect(await verify(), isFalse);
    expect(gate.hasPending(owner: owner, loginCycle: cycle,
      programId: programId), isTrue);
    routines.rows.add(command.routine);
    expect(await verify(), isFalse); // Metadata alone is not a commit proof.
    compositions.snapshot = RoutineCompositionSnapshot(
      routineId: routineId, revision: 1,
      lastMutationId: command.mutationId, entries: command.entries,
    );
    expect(await verify(), isTrue);
    expect(gate.hasPending(owner: owner, loginCycle: cycle,
      programId: programId), isFalse);
  });

  test('remote rename does not invalidate confirmed immutable Create', () async {
    final gate = RoutinePendingCreateGate()
      ..bindSession(owner: owner, loginCycle: cycle);
    gate.retain(owner: owner, loginCycle: cycle, command: command);
    final routines = _Routines()
      ..rows.add(Routine(
        id: routineId, programId: programId, name: 'Renamed on another device',
      ));
    final compositions = _Compositions()
      ..snapshot = RoutineCompositionSnapshot(
        routineId: routineId, revision: 1,
        lastMutationId: command.mutationId, entries: command.entries,
      );
    expect(await gate.verify(
      owner: owner, loginCycle: cycle, programId: programId,
      routines: routines, compositions: compositions,
      canWrite: () => true,
    ), isTrue);
    expect(gate.hasPending(owner: owner, loginCycle: cycle,
      programId: programId), isFalse);
  });

  test('different committed mutation never clears gate despite name match',
      () async {
    final gate = RoutinePendingCreateGate()
      ..bindSession(owner: owner, loginCycle: cycle);
    gate.retain(owner: owner, loginCycle: cycle, command: command);
    final routines = _Routines()..rows.add(command.routine);
    final compositions = _Compositions()
      ..snapshot = RoutineCompositionSnapshot(
        routineId: routineId, revision: 1,
        lastMutationId: '90000000-0000-4000-8000-000000000001',
        entries: command.entries,
      );
    expect(await gate.verify(
      owner: owner, loginCycle: cycle, programId: programId,
      routines: routines, compositions: compositions,
      canWrite: () => true,
    ), isFalse);
    expect(gate.hasPending(owner: owner, loginCycle: cycle,
      programId: programId), isTrue);
  });

  test('revocation and next login cycle cannot access old mutation', () async {
    final gate = RoutinePendingCreateGate()
      ..bindSession(owner: owner, loginCycle: cycle);
    gate.retain(owner: owner, loginCycle: cycle, command: command);
    expect(await gate.verify(
      owner: 'other-user', loginCycle: cycle, programId: programId,
      routines: _Routines(), compositions: _Compositions(),
      canWrite: () => true), isFalse);
    gate.bindSession(owner: owner, loginCycle: 'cycle-2');
    expect(gate.hasPending(owner: owner, loginCycle: cycle,
      programId: programId), isFalse);
  });
}

class _Routines implements RoutineRepository {
  final List<Routine> rows = [];
  @override Future<List<Routine>> list(ProgramId id) async =>
      rows.where((r) => r.programId == id).toList();
  @override Future<void> create(Routine routine) async => throw UnimplementedError();
  @override Future<void> rename({required RoutineId id, required String name})
      async => throw UnimplementedError();
}

class _Compositions implements RoutineCompositionRepository {
  RoutineCompositionSnapshot? snapshot;
  @override Future<RoutineCompositionSnapshot?> read(RoutineId id) async =>
      snapshot;
  @override Future<int> save(RoutineCompositionSave command) async =>
      throw UnimplementedError();
}
