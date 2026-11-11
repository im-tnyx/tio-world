import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const owner = 'owner-a';
const cycle = 'login-a1';
final defaultId = ProgramId('10000000-0000-4000-8000-000000000001');
final routineId = RoutineId('20000000-0000-4000-8000-000000000001');

MyProgramRoutineCreateCommand createCommand() => MyProgramRoutineCreateCommand(
      routineId: routineId,
      name: 'First Routine',
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

Program renamedDefault() =>
    Program(id: defaultId, name: 'My Renamed Workouts', isDefault: true);

Routine persistedRoutine({String name = 'First Routine'}) =>
    Routine(id: routineId, programId: defaultId, name: name);

RoutineCompositionSnapshot savedSnapshot(
  MyProgramRoutineCreateCommand command, {
  String? name = 'First Routine',
  int revision = 1,
  String? mutation,
}) =>
    RoutineCompositionSnapshot(
      routineId: routineId,
      name: name,
      revision: revision,
      lastMutationId: mutation ?? command.mutationId,
      entries: command.entries,
    );

void main() {
  test('first Create is reserved without an invented ProgramId', () {
    final gate = RoutinePendingCreateGate()
      ..bindSession(owner: owner, loginCycle: cycle);
    final command = createCommand();
    gate.retainMyProgram(
      owner: owner, loginCycle: cycle, command: command,
    );
    expect(gate.hasPendingMyProgram(owner: owner, loginCycle: cycle), isTrue);
    expect(gate.hasPendingMyProgramForOwner(owner: owner), isTrue);
    expect(gate.hasPendingMyProgramForOwner(owner: 'owner-b'), isFalse);
    expect(
      () => gate.retainMyProgram(
        owner: owner, loginCycle: cycle, command: createCommand(),
      ),
      throwsStateError,
      reason: 'A second pending first-Create cannot mint another default',
    );
    gate.releaseMyProgram(
      owner: owner, loginCycle: cycle, command: createCommand(),
    );
    expect(gate.hasPendingMyProgram(owner: owner, loginCycle: cycle), isTrue);
    gate.releaseMyProgram(owner: owner, loginCycle: cycle, command: command);
    expect(gate.hasPendingMyProgram(owner: owner, loginCycle: cycle), isFalse);
  });

  test('empty and display-name-only readbacks stay UNKNOWN', () async {
    final gate = RoutinePendingCreateGate()
      ..bindSession(owner: owner, loginCycle: cycle);
    final command = createCommand();
    gate.retainMyProgram(owner: owner, loginCycle: cycle, command: command);
    final programs = _Programs();
    final routines = _Routines();
    final compositions = _Compositions();
    Future<bool> verify() => gate.verifyMyProgram(
          owner: owner,
          loginCycle: cycle,
          programs: programs,
          routines: routines,
          compositions: compositions,
          canWrite: () => true,
        );

    expect(await verify(), isFalse);
    programs.rows.add(Program(id: defaultId, name: 'My Program'));
    routines.rows.add(persistedRoutine());
    compositions.snapshot = savedSnapshot(command);
    expect(await verify(), isFalse,
        reason: 'A display name is not server-owned is_default evidence');
    expect(gate.hasPendingMyProgram(owner: owner, loginCycle: cycle), isTrue);

    programs.rows
      ..clear()
      ..add(renamedDefault());
    expect(await verify(), isTrue,
        reason: 'A renamed canonical default is valid positive evidence');
    expect(gate.hasPendingMyProgram(owner: owner, loginCycle: cycle), isFalse);
  });

  test('matching metadata alone does not unlock missing composition', () async {
    final gate = RoutinePendingCreateGate()
      ..bindSession(owner: owner, loginCycle: cycle);
    final command = createCommand();
    gate.retainMyProgram(owner: owner, loginCycle: cycle, command: command);
    final programs = _Programs()..rows.add(renamedDefault());
    final routines = _Routines()..rows.add(persistedRoutine());
    final compositions = _Compositions();

    Future<bool> verify() => gate.verifyMyProgram(
          owner: owner, loginCycle: cycle,
          programs: programs, routines: routines,
          compositions: compositions, canWrite: () => true,
        );

    expect(await verify(), isFalse);
    compositions.snapshot = savedSnapshot(command, name: null);
    expect(await verify(), isFalse);
    compositions.snapshot = savedSnapshot(command, name: 'Conflicting name');
    expect(await verify(), isFalse);
    compositions.snapshot = savedSnapshot(command,
        mutation: '90000000-0000-4000-8000-000000000001');
    expect(await verify(), isFalse);
    compositions.snapshot = savedSnapshot(command, revision: 2);
    expect(await verify(), isFalse);
    expect(gate.hasPendingMyProgram(owner: owner, loginCycle: cycle), isTrue);
    compositions.snapshot = savedSnapshot(command);
    expect(await verify(), isTrue);
  });

  test('wrong Routine name or duplicate canonical default stays pending',
      () async {
    final gate = RoutinePendingCreateGate()
      ..bindSession(owner: owner, loginCycle: cycle);
    final command = createCommand();
    gate.retainMyProgram(owner: owner, loginCycle: cycle, command: command);
    final programs = _Programs()..rows.add(renamedDefault());
    final routines = _Routines()..rows.add(persistedRoutine(name: 'Other'));
    final compositions = _Compositions()..snapshot = savedSnapshot(command);
    Future<bool> verify() => gate.verifyMyProgram(
          owner: owner, loginCycle: cycle,
          programs: programs, routines: routines,
          compositions: compositions, canWrite: () => true,
        );

    expect(await verify(), isFalse);
    routines.rows
      ..clear()
      ..add(persistedRoutine());
    programs.rows.add(Program(
      id: ProgramId('10000000-0000-4000-8000-000000000002'),
      name: 'Another Default',
      isDefault: true,
    ));
    expect(await verify(), isFalse);
    programs.rows.removeLast();
    expect(await verify(), isTrue);
  });

  test('A to B to A keeps pending identity private and exact', () async {
    final gate = RoutinePendingCreateGate()
      ..bindSession(owner: owner, loginCycle: cycle);
    final command = createCommand();
    gate.retainMyProgram(owner: owner, loginCycle: cycle, command: command);
    gate.bindSession(owner: 'owner-b', loginCycle: 'login-b1');
    expect(gate.hasPendingMyProgram(owner: owner, loginCycle: cycle), isFalse);
    expect(gate.hasPendingMyProgram(
        owner: 'owner-b', loginCycle: 'login-b1'), isFalse);
    expect(gate.hasPendingMyProgramForOwner(owner: owner), isTrue);
    expect(await gate.verifyMyProgram(
      owner: owner, loginCycle: cycle,
      programs: _Programs(), routines: _Routines(),
      compositions: _Compositions(), canWrite: () => true,
    ), isFalse);
    gate.bindSession(owner: owner, loginCycle: 'login-a2');
    gate.releaseMyProgram(owner: owner, loginCycle: cycle, command: command);
    expect(gate.hasPendingMyProgram(
        owner: owner, loginCycle: 'login-a2'), isTrue);

    final programs = _Programs()..rows.add(renamedDefault());
    final routines = _Routines()..rows.add(persistedRoutine());
    final compositions = _Compositions()..snapshot = savedSnapshot(command);
    expect(await gate.verifyMyProgram(
      owner: owner, loginCycle: 'login-a2',
      programs: programs, routines: routines,
      compositions: compositions, canWrite: () => true,
    ), isTrue);
  });

  test('auth switch during first read never clears UNKNOWN', () async {
    final gate = RoutinePendingCreateGate()
      ..bindSession(owner: owner, loginCycle: cycle);
    final command = createCommand();
    gate.retainMyProgram(owner: owner, loginCycle: cycle, command: command);
    final read = Completer<List<Program>>();
    final programs = _Programs()..load = () => read.future;
    final result = gate.verifyMyProgram(
      owner: owner, loginCycle: cycle,
      programs: programs, routines: _Routines()..rows.add(persistedRoutine()),
      compositions: _Compositions()..snapshot = savedSnapshot(command),
      canWrite: () => true,
    );
    gate.bindSession(owner: 'owner-b', loginCycle: 'login-b1');
    read.complete([renamedDefault()]);
    expect(await result, isFalse);
    expect(gate.hasPendingMyProgramForOwner(owner: owner), isTrue);
    gate.bindSession(owner: owner, loginCycle: 'login-a2');
    expect(gate.hasPendingMyProgram(
      owner: owner, loginCycle: 'login-a2',
    ), isTrue);
  });

  test('definite rejection clears only exact owner command across cycles', () {
    final gate = RoutinePendingCreateGate()
      ..bindSession(owner: owner, loginCycle: cycle);
    final first = createCommand();
    gate.retainMyProgram(owner: owner, loginCycle: cycle, command: first);
    gate.bindSession(owner: 'owner-b', loginCycle: 'login-b1');
    final other = createCommand();
    gate.retainMyProgram(
      owner: 'owner-b', loginCycle: 'login-b1', command: other,
    );
    gate.releaseDefiniteMyProgramForOwner(
      owner: owner, command: createCommand(),
    );
    expect(gate.hasPendingMyProgramForOwner(owner: owner), isTrue);
    gate.releaseDefiniteMyProgramForOwner(owner: owner, command: first);
    expect(gate.hasPendingMyProgramForOwner(owner: owner), isFalse);
    expect(gate.hasPendingMyProgramForOwner(owner: 'owner-b'), isTrue);
  });
}

class _Programs implements ProgramRepository {
  final List<Program> rows = [];
  Future<List<Program>> Function()? load;

  @override
  Future<List<Program>> list() =>
      load?.call() ?? Future<List<Program>>.value(rows);

  @override
  Future<void> create(Program program) async => throw UnimplementedError();

  @override
  Future<void> rename({required ProgramId id, required String name}) async =>
      throw UnimplementedError();
}

class _Routines implements RoutineRepository {
  final List<Routine> rows = [];

  @override
  Future<List<Routine>> list(ProgramId id) async =>
      rows.where((r) => r.programId == id).toList();

  @override
  Future<void> create(Routine routine) async => throw UnimplementedError();

  @override
  Future<void> rename({required RoutineId id, required String name}) async =>
      throw UnimplementedError();
}

class _Compositions implements RoutineCompositionRepository {
  RoutineCompositionSnapshot? snapshot;

  @override
  Future<RoutineCompositionSnapshot?> read(RoutineId id) async => snapshot;

  @override
  Future<int> save(RoutineCompositionSave command) async =>
      throw UnimplementedError();
}
