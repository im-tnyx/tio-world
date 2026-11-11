import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/composition/auth_providers.dart';
import 'package:tio_app/app/composition/workout_providers.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _owner = '11111111-1111-4111-8111-111111111111';
const _otherOwner = '99999999-9999-4999-8999-999999999999';
const _cycle = 'cycle-a';
const _otherCycle = 'cycle-b';
const _mutationOne = '66666666-6666-4666-8666-666666666666';
const _mutationTwo = '77777777-7777-4777-8777-777777777777';
final _source = ProgramId('22222222-2222-4222-8222-222222222222');
final _destination = ProgramId('33333333-3333-4333-8333-333333333333');
final _routine = RoutineId('44444444-4444-4444-8444-444444444444');

void main() {
  test(
      'unmount before ACK still refreshes once and a replacement controller cannot duplicate the RPC',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final first = fixture.listenController();
    final controller = first.read()!;

    expect(await controller.prepare(_source), isTrue);
    final inFlight = controller.confirm(clientMutationId: _mutationOne);
    expect(fixture.deletes.writes, 1);

    first.close();
    await pumpEventQueue();

    final replacement = fixture.listenController();
    addTearDown(replacement.close);
    final replacementController = replacement.read()!;
    expect(await replacementController.prepare(_source), isFalse);
    expect(replacementController.state.failure?.kind,
        ProgramDeleteFailureKind.inProgress);
    expect(fixture.deletes.writes, 1);

    fixture.deletes.complete(_success());
    expect((await inFlight).status, ProgramDeleteOperationStatus.inFlight);
    await pumpEventQueue();

    final signal = fixture.container.read(routineMoveRefreshSignalProvider);
    expect(signal.matches(ownerId: _owner, loginCycleId: _cycle), isTrue);
    expect(signal.version, 1);
    expect(fixture.deletes.writes, 1);
  });

  test('unmount before UNKNOWN refreshes but retains sticky retry protection',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final first = fixture.listenController();
    final controller = first.read()!;

    expect(await controller.prepare(_source), isTrue);
    final inFlight = controller.confirm(clientMutationId: _mutationOne);
    expect(fixture.deletes.writes, 1);

    first.close();
    await pumpEventQueue();
    fixture.deletes.completeUnknown();
    expect((await inFlight).status, ProgramDeleteOperationStatus.inFlight);
    await pumpEventQueue();

    final signal = fixture.container.read(routineMoveRefreshSignalProvider);
    expect(signal.matches(ownerId: _owner, loginCycleId: _cycle), isTrue);
    expect(fixture.gate.isUnknown(_owner, _source), isTrue);

    final replacement = fixture.listenController();
    addTearDown(replacement.close);
    final replacementController = replacement.read()!;
    expect(await replacementController.prepare(_source), isFalse);
    expect(replacementController.state.status,
        ProgramDeleteOperationStatus.unknown);
    expect(fixture.deletes.writes, 1);
  });

  test(
      'account switch during an in-flight write has no cross-owner refresh or false success',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final listener = fixture.listenController();
    addTearDown(listener.close);
    final controller = listener.read()!;

    expect(await controller.prepare(_source), isTrue);
    final inFlight = controller.confirm(clientMutationId: _mutationOne);
    expect(fixture.deletes.writes, 1);

    fixture.auth.emit(const AuthSessionAuthenticated(AuthSession(
      userId: _otherOwner,
      loginCycleId: _otherCycle,
    )));
    await pumpEventQueue();
    fixture.deletes.complete(_success());

    final state = await inFlight;
    expect(state.status, ProgramDeleteOperationStatus.unknown);
    expect(state.unknown?.reason, ProgramDeleteUncertainty.sessionChanged);
    final signal = fixture.container.read(routineMoveRefreshSignalProvider);
    expect(signal.version, 0);
    expect(signal.matches(ownerId: _otherOwner, loginCycleId: _otherCycle),
        isFalse);
    expect(fixture.deletes.writes, 1);
  });

  test(
      'durable refresh delivery rejects an old cycle after its controller unmounts',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final listener = fixture.listenController();
    final controller = listener.read()!;

    expect(await controller.prepare(_source), isTrue);
    final inFlight = controller.confirm(clientMutationId: _mutationTwo);
    listener.close();
    await pumpEventQueue();

    fixture.auth.emit(const AuthSessionAuthenticated(AuthSession(
      userId: _otherOwner,
      loginCycleId: _otherCycle,
    )));
    await pumpEventQueue();
    fixture.deletes.complete(_success());
    await inFlight;
    await pumpEventQueue();

    final signal = fixture.container.read(routineMoveRefreshSignalProvider);
    expect(signal.version, 0);
    expect(fixture.deletes.writes, 1);
  });
}

final class _Fixture {
  _Fixture._({
    required this.auth,
    required this.gate,
    required this.deletes,
    required this.container,
  });

  factory _Fixture.createUnstarted() {
    final auth = _AuthStates(const AuthSessionAuthenticated(AuthSession(
      userId: _owner,
      loginCycleId: _cycle,
    )));
    final gate = ProgramDeleteAttemptGate();
    final routines = _AuthBoundRoutines(auth);
    final deletes = _ControlledDeleteRepository(gate);
    final container = ProviderContainer(
      overrides: [
        authSessionStateProvider.overrideWith((ref) => auth.states),
        programRepositoryProvider.overrideWithValue(_Programs()),
        routineRepositoryProvider.overrideWithValue(routines),
        programDeleteAttemptGateProvider.overrideWithValue(gate),
        programDeleteRepositoryProvider.overrideWithValue(deletes),
      ],
    );
    return _Fixture._(
      auth: auth,
      gate: gate,
      deletes: deletes,
      container: container,
    );
  }

  static Future<_Fixture> create() async {
    final fixture = _Fixture.createUnstarted();
    await fixture.container.read(authSessionStateProvider.future);
    return fixture;
  }

  final _AuthStates auth;
  final ProgramDeleteAttemptGate gate;
  final _ControlledDeleteRepository deletes;
  final ProviderContainer container;

  ProviderSubscription<ProgramDeleteController?> listenController() =>
      container.listen(
        programDeleteControllerProvider(_source),
        (previous, next) {},
        fireImmediately: true,
      );

  Future<void> dispose() async {
    container.dispose();
    await auth.dispose();
  }
}

final class _AuthStates {
  _AuthStates(this._current);

  final StreamController<AuthSessionState> _changes =
      StreamController<AuthSessionState>.broadcast();
  AuthSessionState _current;

  Stream<AuthSessionState> get states async* {
    yield _current;
    yield* _changes.stream;
  }

  void emit(AuthSessionState next) {
    _current = next;
    _changes.add(next);
  }

  Future<void> dispose() => _changes.close();

  AuthSession? get session => switch (_current) {
        AuthSessionAuthenticated(:final session) => session,
        _ => null,
      };
}

final class _Programs implements ProgramRepository {
  @override
  Future<void> create(Program program) async {}

  @override
  Future<List<Program>> list() async => [
        Program(id: _source, name: 'Legs'),
      ];

  @override
  Future<void> rename({required ProgramId id, required String name}) async {}
}

final class _AuthBoundRoutines
    implements RoutineRepository, RoutineVersionedRenameRepository {
  _AuthBoundRoutines(this._auth);

  final _AuthStates _auth;

  @override
  String? get activeLoginCycleId => _auth.session?.loginCycleId;

  @override
  String? get activeOwnerId => _auth.session?.userId;

  @override
  Future<void> create(Routine routine) async {}

  @override
  Future<List<Routine>> list(ProgramId programId) async => [
        for (final snapshot in await listVersioned(programId)) snapshot.routine,
      ];

  @override
  Future<void> rename({required RoutineId id, required String name}) async {}

  @override
  Future<List<RoutineMetadataRevision>> listVersioned(
      ProgramId programId) async {
    final cycle = activeLoginCycleId;
    if (cycle == null) return const [];
    return [
      RoutineMetadataRevision(
        routine: Routine(id: _routine, programId: programId, name: 'Routine'),
        revision: 1,
        loginCycleId: cycle,
      ),
    ];
  }

  @override
  Future<int> renameVersioned(
    RoutineAggregateUpdate command, {
    required String expectedLoginCycleId,
  }) =>
      Future<int>.error(UnsupportedError('not used'));
}

final class _ControlledDeleteRepository implements ProgramDeleteRepository {
  _ControlledDeleteRepository(this._gate);

  final ProgramDeleteAttemptGate _gate;
  final Completer<ProgramDeleteResult> _result =
      Completer<ProgramDeleteResult>();
  int writes = 0;

  void complete(ProgramDeleteResult result) => _result.complete(result);

  void completeUnknown() =>
      _result.completeError(const ProgramDeleteOutcomeUnknown());

  @override
  Future<ProgramDeleteResult> delete({
    required ProgramDeleteTarget target,
    required String clientMutationId,
  }) async {
    if (!_gate.tryStart(
      owner: target.ownerId,
      sourceProgramId: target.sourceProgramId,
      target: target,
      mutationId: clientMutationId,
    )) {
      throw const ProgramDeleteException(ProgramDeleteFailureKind.inProgress);
    }
    writes++;
    try {
      final result = await _result.future;
      _gate.markCommitted(target.ownerId, target.sourceProgramId);
      return result;
    } on ProgramDeleteOutcomeUnknown {
      _gate.markUnknown(target.ownerId, target.sourceProgramId);
      rethrow;
    } finally {
      _gate.finish(target.ownerId, target.sourceProgramId);
    }
  }
}

ProgramDeleteResult _success() => ProgramDeleteResult(
      deletedProgramId: _source,
      destinationProgramId: _destination,
      movedRoutineCount: 1,
    );
