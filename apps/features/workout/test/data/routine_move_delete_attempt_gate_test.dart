import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _owner = '11111111-1111-4111-8111-111111111111';
const _otherOwner = '99999999-9999-4999-8999-999999999999';
const _cycle = 'cycle-one';
const _mutation = '55555555-5555-4555-8555-555555555555';
final _source = ProgramId('22222222-2222-4222-8222-222222222222');
final _destination = ProgramId('33333333-3333-4333-8333-333333333333');
final _routine = RoutineId('44444444-4444-4444-8444-444444444444');

Map<String, dynamic> _header({int revision = 4, ProgramId? program}) => {
  'id': _routine.value,
  'user_id': _owner,
  'program_id': (program ?? _source).value,
  'name': 'Morning',
  'composition_revision': revision,
};

final class _MoveGateway implements RoutineMoveGateway {
  Map<String, dynamic>? row = _header();
  Future<Map<String, dynamic>?> Function()? onRead;
  Future<Object?> Function()? onMove;
  Future<Object?> Function()? onAtomic;
  int reads = 0;
  int writes = 0;
  int atomicWrites = 0;

  @override
  Future<Map<String, dynamic>?> readOwnedHeader({
    required String userId, required String routineId,
  }) async {
    reads++;
    return onRead == null ? row : await onRead!();
  }

  @override
  Future<Object?> move({
    required String routineId,
    required String sourceProgramId,
    required String destinationProgramId,
    required int expectedRevision,
    required String mutationId,
  }) async {
    writes++;
    return onMove == null ? expectedRevision + 1 : await onMove!();
  }

  @override
  Future<Object?> createAndMove({
    required String routineId,
    required String sourceProgramId,
    required String newProgramId,
    required String newProgramName,
    required int expectedRevision,
    required String mutationId,
  }) async {
    atomicWrites++;
    return onAtomic == null ? expectedRevision + 1 : await onAtomic!();
  }
}

final class _DeleteGateway implements RoutineDeleteGateway {
  Map<String, dynamic>? row = _header();
  Future<Object?> Function()? onDelete;
  int reads = 0;
  int writes = 0;

  @override
  Future<Map<String, dynamic>?> readOwnedHeader({
    required String userId, required String routineId,
  }) async {
    reads++;
    return row;
  }

  @override
  Future<Object?> delete({
    required String routineId,
    required String programId,
    required int expectedRevision,
  }) async {
    writes++;
    return onDelete == null ? true : await onDelete!();
  }
}

SupabaseRoutineMoveRepository _moveRepo(
  _MoveGateway gateway, RoutineMoveDeleteAttemptGate gate,
) => SupabaseRoutineMoveRepository(
  gateway: gateway,
  attemptGate: RoutineMoveAttemptGate(),
  crossOperationGate: gate,
  currentUserId: () => _owner,
  currentLoginCycleId: () => _cycle,
);

SupabaseRoutineDeleteRepository _deleteRepo(
  _DeleteGateway gateway, RoutineMoveDeleteAttemptGate gate,
) => SupabaseRoutineDeleteRepository(
  gateway: gateway,
  attemptGate: RoutineDeleteAttemptGate(),
  crossOperationGate: gate,
  currentUserId: () => _owner,
  currentLoginCycleId: () => _cycle,
);

Future<RoutineMoveTarget> _inspectMove(
  SupabaseRoutineMoveRepository repository,
) async => (await repository.inspect(
  sourceProgramId: _source, routineId: _routine,
))!;

Future<RoutineDeleteTarget> _inspectDelete(
  SupabaseRoutineDeleteRepository repository, {ProgramId? program},
) async => (await repository.inspect(
  programId: program ?? _source, routineId: _routine,
))!;

Future<RoutineMoveResult> _dispatchMove(
  SupabaseRoutineMoveRepository repository, RoutineMoveTarget target,
) => repository.move(
  target: target,
  destinationProgramId: _destination,
  mutationId: _mutation,
);

Matcher _moveFailure(RoutineMoveFailureKind kind) =>
    isA<RoutineMoveException>().having((e) => e.kind, 'kind', kind);

Matcher _deleteFailure(RoutineDeleteFailureKind kind) =>
    isA<RoutineDeleteException>().having((e) => e.kind, 'kind', kind);

void main() {
  test('gate is per-owner/Routine and holds uncertain CAS until later read', () {
    final gate = RoutineMoveDeleteAttemptGate();
    expect(gate.tryStart(_owner, _routine), isTrue);
    expect(gate.tryStart(_owner, _routine), isFalse);
    expect(gate.tryStart(_otherOwner, _routine), isTrue,
        reason: 'One owner must not block another');
    gate.finish(_otherOwner, _routine);
    gate.markUncertain(_owner, _routine, 4);
    gate.finish(_owner, _routine);
    expect(gate.uncertain(_owner, _routine), isTrue);
    gate.observeRevision(_owner, _routine, 4);
    expect(gate.tryStart(_owner, _routine), isFalse,
        reason: 'An early same-revision read cannot disprove a late commit');
    gate.observeRevision(_owner, _routine, 5);
    expect(gate.tryStart(_owner, _routine), isTrue);
    gate.finish(_owner, _routine);
  });

  test('in-flight Move blocks inspected Delete and invalidates stale target',
      () async {
    final gate = RoutineMoveDeleteAttemptGate();
    final completing = Completer<Object?>();
    final mGateway = _MoveGateway()..onMove = () => completing.future;
    final dGateway = _DeleteGateway();
    final moving = _moveRepo(mGateway, gate);
    final deleting = _deleteRepo(dGateway, gate);
    final deleteTarget = await _inspectDelete(deleting);
    final moveTarget = await _inspectMove(moving);

    final pending = _dispatchMove(moving, moveTarget);
    await expectLater(deleting.delete(deleteTarget),
        throwsA(_deleteFailure(RoutineDeleteFailureKind.inProgress)));
    await expectLater(deleting.inspect(
        programId: _source, routineId: _routine),
        throwsA(_deleteFailure(RoutineDeleteFailureKind.inProgress)));
    expect(dGateway.writes, 0);
    completing.complete(5);
    expect(await pending, RoutineMoveResult.confirmed);
    await expectLater(deleting.delete(deleteTarget),
        throwsA(_deleteFailure(RoutineDeleteFailureKind.staleTarget)));
    expect(dGateway.writes, 0);
  });

  test('in-flight atomic Create & Move blocks Delete with zero Delete RPCs',
      () async {
    final gate = RoutineMoveDeleteAttemptGate();
    final completing = Completer<Object?>();
    final mGateway = _MoveGateway()..onAtomic = () => completing.future;
    final dGateway = _DeleteGateway();
    final moving = _moveRepo(mGateway, gate);
    final deleting = _deleteRepo(dGateway, gate);
    final deleteTarget = await _inspectDelete(deleting);
    final moveTarget = await _inspectMove(moving);

    final pending = moving.createAndMove(
      target: moveTarget,
      newProgramId: _destination,
      newProgramName: 'Program 1',
      mutationId: _mutation,
    );
    await expectLater(deleting.delete(deleteTarget),
        throwsA(_deleteFailure(RoutineDeleteFailureKind.inProgress)));
    expect(dGateway.writes, 0);
    completing.complete(5);
    expect(await pending, RoutineMoveResult.confirmed);
    expect(mGateway.atomicWrites, 1);
    await expectLater(deleting.delete(deleteTarget),
        throwsA(_deleteFailure(RoutineDeleteFailureKind.staleTarget)));
  });

  test('in-flight Delete blocks both existing and atomic Move dispatch',
      () async {
    final gate = RoutineMoveDeleteAttemptGate();
    final completing = Completer<Object?>();
    final mGateway = _MoveGateway();
    final dGateway = _DeleteGateway()..onDelete = () => completing.future;
    final moving = _moveRepo(mGateway, gate);
    final deleting = _deleteRepo(dGateway, gate);
    final moveTarget = await _inspectMove(moving);
    final deleteTarget = await _inspectDelete(deleting);

    final pending = deleting.delete(deleteTarget);
    await expectLater(_dispatchMove(moving, moveTarget),
        throwsA(_moveFailure(RoutineMoveFailureKind.inProgress)));
    await expectLater(moving.createAndMove(
      target: moveTarget,
      newProgramId: _destination,
      newProgramName: 'Program 1',
      mutationId: _mutation,
    ), throwsA(_moveFailure(RoutineMoveFailureKind.inProgress)));
    expect(mGateway.writes, 0);
    expect(mGateway.atomicWrites, 0);
    completing.complete(true);
    expect(await pending, RoutineDeleteResult.confirmed);
    await expectLater(_dispatchMove(moving, moveTarget),
        throwsA(_moveFailure(RoutineMoveFailureKind.staleTarget)));
    expect(mGateway.writes, 0);
  });

  test('unknown Move blocks Delete until later owner revision', () async {
    final gate = RoutineMoveDeleteAttemptGate();
    final mGateway = _MoveGateway()
      ..onMove = () async => throw TimeoutException('network unknown');
    final dGateway = _DeleteGateway();
    final moving = _moveRepo(mGateway, gate);
    final deleting = _deleteRepo(dGateway, gate);
    final moveTarget = await _inspectMove(moving);
    final deleteTarget = await _inspectDelete(deleting);

    await expectLater(_dispatchMove(moving, moveTarget),
        throwsA(isA<RoutineMoveOutcomeUnknown>()));
    await expectLater(deleting.delete(deleteTarget),
        throwsA(isA<RoutineDeleteOutcomeUnknown>()));
    final sameRevision = await _inspectDelete(deleting);
    await expectLater(deleting.delete(sameRevision),
        throwsA(isA<RoutineDeleteOutcomeUnknown>()));
    expect(dGateway.writes, 0);

    dGateway.row = _header(program: _destination, revision: 5);
    final fresh = await _inspectDelete(deleting, program: _destination);
    expect(await deleting.delete(fresh), RoutineDeleteResult.confirmed);
    expect(dGateway.writes, 1);
  });

  test('unknown Delete also blocks Move until positive later revision',
      () async {
    final gate = RoutineMoveDeleteAttemptGate();
    final mGateway = _MoveGateway();
    final dGateway = _DeleteGateway()
      ..onDelete = () async => throw TimeoutException('network unknown');
    final moving = _moveRepo(mGateway, gate);
    final deleting = _deleteRepo(dGateway, gate);
    final moveTarget = await _inspectMove(moving);
    final deleteTarget = await _inspectDelete(deleting);

    await expectLater(deleting.delete(deleteTarget),
        throwsA(isA<RoutineDeleteOutcomeUnknown>()));
    await expectLater(_dispatchMove(moving, moveTarget),
        throwsA(isA<RoutineMoveOutcomeUnknown>()));
    final sameRevision = await _inspectMove(moving);
    await expectLater(_dispatchMove(moving, sameRevision),
        throwsA(isA<RoutineMoveOutcomeUnknown>()));
    expect(mGateway.writes, 0);

    mGateway.row = _header(revision: 5);
    final fresh = await _inspectMove(moving);
    expect(await _dispatchMove(moving, fresh), RoutineMoveResult.confirmed);
    expect(mGateway.writes, 1);
  });

  test('late read started before opposite dispatch cannot prepare a target',
      () async {
    final gate = RoutineMoveDeleteAttemptGate();
    final read = Completer<Map<String, dynamic>?>();
    final mGateway = _MoveGateway()..onRead = () => read.future;
    final dGateway = _DeleteGateway();
    final moving = _moveRepo(mGateway, gate);
    final deleting = _deleteRepo(dGateway, gate);

    final awaitingMove = moving.inspect(
      sourceProgramId: _source, routineId: _routine);
    final deleteTarget = await _inspectDelete(deleting);
    expect(await deleting.delete(deleteTarget), RoutineDeleteResult.confirmed);
    read.complete(_header());
    await expectLater(awaitingMove,
        throwsA(_moveFailure(RoutineMoveFailureKind.staleTarget)));
    expect(mGateway.writes, 0);
  });
}
