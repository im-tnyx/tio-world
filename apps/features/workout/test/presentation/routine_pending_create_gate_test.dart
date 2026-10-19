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
  test('owner Program pending bit persists across cycles and has no draft',
      () {
    final gate = RoutinePendingCreateGate()
      ..bindSession(owner: owner, loginCycle: cycle);
    gate.retain(owner: owner, loginCycle: cycle, command: command);
    expect(gate.hasPendingForOwnerProgram(
        owner: owner, programId: programId), isTrue);
    expect(gate.hasPendingForOwnerProgram(
        owner: 'other-user', programId: programId), isFalse);
    gate.bindSession(owner: 'other-user', loginCycle: 'cycle-b');
    expect(gate.hasPendingForOwnerProgram(
        owner: owner, programId: programId), isTrue,
        reason: 'A late Create RPC may still commit after account switch');
    gate.bindSession(owner: owner, loginCycle: 'cycle-2');
    gate.release(owner: owner, loginCycle: cycle, command: command);
    expect(gate.hasPendingForOwnerProgram(
        owner: owner, programId: programId), isTrue);
    gate.releaseDefiniteForOwner(owner: owner, command: command);
    expect(gate.hasPendingForOwnerProgram(
        owner: owner, programId: programId), isFalse);
  });

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

  test('later composition edit can confirm original Routine identity',
      () async {
    final gate = RoutinePendingCreateGate()
      ..bindSession(owner: owner, loginCycle: cycle);
    gate.retain(owner: owner, loginCycle: cycle, command: command);
    final routines = _Routines()..rows.add(command.routine);
    final changedEntry = RoutineCompositionEntry(
      id: command.entries.single.id,
      exercise: command.entries.single.exercise,
      sets: [RoutineCompositionSet(
        id: command.entries.single.sets.single.id,
        prescription: SetPrescription(reps: 12),
      )],
    );
    final compositions = _Compositions()
      ..snapshot = RoutineCompositionSnapshot(
        routineId: routineId, revision: 2,
        lastMutationId: '90000000-0000-4000-8000-000000000001',
        entries: [changedEntry],
      );
    expect(await gate.verify(
      owner: owner, loginCycle: cycle, programId: programId,
      routines: routines, compositions: compositions,
      canWrite: () => true,
    ), isTrue);
    expect(gate.hasPending(owner: owner, loginCycle: cycle,
      programId: programId), isFalse);
    expect(compositions.snapshot!.entries.single.sets.single.prescription.reps,
      12, reason: 'Checking status must not restore stale Create content');
  });

  test('revision greater than 1 without persisted mutation stays pending',
      () async {
    final gate = RoutinePendingCreateGate()
      ..bindSession(owner: owner, loginCycle: cycle);
    gate.retain(owner: owner, loginCycle: cycle, command: command);
    final routines = _Routines()..rows.add(command.routine);
    final compositions = _Compositions()
      ..snapshot = RoutineCompositionSnapshot(
        routineId: routineId, revision: 2,
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

  test('in-flight Create survives same-owner reauthentication, then verifies',
      () async {
    final gate = RoutinePendingCreateGate()
      ..bindSession(owner: owner, loginCycle: cycle);
    gate.retain(owner: owner, loginCycle: cycle, command: command);
    gate.bindSession(owner: owner, loginCycle: 'cycle-2');
    expect(gate.hasPending(owner: owner, loginCycle: cycle,
      programId: programId), isFalse);
    expect(gate.hasPending(owner: owner, loginCycle: 'cycle-2',
      programId: programId), isTrue);

    // A stale route must not clear a new session's in-flight reservation.
    gate.release(owner: owner, loginCycle: cycle, command: command);
    expect(gate.hasPending(owner: owner, loginCycle: 'cycle-2',
      programId: programId), isTrue);

    final routines = _Routines();
    final compositions = _Compositions();
    Future<bool> check() => gate.verify(
      owner: owner, loginCycle: 'cycle-2', programId: programId,
      routines: routines, compositions: compositions,
      canWrite: () => true,
    );
    expect(await check(), isFalse);
    expect(gate.hasPending(owner: owner, loginCycle: 'cycle-2',
      programId: programId), isTrue);
    routines.rows.add(command.routine);
    compositions.snapshot = RoutineCompositionSnapshot(
      routineId: routineId, revision: 1,
      lastMutationId: command.mutationId, entries: command.entries,
    );
    expect(await check(), isTrue);
    expect(gate.hasPending(owner: owner, loginCycle: 'cycle-2',
      programId: programId), isFalse);
  });

  test('definite rejection frees exact in-flight Create across same owner cycles',
      () {
    final gate = RoutinePendingCreateGate()
      ..bindSession(owner: owner, loginCycle: cycle);
    gate.retain(owner: owner, loginCycle: cycle, command: command);
    gate.bindSession(owner: owner, loginCycle: 'cycle-2');

    final distinctInstance = RoutineCreateCommand(
      routine: command.routine, mutationId: command.mutationId,
      entries: command.entries,
    );
    gate.releaseDefiniteForOwner(owner: owner, command: distinctInstance);
    expect(gate.hasPending(owner: owner, loginCycle: 'cycle-2',
      programId: programId), isTrue,
      reason: 'A different command instance must never free a reservation');

    gate.releaseDefiniteForOwner(owner: owner, command: command);
    expect(gate.hasPending(owner: owner, loginCycle: 'cycle-2',
      programId: programId), isFalse);
  });

  test('A -> B -> A retains owner A attempt without exposing it to B',
      () async {
    final gate = RoutinePendingCreateGate()
      ..bindSession(owner: owner, loginCycle: cycle);
    gate.retain(owner: owner, loginCycle: cycle, command: command);
    gate.bindSession(owner: 'other-user', loginCycle: 'other-cycle');
    expect(gate.hasPending(owner: owner, loginCycle: cycle,
      programId: programId), isFalse,
      reason: 'A pending identity must not be readable while B is active');
    expect(gate.hasPending(owner: 'other-user', loginCycle: 'other-cycle',
      programId: programId), isFalse,
      reason: 'B cannot inherit A pending identity or draft');
    expect(await gate.verify(
      owner: owner, loginCycle: cycle, programId: programId,
      routines: _Routines(), compositions: _Compositions(),
      canWrite: () => true), isFalse,
      reason: 'A cannot verify through a B session');

    gate.bindSession(owner: owner, loginCycle: 'cycle-2');
    expect(gate.hasPending(owner: owner, loginCycle: 'cycle-2',
      programId: programId), isTrue,
      reason: 'A must be blocked from a second Create after returning');
    final routines = _Routines();
    final compositions = _Compositions();
    expect(await gate.verify(
      owner: owner, loginCycle: 'cycle-2', programId: programId,
      routines: routines, compositions: compositions,
      canWrite: () => true), isFalse,
      reason: 'An empty read never proves the old RPC cannot commit');
    expect(gate.hasPending(owner: owner, loginCycle: 'cycle-2',
      programId: programId), isTrue);
    routines.rows.add(command.routine);
    compositions.snapshot = RoutineCompositionSnapshot(
      routineId: routineId, revision: 1,
      lastMutationId: command.mutationId, entries: command.entries,
    );
    expect(await gate.verify(
      owner: owner, loginCycle: 'cycle-2', programId: programId,
      routines: routines, compositions: compositions,
      canWrite: () => true), isTrue);
    expect(gate.hasPending(owner: owner, loginCycle: 'cycle-2',
      programId: programId), isFalse);
  });

  test('B reservations stay private and an old A definite failure clears A',
      () {
    final gate = RoutinePendingCreateGate()
      ..bindSession(owner: owner, loginCycle: cycle);
    gate.retain(owner: owner, loginCycle: cycle, command: command);
    gate.bindSession(owner: 'other-user', loginCycle: 'other-cycle');
    final bCommand = RoutineCreateCommand(
      routine: Routine(
        id: RoutineId('20000000-0000-4000-8000-000000000002'),
        programId: programId, name: 'Owner B Routine',
      ),
      mutationId: '30000000-0000-4000-8000-000000000002',
      entries: command.entries,
    );
    gate.retain(owner: 'other-user', loginCycle: 'other-cycle',
      command: bCommand);
    gate.releaseDefiniteForOwner(owner: owner, command: command);
    expect(gate.hasPending(owner: 'other-user', loginCycle: 'other-cycle',
      programId: programId), isTrue,
      reason: 'Old A RPC callback cannot release B in-flight Create');
    gate.bindSession(owner: owner, loginCycle: 'cycle-2');
    expect(gate.hasPending(owner: owner, loginCycle: 'cycle-2',
      programId: programId), isFalse,
      reason: 'A definite rollback must not leave A permanently blocked');
    gate.bindSession(owner: 'other-user', loginCycle: 'other-cycle');
    expect(gate.hasPending(owner: 'other-user', loginCycle: 'other-cycle',
      programId: programId), isTrue,
      reason: 'B retained its independent reservation across A login');
  });

  test('definite Create result clears only its own pending reservation',
      () async {
    final gate = RoutinePendingCreateGate()
      ..bindSession(owner: owner, loginCycle: cycle);
    gate.retain(owner: owner, loginCycle: cycle, command: command);
    gate.release(owner: owner, loginCycle: cycle, command: command);
    expect(gate.hasPending(owner: owner, loginCycle: cycle,
      programId: programId), isFalse);
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
