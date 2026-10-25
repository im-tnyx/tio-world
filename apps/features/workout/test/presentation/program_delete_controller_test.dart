import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _owner = '11111111-1111-4111-8111-111111111111';
const _otherOwner = '99999999-9999-4999-8999-999999999999';
const _cycle = 'cycle-a';
const _otherCycle = 'cycle-b';
final _source = ProgramId('22222222-2222-4222-8222-222222222222');
final _destination = ProgramId('33333333-3333-4333-8333-333333333333');
final _routineOne = RoutineId('44444444-4444-4444-8444-444444444444');
final _routineTwo = RoutineId('55555555-5555-4555-8555-555555555555');
const _mutationOne = '66666666-6666-4666-8666-666666666666';
const _mutationTwo = '77777777-7777-4777-8777-777777777777';

Program _program({bool isDefault = false, String name = 'Legs'}) => Program(
      id: _source,
      name: name,
      isDefault: isDefault,
    );

RoutineMetadataRevision _snapshot(RoutineId id) => RoutineMetadataRevision(
      routine: Routine(id: id, programId: _source, name: 'Routine'),
      revision: 4,
      loginCycleId: _cycle,
    );

ProgramDeleteResult _success({int moved = 0}) => ProgramDeleteResult(
      deletedProgramId: _source,
      destinationProgramId: moved == 0 ? null : _destination,
      movedRoutineCount: moved,
    );

ProgramDeleteController _controller({
  required _FakePrograms programs,
  required _FakeVersionedRoutines routines,
  required _FakeDeleteRepository deleteRepository,
  required ProgramDeleteAttemptGate attemptGate,
  RoutinePendingCreateGate? pendingCreateGate,
  RoutineMoveDeleteAttemptGate? routineOperationGate,
  List<ProgramDeleteRefreshRequest>? refreshes,
}) {
  final pending = pendingCreateGate ?? RoutinePendingCreateGate();
  final operations = routineOperationGate ?? RoutineMoveDeleteAttemptGate();
  return ProgramDeleteController(
    programs: programs,
    routines: routines,
    deleteRepository: deleteRepository,
    attemptGate: attemptGate,
    pendingCreateGate: pending,
    routineOperationGate: operations,
    refresh: (request) async => refreshes?.add(request),
  );
}

void main() {
  test('prepares a complete multi-Routine target and refreshes after success',
      () async {
    final programs = _FakePrograms([_program()]);
    final routines = _FakeVersionedRoutines(
        [_snapshot(_routineOne), _snapshot(_routineTwo)]);
    final gate = ProgramDeleteAttemptGate();
    final deleteRepository = _FakeDeleteRepository(
      attemptGate: gate,
      result: _success(moved: 2),
    );
    final refreshes = <ProgramDeleteRefreshRequest>[];
    final controller = _controller(
      programs: programs,
      routines: routines,
      deleteRepository: deleteRepository,
      attemptGate: gate,
      refreshes: refreshes,
    );
    addTearDown(controller.dispose);

    expect(await controller.prepare(_source), isTrue);
    expect(controller.state.status, ProgramDeleteOperationStatus.ready);
    expect(controller.state.target!.expectedRoutineIds,
        [_routineOne, _routineTwo]);

    final state = await controller.confirm(clientMutationId: _mutationOne);
    expect(state.status, ProgramDeleteOperationStatus.confirmed);
    expect(deleteRepository.writes, 1);
    expect(refreshes, hasLength(1));
    expect(refreshes.single.ownerId, _owner);
    expect(refreshes.single.loginCycleId, _cycle);
    expect(refreshes.single.destinationProgramId, _destination);
  });

  test('empty Program prepares and accepts a confirmed empty deletion',
      () async {
    final programs = _FakePrograms([_program()]);
    final routines = _FakeVersionedRoutines(const []);
    final gate = ProgramDeleteAttemptGate();
    final deleteRepository = _FakeDeleteRepository(
      attemptGate: gate,
      result: _success(),
    );
    final refreshes = <ProgramDeleteRefreshRequest>[];
    final controller = _controller(
      programs: programs,
      routines: routines,
      deleteRepository: deleteRepository,
      attemptGate: gate,
      refreshes: refreshes,
    );
    addTearDown(controller.dispose);

    expect(await controller.prepare(_source), isTrue);
    expect(controller.state.target!.expectedRoutineIds, isEmpty);
    expect(
      (await controller.confirm(clientMutationId: _mutationOne)).status,
      ProgramDeleteOperationStatus.confirmed,
    );
    expect(refreshes, hasLength(1));
  });

  test('renamed canonical default remains protected by isDefault', () async {
    final programs =
        _FakePrograms([_program(isDefault: true, name: 'Strength')]);
    final gate = ProgramDeleteAttemptGate();
    final controller = _controller(
      programs: programs,
      routines: _FakeVersionedRoutines(const []),
      deleteRepository: _FakeDeleteRepository(attemptGate: gate),
      attemptGate: gate,
    );
    addTearDown(controller.dispose);

    expect(await controller.prepare(_source), isFalse);
    expect(controller.state.status,
        ProgramDeleteOperationStatus.definitelyRejected);
    expect(controller.state.failure!.kind,
        ProgramDeleteFailureKind.defaultProtected);
  });

  test('wrong owner, logout and account switch are rejected before write',
      () async {
    final programs = _FakePrograms([], onList: () async => const []);
    final gate = ProgramDeleteAttemptGate();
    final wrongOwner = _controller(
      programs: programs,
      routines: _FakeVersionedRoutines(const [], owner: _otherOwner),
      deleteRepository: _FakeDeleteRepository(attemptGate: gate),
      attemptGate: gate,
    );
    addTearDown(wrongOwner.dispose);
    expect(await wrongOwner.prepare(_source), isFalse);
    expect(wrongOwner.state.failure!.kind, ProgramDeleteFailureKind.notFound);

    final logoutRoutines = _FakeVersionedRoutines(const [], owner: null);
    final logout = _controller(
      programs: _FakePrograms([_program()]),
      routines: logoutRoutines,
      deleteRepository: _FakeDeleteRepository(attemptGate: gate),
      attemptGate: gate,
    );
    addTearDown(logout.dispose);
    expect(await logout.prepare(_source), isFalse);
    expect(logout.state.failure!.kind, ProgramDeleteFailureKind.unauthorized);

    late final _FakeVersionedRoutines switching;
    switching = _FakeVersionedRoutines(
      const [],
      onList: () async {
        switching.switchSession(owner: _otherOwner, cycle: _otherCycle);
        return const [];
      },
    );
    final switchController = _controller(
      programs: _FakePrograms([_program()]),
      routines: switching,
      deleteRepository: _FakeDeleteRepository(attemptGate: gate),
      attemptGate: gate,
    );
    addTearDown(switchController.dispose);
    expect(await switchController.prepare(_source), isFalse);
    expect(switchController.state.failure!.kind,
        ProgramDeleteFailureKind.unauthorized);
  });

  test(
      'account switch during dispatch becomes UNKNOWN without old-owner refresh',
      () async {
    late final _FakeVersionedRoutines routines;
    final gate = ProgramDeleteAttemptGate();
    final deleteRepository = _FakeDeleteRepository(
      attemptGate: gate,
      onDelete: () async {
        routines.switchSession(owner: _otherOwner, cycle: _otherCycle);
        return _success(moved: 1);
      },
    );
    routines = _FakeVersionedRoutines([_snapshot(_routineOne)]);
    final refreshes = <ProgramDeleteRefreshRequest>[];
    final controller = _controller(
      programs: _FakePrograms([_program()]),
      routines: routines,
      deleteRepository: deleteRepository,
      attemptGate: gate,
      refreshes: refreshes,
    );
    addTearDown(controller.dispose);

    expect(await controller.prepare(_source), isTrue);
    final state = await controller.confirm(clientMutationId: _mutationOne);
    expect(state.status, ProgramDeleteOperationStatus.unknown);
    expect(state.unknown?.reason, ProgramDeleteUncertainty.sessionChanged);
    expect(refreshes, isEmpty);
    expect(deleteRepository.writes, 1);
    expect(await controller.prepare(_source), isFalse);
  });

  test('pending Create and pending Edit/Move block preparation', () async {
    final pendingCommand = _createCommand();
    final pending = RoutinePendingCreateGate()
      ..bindSession(owner: _owner, loginCycle: _cycle)
      ..retain(
        owner: _owner,
        loginCycle: _cycle,
        command: pendingCommand,
      );
    addTearDown(pending.dispose);
    final operations = RoutineMoveDeleteAttemptGate();
    final gate = ProgramDeleteAttemptGate();
    final controller = _controller(
      programs: _FakePrograms([_program()]),
      routines: _FakeVersionedRoutines([_snapshot(_routineOne)]),
      deleteRepository: _FakeDeleteRepository(attemptGate: gate),
      attemptGate: gate,
      pendingCreateGate: pending,
      routineOperationGate: operations,
    );
    addTearDown(controller.dispose);

    expect(await controller.prepare(_source), isFalse);
    expect(controller.state.failure!.kind,
        ProgramDeleteFailureKind.staleMembership);

    pending.releaseDefiniteForOwner(
      owner: _owner,
      command: pendingCommand,
    );
    operations.tryStart(_owner, _routineOne);
    final second = _controller(
      programs: _FakePrograms([_program()]),
      routines: _FakeVersionedRoutines([_snapshot(_routineOne)]),
      deleteRepository: _FakeDeleteRepository(attemptGate: gate),
      attemptGate: gate,
      routineOperationGate: operations,
    );
    addTearDown(second.dispose);
    expect(await second.prepare(_source), isFalse);
    expect(
        second.state.failure!.kind, ProgramDeleteFailureKind.staleMembership);
  });

  test('pending Create or Routine operation after preparation blocks dispatch',
      () async {
    final pending = RoutinePendingCreateGate()
      ..bindSession(owner: _owner, loginCycle: _cycle);
    addTearDown(pending.dispose);
    final operations = RoutineMoveDeleteAttemptGate();
    final gate = ProgramDeleteAttemptGate();
    final repository = _FakeDeleteRepository(attemptGate: gate);
    final controller = _controller(
      programs: _FakePrograms([_program()]),
      routines: _FakeVersionedRoutines([_snapshot(_routineOne)]),
      deleteRepository: repository,
      attemptGate: gate,
      pendingCreateGate: pending,
      routineOperationGate: operations,
    );
    addTearDown(controller.dispose);

    expect(await controller.prepare(_source), isTrue);
    final command = _createCommand();
    pending.retain(
      owner: _owner,
      loginCycle: _cycle,
      command: command,
    );
    expect(
      (await controller.confirm(clientMutationId: _mutationOne)).failure!.kind,
      ProgramDeleteFailureKind.staleMembership,
    );
    expect(repository.writes, 0);

    pending.releaseDefiniteForOwner(owner: _owner, command: command);
    final second = _controller(
      programs: _FakePrograms([_program()]),
      routines: _FakeVersionedRoutines([_snapshot(_routineOne)]),
      deleteRepository: repository,
      attemptGate: gate,
      pendingCreateGate: pending,
      routineOperationGate: operations,
    );
    addTearDown(second.dispose);
    expect(await second.prepare(_source), isTrue);
    expect(operations.tryStart(_owner, _routineOne), isTrue);
    expect(
      (await second.confirm(clientMutationId: _mutationTwo)).failure!.kind,
      ProgramDeleteFailureKind.staleMembership,
    );
    expect(repository.writes, 0);
  });

  test('in-flight conflict is recoverable after the owning attempt rejects',
      () async {
    final gate = ProgramDeleteAttemptGate();
    var calls = 0;
    final repository = _FakeDeleteRepository(
      attemptGate: gate,
      onDelete: () {
        calls++;
        return calls == 1
            ? Future<ProgramDeleteResult>.error(
                const ProgramDeleteException(
                  ProgramDeleteFailureKind.staleMembership,
                ),
              )
            : Future<ProgramDeleteResult>.value(_success(moved: 1));
      },
    );
    final first = _controller(
      programs: _FakePrograms([_program()]),
      routines: _FakeVersionedRoutines([_snapshot(_routineOne)]),
      deleteRepository: repository,
      attemptGate: gate,
    );
    final second = _controller(
      programs: _FakePrograms([_program()]),
      routines: _FakeVersionedRoutines([_snapshot(_routineOne)]),
      deleteRepository: repository,
      attemptGate: gate,
    );
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    expect(await first.prepare(_source), isTrue);
    expect(await second.prepare(_source), isTrue);
    final firstAttempt = first.confirm(clientMutationId: _mutationOne);
    final secondState = await second.confirm(clientMutationId: _mutationTwo);
    expect(secondState.status, ProgramDeleteOperationStatus.definitelyRejected);
    expect(secondState.failure!.kind, ProgramDeleteFailureKind.inProgress);
    expect((await firstAttempt).status,
        ProgramDeleteOperationStatus.definitelyRejected);

    expect(await second.prepare(_source), isTrue);
    expect((await second.confirm(clientMutationId: _mutationTwo)).status,
        ProgramDeleteOperationStatus.confirmed);
    expect(repository.writes, 2);
  });

  test('definite stale rejection requires a fresh snapshot and UUID', () async {
    final gate = ProgramDeleteAttemptGate();
    final deleteRepository = _FakeDeleteRepository(
      attemptGate: gate,
      outcomes: <Object>[
        const ProgramDeleteException(ProgramDeleteFailureKind.staleMembership),
        _success(moved: 1),
      ],
    );
    final controller = _controller(
      programs: _FakePrograms([_program()]),
      routines: _FakeVersionedRoutines([_snapshot(_routineOne)]),
      deleteRepository: deleteRepository,
      attemptGate: gate,
    );
    addTearDown(controller.dispose);

    expect(await controller.prepare(_source), isTrue);
    expect((await controller.confirm(clientMutationId: _mutationOne)).status,
        ProgramDeleteOperationStatus.definitelyRejected);
    expect(
      (await controller.confirm(clientMutationId: _mutationTwo)).status,
      ProgramDeleteOperationStatus.definitelyRejected,
    );
    expect(await controller.prepare(_source), isTrue);
    expect((await controller.confirm(clientMutationId: _mutationTwo)).status,
        ProgramDeleteOperationStatus.confirmed);
    expect(deleteRepository.writes, 2);
  });

  for (final entry in <(String, ProgramDeleteUncertainty)>[
    (
      '40003 statement_completion_unknown',
      ProgramDeleteUncertainty.unconfirmed
    ),
    ('timeout', ProgramDeleteUncertainty.unconfirmed),
    ('lost ACK', ProgramDeleteUncertainty.unconfirmed),
    ('malformed response', ProgramDeleteUncertainty.malformedResponse),
    ('session switch', ProgramDeleteUncertainty.sessionChanged),
  ]) {
    test('UNKNOWN ${entry.$1} stays sticky and refresh is not success',
        () async {
      final gate = ProgramDeleteAttemptGate();
      final deleteRepository = _FakeDeleteRepository(
        attemptGate: gate,
        outcomes: <Object>[ProgramDeleteOutcomeUnknown(reason: entry.$2)],
      );
      final refreshes = <ProgramDeleteRefreshRequest>[];
      final controller = _controller(
        programs: _FakePrograms([_program()]),
        routines: _FakeVersionedRoutines([_snapshot(_routineOne)]),
        deleteRepository: deleteRepository,
        attemptGate: gate,
        refreshes: refreshes,
      );
      addTearDown(controller.dispose);

      expect(await controller.prepare(_source), isTrue);
      expect((await controller.confirm(clientMutationId: _mutationOne)).status,
          ProgramDeleteOperationStatus.unknown);
      expect(await controller.prepare(_source), isFalse);
      expect(controller.state.status, ProgramDeleteOperationStatus.unknown);
      expect(refreshes, hasLength(1));
      expect(controller.state.result, isNull);
      expect(deleteRepository.writes, 1);
    });
  }

  test('concurrent confirmations remain single-flight', () async {
    final completer = Completer<ProgramDeleteResult>();
    final gate = ProgramDeleteAttemptGate();
    final deleteRepository = _FakeDeleteRepository(
      attemptGate: gate,
      onDelete: () => completer.future,
    );
    final controller = _controller(
      programs: _FakePrograms([_program()]),
      routines: _FakeVersionedRoutines([_snapshot(_routineOne)]),
      deleteRepository: deleteRepository,
      attemptGate: gate,
    );
    addTearDown(controller.dispose);

    expect(await controller.prepare(_source), isTrue);
    final first = controller.confirm(clientMutationId: _mutationOne);
    final second = await controller.confirm(clientMutationId: _mutationTwo);
    expect(second.status, ProgramDeleteOperationStatus.inFlight);
    expect(deleteRepository.writes, 1);

    completer.complete(_success(moved: 1));
    expect((await first).status, ProgramDeleteOperationStatus.confirmed);
    expect(deleteRepository.writes, 1);
  });
}

final class _FakePrograms implements ProgramRepository {
  _FakePrograms(this.programs, {this.onList});

  final List<Program> programs;
  final Future<List<Program>> Function()? onList;

  @override
  Future<List<Program>> list() async =>
      onList?.call() ?? List<Program>.unmodifiable(programs);

  @override
  Future<void> create(Program program) async {}

  @override
  Future<void> rename({required ProgramId id, required String name}) async {}
}

final class _FakeVersionedRoutines implements RoutineVersionedRenameRepository {
  _FakeVersionedRoutines(
    this.snapshots, {
    String? owner = '11111111-1111-4111-8111-111111111111',
    String? cycle = 'cycle-a',
    this.onList,
  })  : _owner = owner,
        _cycle = cycle;

  final List<RoutineMetadataRevision> snapshots;
  final Future<List<RoutineMetadataRevision>> Function()? onList;
  String? _owner;
  String? _cycle;

  @override
  String? get activeOwnerId => _owner;

  @override
  String? get activeLoginCycleId => _cycle;

  void switchSession({required String owner, required String cycle}) {
    _owner = owner;
    _cycle = cycle;
  }

  @override
  Future<List<RoutineMetadataRevision>> listVersioned(ProgramId programId) =>
      onList?.call() ?? Future<List<RoutineMetadataRevision>>.value(snapshots);

  @override
  Future<int> renameVersioned(RoutineAggregateUpdate command,
          {required String expectedLoginCycleId}) =>
      Future<int>.error(UnsupportedError('not used'));
}

final class _FakeDeleteRepository implements ProgramDeleteRepository {
  _FakeDeleteRepository({
    required this.attemptGate,
    this.result,
    this.outcomes = const [],
    this.onDelete,
  });

  final ProgramDeleteAttemptGate attemptGate;
  final ProgramDeleteResult? result;
  final List<Object> outcomes;
  final Future<ProgramDeleteResult> Function()? onDelete;
  int writes = 0;
  var _outcomeIndex = 0;

  @override
  Future<ProgramDeleteResult> delete({
    required ProgramDeleteTarget target,
    required String clientMutationId,
  }) async {
    if (!attemptGate.tryStart(
      owner: target.ownerId,
      sourceProgramId: target.sourceProgramId,
      target: target,
      mutationId: clientMutationId,
    )) {
      throw const ProgramDeleteException(ProgramDeleteFailureKind.inProgress);
    }
    writes++;
    try {
      final outcome = onDelete != null
          ? await onDelete!()
          : (_outcomeIndex < outcomes.length
              ? outcomes[_outcomeIndex++]
              : result ?? _success());
      if (outcome is ProgramDeleteException) throw outcome;
      if (outcome is ProgramDeleteOutcomeUnknown) throw outcome;
      final committed = outcome as ProgramDeleteResult;
      attemptGate.markCommitted(target.ownerId, target.sourceProgramId);
      return committed;
    } on ProgramDeleteOutcomeUnknown {
      attemptGate.markUnknown(target.ownerId, target.sourceProgramId);
      rethrow;
    } on ProgramDeleteException {
      attemptGate.markDefiniteRejection(
        target.ownerId,
        target.sourceProgramId,
        target,
        clientMutationId,
      );
      rethrow;
    } finally {
      attemptGate.finish(target.ownerId, target.sourceProgramId);
    }
  }
}

RoutineCreateCommand _createCommand() => RoutineCreateCommand(
      routine: Routine(
        id: _routineOne,
        programId: _source,
        name: 'Pending',
      ),
      mutationId: _mutationOne,
      entries: [
        RoutineCompositionEntry(
          id: '88888888-8888-4888-8888-888888888888',
          exercise: ExerciseRef.catalog('ex_bench_press'),
          sets: [
            RoutineCompositionSet(
              id: '99999999-9999-4999-8999-999999999999',
              prescription: SetPrescription(),
            ),
          ],
        ),
      ],
    );
