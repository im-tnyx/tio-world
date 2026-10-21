import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _defaultUuid = '11111111-1111-4111-8111-111111111111';
const _entryUuid = '22222222-2222-4222-8222-222222222222';
const _setUuid = '33333333-3333-4333-8333-333333333333';
const _routineUuid = '44444444-4444-4444-8444-444444444444';
const _mutationUuid = '55555555-5555-4555-8555-555555555555';

final _defaultId = ProgramId(_defaultUuid);
final _exercise = Exercise(
  ref: ExerciseRef.catalog('ex_bench_press'),
  displayName: 'Bench Press',
  status: ExerciseStatus.active,
);

RoutineCreateController _draft(
  _MyCreates repo, {
  bool Function()? canWrite,
  ValueChanged<MyProgramRoutineCreateCommand>? onDefiniteFailure,
}) {
  final ids = [_entryUuid, _setUuid, _routineUuid, _mutationUuid].iterator;
  return RoutineCreateController.forMyProgram(
    initialName: 'First Routine',
    myProgramRepository: repo,
    canWrite: canWrite ?? () => true,
    onMyProgramDefiniteFailure: onDefiniteFailure,
    newUuid: () {
      if (!ids.moveNext()) throw StateError('Extra UUID allocation');
      return ids.current;
    },
  );
}

void main() {
  testWidgets('programless mode uses the same Exercise/Set composer and atomic RPC',
      (tester) async {
    final repo = _MyCreates();
    final gate = RoutinePendingCreateGate()
      ..bindSession(owner: 'owner-a', loginCycle: 'cycle-1');
    addTearDown(gate.dispose);
    final ids = [_entryUuid, _setUuid, _routineUuid, _mutationUuid].iterator;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.dark),
        child: child ?? const SizedBox.shrink(),
      ),
      home: CreateRoutinePage.forMyProgram(
        initialName: 'First Routine',
        myProgramRepository: repo,
        programRepository: _Programs(),
        catalogRepository: _Catalog(),
        weightUnit: WeightUnit.kg,
        onMyProgramWriteStarted: (command) => gate.retainMyProgram(
          owner: 'owner-a', loginCycle: 'cycle-1', command: command,
        ),
        onMyProgramWriteResolved: (command) => gate.releaseMyProgram(
          owner: 'owner-a', loginCycle: 'cycle-1', command: command,
        ),
        onMyProgramUnconfirmedExit: (_) {},
        canWrite: () => true,
        onMyProgramDefiniteFailure: (command) =>
            gate.releaseDefiniteMyProgramForOwner(
              owner: 'owner-a', command: command,
            ),
        newUuid: () {
          if (!ids.moveNext()) throw StateError('Extra UUID allocation');
          return ids.current;
        },
      ),
    ));
    expect(find.byKey(const ValueKey('routine-composer-screen')),
        findsOneWidget);
    expect(find.text('Create Routine'), findsOneWidget);
    expect(tester.widget<TextButton>(
        find.byKey(const ValueKey('create-routine-save'))).onPressed, isNull);
    await tester.tap(find.byKey(
        const ValueKey('create-routine-add-exercise')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(
        const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('create-routine-entry-$_entryUuid')),
        findsOneWidget);
    expect(repo.calls, 0);
    await tester.tap(find.byKey(const ValueKey('create-routine-save')));
    await tester.pump();
    expect(repo.calls, 1);
    final command = repo.command!;
    expect(command.routineId, RoutineId(_routineUuid));
    expect(command.mutationId, _mutationUuid);
    expect(command.entries.single.sets.single.id, _setUuid);
    expect(command.name, 'First Routine');
    expect(gate.hasPendingMyProgramForOwner(owner: 'owner-a'), isFalse);
  });

  test('UNKNOWN retains the same programless identity, negative reads cannot retry',
      () async {
    final repo = _MyCreates()..loseAck = true;
    final c = _draft(repo);
    addTearDown(c.dispose);
    c.addPickedExercise(_exercise);
    expect(await c.save(), isFalse);
    final frozen = c.unconfirmedMyProgramAttempt!;
    expect(frozen.routineId, RoutineId(_routineUuid));
    expect(c.state.status, RoutineCreateStatus.outcomeUnknown);
    expect(await c.save(), isFalse);
    expect(repo.calls, 1);

    final programs = _Programs()
      ..rows.add(Program(id: _defaultId, name: 'My Program'));
    final routines = _Routines();
    final compositions = _Compositions();
    Future<bool> verify() => c.reconcileUnknown(
      programs: programs, routines: routines, compositions: compositions,
    );
    expect(await verify(), isFalse);
    // A display name is not proof of server-owned default identity.
    routines.rows.add(Routine(
      id: frozen.routineId, programId: _defaultId, name: frozen.name,
    ));
    compositions.snapshot = RoutineCompositionSnapshot(
      routineId: frozen.routineId,
      name: frozen.name,
      revision: 1,
      lastMutationId: frozen.mutationId,
      entries: frozen.entries,
    );
    expect(await verify(), isFalse);
    expect(c.unconfirmedMyProgramAttempt, same(frozen));
    programs.rows
      ..clear()
      ..add(Program(id: _defaultId, name: 'Renamed', isDefault: true));
    expect(await verify(), isTrue);
    expect(c.state.status, RoutineCreateStatus.saved);
    expect(repo.calls, 1);
  });

  test('definite rejection releases only the frozen command; fresh Save is explicit',
      () async {
    final repo = _MyCreates()..definiteFailure = true;
    final rejected = <MyProgramRoutineCreateCommand>[];
    var index = 0;
    final ids = [_entryUuid, _setUuid, _routineUuid, _mutationUuid,
      '66666666-6666-4666-8666-666666666666',
      '77777777-7777-4777-8777-777777777777'];
    final c = RoutineCreateController.forMyProgram(
      initialName: 'First Routine',
      myProgramRepository: repo,
      onMyProgramDefiniteFailure: rejected.add,
      canWrite: () => true,
      newUuid: () => ids[index++],
    );
    addTearDown(c.dispose);
    c.addPickedExercise(_exercise);
    expect(await c.save(), isFalse);
    expect(c.state.status, RoutineCreateStatus.ready);
    expect(rejected, hasLength(1));
    expect(rejected.single, same(repo.command));
    repo.definiteFailure = false;
    expect(await c.save(), isTrue);
    expect(repo.calls, 2);
    expect(repo.command, isNot(same(rejected.single)));
    expect(c.state.status, RoutineCreateStatus.saved);
  });

  test('revoking the login cycle before RPC ACK never confirms or releases',
      () async {
    final repo = _MyCreates();
    final pending = Completer<MyProgramRoutineCreateReceipt>();
    repo.waitOn = pending.future;
    var authorized = true;
    final c = _draft(repo, canWrite: () => authorized);
    addTearDown(c.dispose);
    c.addPickedExercise(_exercise);
    final future = c.save();
    expect(c.inFlightMyProgramAttempt, isNotNull);
    authorized = false;
    pending.complete(MyProgramRoutineCreateReceipt(
      programId: _defaultId, compositionRevision: 1,
    ));
    expect(await future, isFalse);
    expect(c.state.status, isNot(RoutineCreateStatus.saved));
  });
}

class _Catalog implements ExerciseCatalogRepository {
  @override
  Future<ExerciseCatalog> load() async => ExerciseCatalog([_exercise]);
}

class _MyCreates implements MyProgramRoutineCreateRepository {
  int calls = 0;
  MyProgramRoutineCreateCommand? command;
  bool loseAck = false;
  bool definiteFailure = false;
  Future<MyProgramRoutineCreateReceipt>? waitOn;

  @override
  Future<MyProgramRoutineCreateReceipt> createInMyProgram(
      MyProgramRoutineCreateCommand value) async {
    calls++;
    command = value;
    if (waitOn != null) return waitOn!;
    if (definiteFailure) {
      throw const RoutineCompositionException(
          RoutineCompositionFailureKind.forbidden);
    }
    if (loseAck) throw StateError('ACK lost');
    return MyProgramRoutineCreateReceipt(
        programId: _defaultId, compositionRevision: 1);
  }
}

class _Programs implements ProgramRepository {
  final rows = <Program>[];
  @override
  Future<List<Program>> list() async => List.of(rows);
  @override
  Future<void> create(Program program) async =>
      throw StateError('Client-side default Program INSERT forbidden');
  @override
  Future<void> rename({required ProgramId id, required String name}) async =>
      throw StateError('No Program mutation expected');
}

class _Routines implements RoutineRepository {
  final rows = <Routine>[];
  @override
  Future<List<Routine>> list(ProgramId programId) async =>
      rows.where((row) => row.programId == programId).toList();
  @override
  Future<void> create(Routine routine) async =>
      throw StateError('No metadata-only Routine Create');
  @override
  Future<void> rename({required RoutineId id, required String name}) async =>
      throw StateError('No Routine mutation expected');
}

class _Compositions implements RoutineCompositionRepository {
  RoutineCompositionSnapshot? snapshot;
  @override
  Future<RoutineCompositionSnapshot?> read(RoutineId routineId) async => snapshot;
  @override
  Future<int> save(RoutineCompositionSave command) async =>
      throw StateError('No separate composition Save');
}
