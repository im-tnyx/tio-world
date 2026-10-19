import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const owner = '11111111-1111-4111-8111-111111111111';
const other = '99999999-9999-4999-8999-999999999999';
const cycle = 'cycle-a';
final source = ProgramId('22222222-2222-4222-8222-222222222222');
final destination = ProgramId('33333333-3333-4333-8333-333333333333');
final routine = RoutineId('44444444-4444-4444-8444-444444444444');
const mutation = '55555555-5555-4555-8555-555555555555';

Map<String, dynamic> header({
  String user = owner, ProgramId? program, int revision = 4,
}) => {
  'id': routine.value, 'user_id': user,
  'program_id': (program ?? source).value,
  'name': 'Morning', 'composition_revision': revision,
};
Matcher failure(RoutineMoveFailureKind kind) =>
    isA<RoutineMoveException>().having((e) => e.kind, 'kind', kind);
Matcher unknown(RoutineMoveUncertainty reason) =>
    isA<RoutineMoveOutcomeUnknown>().having((e) => e.reason, 'reason', reason);

final class FakeMoveGateway implements RoutineMoveGateway {
  Map<String, dynamic>? row = header();
  int reads = 0, writes = 0, atomicWrites = 0;
  Future<Object?> Function()? onMove;
  Future<Object?> Function()? onCreateAndMove;
  String? createdName;
  String? createdProgramId;
  void Function()? onRead;
  String? readOwner;
  String? readRoutine;
  String? sourceId, destinationId, routineId, mutationId;
  int? expectedRevision;

  @override
  Future<Map<String, dynamic>?> readOwnedHeader({
    required String userId, required String routineId,
  }) async {
    reads++;
    readOwner = userId;
    readRoutine = routineId;
    onRead?.call();
    return row;
  }

  @override
  Future<Object?> move({
    required String routineId, required String sourceProgramId,
    required String destinationProgramId, required int expectedRevision,
    required String mutationId,
  }) async {
    writes++;
    this.routineId = routineId;
    sourceId = sourceProgramId;
    destinationId = destinationProgramId;
    this.expectedRevision = expectedRevision;
    this.mutationId = mutationId;
    return await (onMove?.call() ?? Future<Object?>.value(expectedRevision + 1));
  }

  @override
  Future<Object?> createAndMove({
    required String routineId, required String sourceProgramId,
    required String newProgramId, required String newProgramName,
    required int expectedRevision, required String mutationId,
  }) async {
    atomicWrites++;
    this.routineId = routineId;
    sourceId = sourceProgramId;
    createdProgramId = newProgramId;
    createdName = newProgramName;
    this.expectedRevision = expectedRevision;
    this.mutationId = mutationId;
    return await (onCreateAndMove?.call() ??
        Future<Object?>.value(expectedRevision + 1));
  }
}

SupabaseRoutineMoveRepository repo(
  FakeMoveGateway gateway, {
  RoutineMoveAttemptGate? gate,
  RoutineMoveDeleteAttemptGate? crossOperationGate,
  String? Function()? user,
  String? Function()? loginCycle,
  Duration timeout = const Duration(seconds: 15),
  RoutineMovePendingCreateCheck? pendingCreateForProgram,
}) => SupabaseRoutineMoveRepository(
  gateway: gateway, attemptGate: gate ?? RoutineMoveAttemptGate(),
  crossOperationGate: crossOperationGate,
  currentUserId: user ?? () => owner,
  currentLoginCycleId: loginCycle ?? () => cycle,
  pendingCreateForProgram: pendingCreateForProgram,
  timeout: timeout,
);

Future<RoutineMoveTarget> inspect(SupabaseRoutineMoveRepository r) async =>
    (await r.inspect(sourceProgramId: source, routineId: routine))!;

Future<RoutineMoveResult> move(
  SupabaseRoutineMoveRepository r, RoutineMoveTarget target,
  {ProgramId? to, String token = mutation}
) => r.move(
  target: target, destinationProgramId: to ?? destination, mutationId: token);

void main() {
  group('read-only UNKNOWN Move verification', () {
    test('exact persisted mutation token attributes original existing Move',
        () async {
      final g = FakeMoveGateway()
        ..onMove = () async => throw const PostgrestException(
          message: 'completion unknown', code: '40003');
      final gate = RoutineMoveAttemptGate();
      final cross = RoutineMoveDeleteAttemptGate();
      final r = repo(g, gate: gate, crossOperationGate: cross);
      final target = await inspect(r);
      await expectLater(move(r, target),
          throwsA(unknown(RoutineMoveUncertainty.stillPresent)));
      expect(cross.uncertain(owner, routine), isTrue);
      expect(g.writes, 1);
      g.row = {
        ...header(program: destination, revision: 5),
        'last_composition_mutation_id': mutation,
      };
      final found = await r.verifyUnknown(routineId: routine);
      expect(found.kind, RoutineMoveReadbackKind.confirmedLatestMutation);
      expect(found.observedProgramId, destination);
      expect(found.observedRevision, 5);
      expect(cross.uncertain(owner, routine), isFalse);
      expect(g.writes, 1, reason: 'Readback never repeats the write RPC');
      await expectLater(r.verifyUnknown(routineId: routine),
          throwsA(failure(RoutineMoveFailureKind.staleTarget)));
    });

    test('atomic Create and Move also attributes the original token only',
        () async {
      final g = FakeMoveGateway()
        ..onCreateAndMove = () async => throw const PostgrestException(
          message: 'completion unknown', code: '40003');
      final r = repo(g);
      final target = await inspect(r);
      await expectLater(r.createAndMove(
        target: target, newProgramId: destination,
        newProgramName: 'Program 1', mutationId: mutation,
      ), throwsA(unknown(RoutineMoveUncertainty.stillPresent)));
      g.row = {
        ...header(program: destination, revision: 5),
        'last_composition_mutation_id': mutation,
      };
      expect((await r.verifyUnknown(routineId: routine)).kind,
          RoutineMoveReadbackKind.confirmedLatestMutation);
      expect(g.atomicWrites, 1);
      expect(g.writes, 0);
    });

    test('destination membership without the token cannot confirm Move',
        () async {
      final g = FakeMoveGateway()
        ..onMove = () async => throw const PostgrestException(
          message: 'completion unknown', code: '40003');
      final gate = RoutineMoveAttemptGate();
      final r = repo(g, gate: gate);
      final target = await inspect(r);
      await expectLater(move(r, target),
          throwsA(unknown(RoutineMoveUncertainty.stillPresent)));
      g.row = {
        ...header(program: destination, revision: 5),
        'last_composition_mutation_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      };
      final check = await r.verifyUnknown(routineId: routine);
      expect(check.kind, RoutineMoveReadbackKind.superseded);
      expect(check.observedProgramId, destination);
      expect(g.writes, 1);
      await expectLater(r.verifyUnknown(routineId: routine),
          throwsA(failure(RoutineMoveFailureKind.staleTarget)));
    });

    test('early unchanged and absent owner reads preserve the UNKNOWN hold',
        () async {
      final g = FakeMoveGateway()
        ..onMove = () async => throw const PostgrestException(
          message: 'completion unknown', code: '40003');
      final r = repo(g);
      final target = await inspect(r);
      await expectLater(move(r, target),
          throwsA(unknown(RoutineMoveUncertainty.stillPresent)));
      expect((await r.verifyUnknown(routineId: routine)).kind,
          RoutineMoveReadbackKind.notConfirmed);
      g.row = null;
      expect((await r.verifyUnknown(routineId: routine)).kind,
          RoutineMoveReadbackKind.absentOnRead);
      g.row = header();
      expect((await r.verifyUnknown(routineId: routine)).kind,
          RoutineMoveReadbackKind.notConfirmed);
      await expectLater(move(r, target),
          throwsA(unknown(RoutineMoveUncertainty.unconfirmed)));
      expect(g.writes, 1);
    });

    test('read failures keep the frozen attempt; no retry or success',
        () async {
      final g = FakeMoveGateway()
        ..onMove = () async => throw const PostgrestException(
          message: 'completion unknown', code: '40003');
      final r = repo(g);
      final target = await inspect(r);
      await expectLater(move(r, target),
          throwsA(unknown(RoutineMoveUncertainty.stillPresent)));
      g.onRead = () => throw StateError('network unavailable');
      final check = await r.verifyUnknown(routineId: routine);
      expect(check.kind, RoutineMoveReadbackKind.readUnavailable);
      await expectLater(move(r, target),
          throwsA(unknown(RoutineMoveUncertainty.unconfirmed)));
      expect(g.writes, 1);
    });

    test('owner or login-cycle changes cannot verify old UNKNOWN attempt',
        () async {
      var activeOwner = owner;
      var activeCycle = cycle;
      final g = FakeMoveGateway()
        ..onMove = () async => throw const PostgrestException(
          message: 'completion unknown', code: '40003');
      final r = repo(g,
          user: () => activeOwner, loginCycle: () => activeCycle);
      final target = await inspect(r);
      await expectLater(move(r, target),
          throwsA(unknown(RoutineMoveUncertainty.stillPresent)));
      final reads = g.reads;
      activeCycle = 'new-login-cycle';
      await expectLater(r.verifyUnknown(routineId: routine),
          throwsA(failure(RoutineMoveFailureKind.unauthorized)));
      activeOwner = other;
      await expectLater(r.verifyUnknown(routineId: routine),
          throwsA(failure(RoutineMoveFailureKind.staleTarget)));
      expect(g.reads, reads, reason: 'No cross-cycle/owner read is permitted');
    });

    test('mid-read session change rejects stale verification',
        () async {
      var activeCycle = cycle;
      final g = FakeMoveGateway()
        ..onMove = () async => throw const PostgrestException(
          message: 'completion unknown', code: '40003');
      final r = repo(g, loginCycle: () => activeCycle);
      final target = await inspect(r);
      await expectLater(move(r, target),
          throwsA(unknown(RoutineMoveUncertainty.stillPresent)));
      g.onRead = () => activeCycle = 'cycle-b';
      await expectLater(r.verifyUnknown(routineId: routine),
          throwsA(failure(RoutineMoveFailureKind.unauthorized)));
      expect(g.writes, 1);
    });

    test('no UNKNOWN attempt cannot read or claim a Move receipt',
        () async {
      final g = FakeMoveGateway();
      final r = repo(g);
      await expectLater(r.verifyUnknown(routineId: routine),
          throwsA(failure(RoutineMoveFailureKind.staleTarget)));
      expect(g.reads, 0);
    });
  });

  test('pending Create in source Program blocks both Move variants before RPC',
      () async {
    var pending = true;
    final g = FakeMoveGateway();
    final r = repo(g, pendingCreateForProgram: (u, p) =>
        pending && u == owner && p == source);
    final t = await inspect(r);
    await expectLater(move(r, t),
        throwsA(failure(RoutineMoveFailureKind.inProgress)));
    await expectLater(r.createAndMove(
      target: t, newProgramId: destination,
      newProgramName: 'New Program', mutationId: mutation,
    ), throwsA(failure(RoutineMoveFailureKind.inProgress)));
    expect(g.writes, 0);
    expect(g.atomicWrites, 0,
        reason: 'No Move RPC is dispatched while Create can still commit');
    // The original prepared Move capability was not consumed by the
    // program-level preflight; a definite Create release can unblock it.
    pending = false;
    expect(await move(r, t), RoutineMoveResult.confirmed);
    expect(g.writes, 1);
  });

  test('pending Create in existing destination blocks Move only for that owner',
      () async {
    var pending = true;
    final g = FakeMoveGateway();
    final r = repo(g, pendingCreateForProgram: (u, p) =>
        pending && u == owner && p == destination);
    final t = await inspect(r);
    await expectLater(move(r, t),
        throwsA(failure(RoutineMoveFailureKind.inProgress)));
    expect(g.writes, 0);
    pending = false;
    expect(await move(r, t), RoutineMoveResult.confirmed);
    expect(g.writes, 1);
  });

  test('pending Create for another owner is not a Move blocker', () async {
    final g = FakeMoveGateway();
    final r = repo(g, pendingCreateForProgram: (u, p) =>
        u == other && p == source);
    final t = await inspect(r);
    expect(await move(r, t), RoutineMoveResult.confirmed);
    expect(g.writes, 1);
  });

  test('pending Create lookup error fails closed for both Move paths',
      () async {
    final g = FakeMoveGateway();
    final r = repo(g, pendingCreateForProgram: (u, p) =>
        throw StateError('disposed gate'));
    final t = await inspect(r);
    await expectLater(move(r, t),
        throwsA(failure(RoutineMoveFailureKind.inProgress)));
    await expectLater(r.createAndMove(
      target: t, newProgramId: destination,
      newProgramName: 'New Program', mutationId: mutation,
    ), throwsA(failure(RoutineMoveFailureKind.inProgress)));
    expect(g.writes, 0);
    expect(g.atomicWrites, 0);
  });

  for (final atomic in <bool>[false, true]) {
    final variant = atomic ? 'atomic Create and Move' : 'existing Move';

    Future<RoutineMoveResult> dispatch(
      SupabaseRoutineMoveRepository repository, RoutineMoveTarget target,
    ) => atomic
        ? repository.createAndMove(
            target: target, newProgramId: destination,
            newProgramName: 'New Program', mutationId: mutation,
          )
        : move(repository, target);

    test('cross-operation UNKNOWN outranks pending Create for $variant',
        () async {
      final cross = RoutineMoveDeleteAttemptGate();
      final gateway = FakeMoveGateway();
      var pendingLookupCalls = 0;
      final repository = repo(
        gateway,
        crossOperationGate: cross,
        pendingCreateForProgram: (ownerId, programId) {
          pendingLookupCalls++;
          return true;
        },
      );
      final target = await inspect(repository);
      expect(cross.tryStart(owner, routine), isTrue);
      cross.markUncertain(owner, routine, target.expectedRevision);
      cross.finish(owner, routine);

      await expectLater(
        dispatch(repository, target),
        throwsA(isA<RoutineMoveOutcomeUnknown>()),
      );
      expect(pendingLookupCalls, 0,
          reason: 'UNKNOWN requires do-not-retry, not Create in-progress');
      expect(gateway.writes, 0);
      expect(gateway.atomicWrites, 0);
    });

    test('stale cross-operation generation outranks Create for $variant',
        () async {
      final cross = RoutineMoveDeleteAttemptGate();
      final gateway = FakeMoveGateway();
      var pendingLookupCalls = 0;
      final repository = repo(
        gateway,
        crossOperationGate: cross,
        pendingCreateForProgram: (ownerId, programId) {
          pendingLookupCalls++;
          return true;
        },
      );
      final target = await inspect(repository);
      expect(cross.tryStart(owner, routine), isTrue);
      cross.finish(owner, routine);

      await expectLater(
        dispatch(repository, target),
        throwsA(failure(RoutineMoveFailureKind.staleTarget)),
      );
      expect(pendingLookupCalls, 0,
          reason: 'Previously inspected target is stale after peer write');
      expect(gateway.writes, 0);
      expect(gateway.atomicWrites, 0);
    });
  }

  test('atomic known SQL rejection after login-cycle change is UNKNOWN', () async {
    var loginCycle = cycle;
    final gate = RoutineMoveAttemptGate();
    final g = FakeMoveGateway()
      ..onCreateAndMove = () async {
        loginCycle = 'cycle-b';
        throw const PostgrestException(
          message: 'routine_create_move_revision_conflict', code: 'P0001');
      };
    final r = repo(g, gate: gate, loginCycle: () => loginCycle);
    final t = await inspect(r);
    await expectLater(r.createAndMove(
      target: t, newProgramId: destination,
      newProgramName: 'Cardio', mutationId: mutation,
    ), throwsA(unknown(RoutineMoveUncertainty.sessionChanged)));
    expect(g.atomicWrites, 1);
    expect(g.reads, 1, reason: 'No stale-cycle reconciliation read');
    final next = repo(g, gate: gate, loginCycle: () => loginCycle);
    final fresh = await inspect(next);
    await expectLater(move(next, fresh),
        throwsA(unknown(RoutineMoveUncertainty.unconfirmed)));
    expect(g.writes, 0,
        reason: 'Old-owner response must freeze both Move paths');
  });

  test('existing Move known SQL rejection after login switch is UNKNOWN',
      () async {
    var loginCycle = cycle;
    final g = FakeMoveGateway()
      ..onMove = () async {
        loginCycle = 'cycle-b';
        throw const PostgrestException(
          message: 'routine_move_revision_conflict', code: 'P0001');
      };
    final r = repo(g, loginCycle: () => loginCycle);
    final t = await inspect(r);
    await expectLater(move(r, t),
        throwsA(unknown(RoutineMoveUncertainty.sessionChanged)));
    expect(g.writes, 1);
    expect(g.reads, 1);
  });

  test('PGRST303 bad JWT is definitive and leaves shared gate reusable',
      () async {
    final g = FakeMoveGateway()
      ..onCreateAndMove = () async => throw const PostgrestException(
          message: 'JWT claims validation or parsing failed',
          code: 'PGRST303');
    final gate = RoutineMoveAttemptGate();
    final r = repo(g, gate: gate);
    final t = await inspect(r);
    await expectLater(r.createAndMove(
      target: t, newProgramId: destination,
      newProgramName: 'Cardio', mutationId: mutation,
    ), throwsA(failure(RoutineMoveFailureKind.unauthorized)));
    expect(g.atomicWrites, 1);
    expect(g.reads, 1,
        reason: 'JWT validation failed before any RPC execution');
    final second = repo(g, gate: gate);
    final fresh = await inspect(second);
    expect(await move(second, fresh), RoutineMoveResult.confirmed,
        reason: 'A corrected JWT and fresh inspect must not be blocked');
    expect(g.writes, 1);
  });

  test('atomic SQLSTATE 40003 stays UNKNOWN and freezes both Move paths',
      () async {
    final g = FakeMoveGateway()
      ..onCreateAndMove = () async => throw const PostgrestException(
          message: 'statement completion unknown', code: '40003');
    final gate = RoutineMoveAttemptGate();
    final first = repo(g, gate: gate);
    final target = await inspect(first);
    await expectLater(first.createAndMove(
      target: target, newProgramId: destination,
      newProgramName: 'Program 1', mutationId: mutation,
    ), throwsA(unknown(RoutineMoveUncertainty.stillPresent)));
    expect(g.atomicWrites, 1);
    expect(g.reads, 2,
        reason: 'Unknown completion must attempt owner-scoped reconciliation');
    final next = repo(g, gate: gate);
    final fresh = await inspect(next);
    await expectLater(move(next, fresh),
        throwsA(unknown(RoutineMoveUncertainty.unconfirmed)));
    await expectLater(next.createAndMove(
      target: fresh, newProgramId: destination,
      newProgramName: 'Program 2', mutationId: mutation,
    ), throwsA(unknown(RoutineMoveUncertainty.unconfirmed)));
    expect(g.writes, 0);
    expect(g.atomicWrites, 1,
        reason: 'No new Program ID/token replay of uncertain commit');
  });

  test('existing Move SQLSTATE 40003 likewise remains UNKNOWN', () async {
    final g = FakeMoveGateway()
      ..onMove = () async => throw const PostgrestException(
          message: 'statement completion unknown', code: '40003');
    final r = repo(g);
    final target = await inspect(r);
    await expectLater(move(r, target),
        throwsA(unknown(RoutineMoveUncertainty.stillPresent)));
    expect(g.writes, 1);
    expect(g.reads, 2);
  });

  test('SQLSTATE 57014 server cancellation is definite and gate reusable',
      () async {
    final g = FakeMoveGateway()
      ..onCreateAndMove = () async => throw const PostgrestException(
          message: 'canceling statement due to statement timeout',
          code: '57014');
    final gate = RoutineMoveAttemptGate();
    final first = repo(g, gate: gate);
    final target = await inspect(first);
    await expectLater(first.createAndMove(
      target: target, newProgramId: destination,
      newProgramName: 'Program 1', mutationId: mutation,
    ), throwsA(failure(RoutineMoveFailureKind.transactionAborted)));
    expect(g.atomicWrites, 1);
    expect(g.reads, 1,
        reason: 'Server query_canceled proves rolled-back statement');
    final next = repo(g, gate: gate);
    final fresh = await inspect(next);
    expect(await move(next, fresh), RoutineMoveResult.confirmed,
        reason: 'A new confirmed Move can proceed after server timeout');
    expect(g.writes, 1);
  });

  for (final (code, kind) in
      <(String, RoutineMoveFailureKind)>[
        ('55P03', RoutineMoveFailureKind.transactionAborted),
        ('429', RoutineMoveFailureKind.unavailable),
        ('422', RoutineMoveFailureKind.invalidRequest),
      ]) {
    test('$code definitive rejection preserves shared Move gate', () async {
      final g = FakeMoveGateway()
        ..onCreateAndMove = () async => throw PostgrestException(
            message: 'pre-execution rejection', code: code);
      final gate = RoutineMoveAttemptGate();
      final first = repo(g, gate: gate);
      final target = await inspect(first);
      await expectLater(first.createAndMove(
        target: target, newProgramId: destination,
        newProgramName: 'Program 1', mutationId: mutation,
      ), throwsA(failure(kind)));
      expect(g.atomicWrites, 1);
      expect(g.reads, 1,
          reason: 'Definite rejection must not trigger unknown reconciliation');
      final next = repo(g, gate: gate);
      final fresh = await inspect(next);
      expect(await move(next, fresh), RoutineMoveResult.confirmed,
          reason: 'Fresh owner-scoped attempt is permitted after rejection');
      expect(g.writes, 1);
    });
  }

  for (final code in <String>['408', '499']) {
    test('HTTP $code is ambiguous and freezes shared Move gate', () async {
      final g = FakeMoveGateway()
        ..onCreateAndMove = () async => throw PostgrestException(
            message: 'request timed out', code: code);
      final gate = RoutineMoveAttemptGate();
      final first = repo(g, gate: gate);
      final target = await inspect(first);
      await expectLater(first.createAndMove(
        target: target, newProgramId: destination,
        newProgramName: 'Program 1', mutationId: mutation,
      ), throwsA(unknown(RoutineMoveUncertainty.stillPresent)));
      expect(g.reads, 2,
          reason: 'Ambiguous transport status must trigger reconciliation');
      final next = repo(g, gate: gate);
      final fresh = await inspect(next);
      await expectLater(move(next, fresh),
          throwsA(unknown(RoutineMoveUncertainty.unconfirmed)));
      expect(g.writes, 0);
      expect(g.atomicWrites, 1);
    });
  }

  for (final (code, kind) in <(String, RoutineMoveFailureKind)>[
    ('53000', RoutineMoveFailureKind.transactionAborted),
    ('53100', RoutineMoveFailureKind.transactionAborted),
    ('53200', RoutineMoveFailureKind.transactionAborted),
    ('53300', RoutineMoveFailureKind.unavailable),
    ('53400', RoutineMoveFailureKind.transactionAborted),
    ('57P03', RoutineMoveFailureKind.unavailable),
  ]) {
    test('$code infrastructure rejection is definite and reusable', () async {
      final gateway = FakeMoveGateway()
        ..onCreateAndMove = () async => throw PostgrestException(
            message: 'server unavailable before commit', code: code);
      final gate = RoutineMoveAttemptGate();
      final first = repo(gateway, gate: gate);
      final target = await inspect(first);
      await expectLater(first.createAndMove(
        target: target, newProgramId: destination,
        newProgramName: 'Program 1', mutationId: mutation,
      ), throwsA(failure(kind)));
      expect(gateway.atomicWrites, 1);
      expect(gateway.reads, 1,
          reason: 'Definite server rejection must not reconcile UNKNOWN');
      final second = repo(gateway, gate: gate);
      final fresh = await inspect(second);
      expect(await move(second, fresh), RoutineMoveResult.confirmed,
          reason: 'Fresh owner-scoped Move works after infrastructure repair');
      expect(gateway.writes, 1);
    });
  }

  test('PGRST300 missing JWT secret is definite; new Move cannot poison gate',
      () async {
    final g = FakeMoveGateway()
      ..onCreateAndMove = () async => throw const PostgrestException(
          message: 'No active JWT secret configured', code: 'PGRST300');
    final gate = RoutineMoveAttemptGate();
    final first = repo(g, gate: gate);
    final target = await inspect(first);
    await expectLater(first.createAndMove(
      target: target, newProgramId: destination,
      newProgramName: 'Program 1', mutationId: mutation,
    ), throwsA(failure(RoutineMoveFailureKind.unavailable)));
    expect(g.atomicWrites, 1);
    expect(g.reads, 1,
        reason: 'Missing JWT secret rejects before the RPC executes');
    final second = repo(g, gate: gate);
    final fresh = await inspect(second);
    expect(await move(second, fresh), RoutineMoveResult.confirmed,
        reason: 'After backend repair a new inspected Move is not frozen');
    expect(g.writes, 1);
  });

  for (final code in <String>[
    'PGRST000', 'PGRST001', 'PGRST002', 'PGRST003',
  ]) {
    test('$code is pre-execution: no unknown gate poison after outage',
        () async {
      final g = FakeMoveGateway()
        ..onCreateAndMove = () async => throw PostgrestException(
          message: 'Cannot acquire database connection', code: code);
      final gate = RoutineMoveAttemptGate();
      final r = repo(g, gate: gate);
      final target = await inspect(r);
      await expectLater(r.createAndMove(
        target: target, newProgramId: destination,
        newProgramName: 'Program 1', mutationId: mutation,
      ), throwsA(failure(RoutineMoveFailureKind.unavailable)));
      expect(g.atomicWrites, 1);
      expect(g.reads, 1, reason: 'No uncertain-result reconciliation');
      final next = repo(g, gate: gate);
      final fresh = await inspect(next);
      expect(await move(next, fresh), RoutineMoveResult.confirmed,
          reason: 'Outage repair permits new inspected existing Move');
      expect(g.writes, 1);
    });
  }

  for (final (code, message) in <(String, String)>[
    ('25006', 'cannot execute INSERT in a read-only transaction'),
    ('PGRST106', 'schema public is not an exposed schema'),
  ]) {
    test('$code rejects without poisoning the shared Move gate', () async {
      final g = FakeMoveGateway()
        ..onCreateAndMove = () async => throw PostgrestException(
          message: message, code: code);
      final gate = RoutineMoveAttemptGate();
      final first = repo(g, gate: gate);
      final target = await inspect(first);
      await expectLater(first.createAndMove(
        target: target, newProgramId: destination,
        newProgramName: 'Program 1', mutationId: mutation,
      ), throwsA(failure(RoutineMoveFailureKind.unavailable)));
      expect(g.atomicWrites, 1);
      expect(g.reads, 1, reason: 'Known rejection must not reconcile');
      final next = repo(g, gate: gate);
      final fresh = await inspect(next);
      expect(await move(next, fresh), RoutineMoveResult.confirmed,
          reason: 'Fresh inspect recovers after known rejection');
      expect(g.writes, 1);
    });
  }

  test('PGRST203 is pre-execution rejection, never freezes shared Move gate',
      () async {
    final g = FakeMoveGateway()
      ..onCreateAndMove = () async => throw const PostgrestException(
          message: 'RPC overload is ambiguous', code: 'PGRST203');
    final gate = RoutineMoveAttemptGate();
    final r = repo(g, gate: gate);
    final t = await inspect(r);
    await expectLater(r.createAndMove(
      target: t, newProgramId: destination,
      newProgramName: 'Cardio', mutationId: mutation,
    ), throwsA(failure(RoutineMoveFailureKind.unavailable)));
    expect(g.atomicWrites, 1);
    expect(g.reads, 1,
        reason: 'A rejected route cannot have executed SQL');
    final second = repo(g, gate: gate);
    final retryTarget = await inspect(second);
    expect(await move(second, retryTarget), RoutineMoveResult.confirmed,
        reason: 'A fresh inspected Move is permitted after definite rejection');
    expect(g.writes, 1);
  });


  test('atomic SDK sends exactly one protected RPC, no standalone Program INSERT',
      () async {
    final requests = <http.Request>[];
    final client = SupabaseClient(
      'https://example.test', 'synthetic-publishable-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.method == 'GET') {
          return http.Response(jsonEncode(header()), 200,
              headers: {'content-type': 'application/json'}, request: request);
        }
        return http.Response('5', 200,
            headers: {'content-type': 'application/json'}, request: request);
      }),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    addTearDown(client.dispose);
    final r = SupabaseRoutineMoveRepository(
      gateway: SupabaseRoutineMoveGateway(client),
      attemptGate: RoutineMoveAttemptGate(),
      currentUserId: () => owner,
      currentLoginCycleId: () => cycle,
    );
    final t = await inspect(r);
    final atomic = r as RoutineCreateMoveRepository;
    expect(await atomic.createAndMove(
      target: t, newProgramId: destination,
      newProgramName: 'Cardio Focus', mutationId: mutation,
    ), RoutineMoveResult.confirmed);
    expect(requests, hasLength(2));
    expect(requests.first.method, 'GET');
    expect(requests.last.method, 'POST');
    expect(requests.last.url.path,
        '/rest/v1/rpc/create_user_workout_program_and_move_routine');
    expect(jsonDecode(requests.last.body), {
      'p_routine_id': routine.value,
      'p_source_program_id': source.value,
      'p_new_program_id': destination.value,
      'p_new_program_name': 'Cardio Focus',
      'p_expected_revision': 4,
      'p_client_mutation_id': mutation,
    });
  });

  test('atomic invalid inputs and stale owner/cycle never dispatch', () async {
    final g = FakeMoveGateway();
    var activeCycle = cycle;
    final r = repo(g, loginCycle: () => activeCycle);
    final t = await inspect(r);
    Future<void> bad(ProgramId id, String name, String token) async {
      await expectLater(r.createAndMove(
        target: t, newProgramId: id,
        newProgramName: name, mutationId: token,
      ), throwsA(failure(RoutineMoveFailureKind.invalidRequest)));
    }
    await bad(source, 'Cardio', mutation);
    await bad(destination, '   ', mutation);
    await bad(destination, 'Cardio', 'bad-token');
    expect(g.atomicWrites, 0);
    activeCycle = 'cycle-b';
    await expectLater(r.createAndMove(
      target: t, newProgramId: destination,
      newProgramName: 'Cardio', mutationId: mutation,
    ), throwsA(failure(RoutineMoveFailureKind.unauthorized)));
    expect(g.atomicWrites, 0);
  });

  test('atomic and existing Move share one gate and prepared target', () async {
    final completion = Completer<Object?>();
    final g = FakeMoveGateway()
      ..onCreateAndMove = () => completion.future;
    final gate = RoutineMoveAttemptGate();
    final atomicRepo = repo(g, gate: gate);
    final existingRepo = repo(g, gate: gate);
    final target = await inspect(atomicRepo);
    final pending = atomicRepo.createAndMove(
      target: target, newProgramId: destination,
      newProgramName: 'Program 1', mutationId: mutation,
    );
    await expectLater(existingRepo.inspect(
      sourceProgramId: source, routineId: routine,
    ), throwsA(failure(RoutineMoveFailureKind.inProgress)));
    await expectLater(move(existingRepo, target),
        throwsA(failure(RoutineMoveFailureKind.inProgress)));
    expect(g.writes, 0);
    expect(g.atomicWrites, 1);
    completion.complete(5);
    expect(await pending, RoutineMoveResult.confirmed);
    await expectLater(move(atomicRepo, target),
        throwsA(failure(RoutineMoveFailureKind.staleTarget)));
    await expectLater(atomicRepo.createAndMove(
      target: target, newProgramId: destination,
      newProgramName: 'Program 1', mutationId: mutation,
    ), throwsA(failure(RoutineMoveFailureKind.staleTarget)));
    expect(g.atomicWrites, 1);
  });

  test('atomic auth switch after server ACK is unknown, never confirmed',
      () async {
    var activeCycle = cycle;
    final g = FakeMoveGateway()
      ..onCreateAndMove = () async {
        activeCycle = 'cycle-b';
        return 5;
      };
    final r = repo(g, loginCycle: () => activeCycle);
    final t = await inspect(r);
    await expectLater(r.createAndMove(
      target: t, newProgramId: destination,
      newProgramName: 'Program 1', mutationId: mutation,
    ), throwsA(unknown(RoutineMoveUncertainty.sessionChanged)));
    expect(g.atomicWrites, 1);
    expect(g.reads, 1, reason: 'Never refresh stale-owner data');
  });

  test('atomic timeout is unconfirmed and blocks existing Move at same revision',
      () async {
    final pending = Completer<Object?>();
    final g = FakeMoveGateway()..onCreateAndMove = () => pending.future;
    final gate = RoutineMoveAttemptGate();
    final r = repo(g, gate: gate,
        timeout: const Duration(milliseconds: 25));
    final target = await inspect(r);
    await expectLater(r.createAndMove(
      target: target, newProgramId: destination,
      newProgramName: 'Program 1', mutationId: mutation,
    ), throwsA(unknown(RoutineMoveUncertainty.stillPresent)));
    final second = repo(g, gate: gate);
    final next = await inspect(second);
    await expectLater(move(second, next),
        throwsA(unknown(RoutineMoveUncertainty.unconfirmed)));
    await expectLater(second.createAndMove(
      target: next, newProgramId: destination,
      newProgramName: 'Program 2', mutationId: mutation,
    ), throwsA(unknown(RoutineMoveUncertainty.unconfirmed)));
    expect(g.atomicWrites, 1);
    expect(g.writes, 0);
    pending.complete(5);
    g.row = header(program: destination, revision: 5);
    expect(await second.inspect(sourceProgramId: source,
        routineId: routine), isNull);
  });

  for (final e in <(String, String, RoutineMoveFailureKind)>[
    ('42501', 'permission denied', RoutineMoveFailureKind.forbidden),
    ('P0002', 'routine_create_move_not_found',
        RoutineMoveFailureKind.notFound),
    ('P0001', 'routine_create_move_revision_conflict',
        RoutineMoveFailureKind.revisionConflict),
    ('P0001', 'routine_create_move_program_conflict',
        RoutineMoveFailureKind.mutationConflict),
    ('P0001', 'routine_create_move_mutation_conflict',
        RoutineMoveFailureKind.mutationConflict),
    ('PGRST203', 'RPC overload is ambiguous',
        RoutineMoveFailureKind.unavailable),
    ('PGRST303', 'JWT claims validation or parsing failed',
        RoutineMoveFailureKind.unauthorized),
    ('PGRST300', 'No active JWT secret configured',
        RoutineMoveFailureKind.unavailable),
    ('PGRST000', 'Cannot acquire database connection',
        RoutineMoveFailureKind.unavailable),
    ('PGRST001', 'Cannot acquire database connection',
        RoutineMoveFailureKind.unavailable),
    ('PGRST002', 'Cannot acquire database connection',
        RoutineMoveFailureKind.unavailable),
    ('PGRST003', 'Cannot acquire database connection',
        RoutineMoveFailureKind.unavailable),
    ('25006', 'cannot execute INSERT in a read-only transaction',
        RoutineMoveFailureKind.unavailable),
    ('PGRST106', 'schema public is not an exposed schema',
        RoutineMoveFailureKind.unavailable),
    ('57014', 'canceling statement due to statement timeout',
        RoutineMoveFailureKind.transactionAborted),
    ('55P03', 'canceling statement due to lock timeout',
        RoutineMoveFailureKind.transactionAborted),
    ('53000', 'insufficient resources',
        RoutineMoveFailureKind.transactionAborted),
    ('53100', 'disk full', RoutineMoveFailureKind.transactionAborted),
    ('53200', 'out of memory', RoutineMoveFailureKind.transactionAborted),
    ('53300', 'too many connections', RoutineMoveFailureKind.unavailable),
    ('53400', 'configuration limit exceeded',
        RoutineMoveFailureKind.transactionAborted),
    ('57P03', 'database is starting up', RoutineMoveFailureKind.unavailable),
    ('429', 'rate limit', RoutineMoveFailureKind.unavailable),
    ('422', 'Unprocessable Entity', RoutineMoveFailureKind.invalidRequest),
  ]) {
    test('atomic SQLSTATE ${e.$1} ${e.$2} is definite', () async {
      final g = FakeMoveGateway()
        ..onCreateAndMove = () async => throw PostgrestException(
            message: e.$2, code: e.$1);
      final r = repo(g);
      final t = await inspect(r);
      await expectLater(r.createAndMove(
        target: t, newProgramId: destination,
        newProgramName: 'Program 1', mutationId: mutation,
      ), throwsA(failure(e.$3)));
      expect(g.reads, 1, reason: 'Known server rejection is not unknown');
      expect(g.atomicWrites, 1);
    });
  }

  test('SDK issues ONE protected RPC with frozen payload and no table update', () async {
    final sent = <http.Request>[];
    final client = SupabaseClient(
      'https://example.test', 'synthetic-publishable-key',
      httpClient: MockClient((request) async {
        sent.add(request);
        if (request.method == 'GET') {
          return http.Response(jsonEncode(header()), 200,
            headers: {'content-type': 'application/json'}, request: request);
        }
        return http.Response('5', 200,
          headers: {'content-type': 'application/json'}, request: request);
      }),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    addTearDown(client.dispose);
    final r = SupabaseRoutineMoveRepository(
      gateway: SupabaseRoutineMoveGateway(client),
      attemptGate: RoutineMoveAttemptGate(),
      currentUserId: () => owner, currentLoginCycleId: () => cycle,
    );
    final target = await inspect(r);
    expect(target.expectedRevision, 4);
    expect(target.loginCycleId, cycle);
    expect(await move(r, target), RoutineMoveResult.confirmed);
    expect(sent, hasLength(2));
    expect(sent.first.method, 'GET');
    expect(sent.first.url.path, '/rest/v1/user_workout_routines');
    expect(sent.first.url.queryParameters['user_id'], 'eq.$owner');
    expect(sent.last.method, 'POST');
    expect(sent.last.url.path, '/rest/v1/rpc/move_user_workout_routine');
    expect(jsonDecode(sent.last.body), {
      'p_routine_id': routine.value,
      'p_source_program_id': source.value,
      'p_destination_program_id': destination.value,
      'p_expected_revision': 4,
      'p_client_mutation_id': mutation,
    });
  });

  test('signed-out and missing cycle deny read and write', () async {
    final g = FakeMoveGateway();
    await expectLater(repo(g, user: () => null).inspect(
      sourceProgramId: source, routineId: routine),
      throwsA(failure(RoutineMoveFailureKind.unauthorized)));
    await expectLater(repo(g, loginCycle: () => null).inspect(
      sourceProgramId: source, routineId: routine),
      throwsA(failure(RoutineMoveFailureKind.unauthorized)));
    expect(g.reads, 0);
    expect(g.writes, 0);
  });

  test('owner switch during inspect cannot publish previous account', () async {
    var user = owner;
    final g = FakeMoveGateway()..onRead = () => user = other;
    await expectLater(repo(g, user: () => user).inspect(
      sourceProgramId: source, routineId: routine),
      throwsA(failure(RoutineMoveFailureKind.unauthorized)));
    expect(g.writes, 0);
  });

  test('wrong source Program and malformed or foreign row fail closed', () async {
    final g = FakeMoveGateway();
    final r = repo(g);
    expect(await r.inspect(sourceProgramId: destination, routineId: routine),
      isNull);
    g.row = header(user: other);
    await expectLater(inspect(r),
      throwsA(failure(RoutineMoveFailureKind.malformedData)));
    g.row = header()..['composition_revision'] = '4';
    await expectLater(inspect(r),
      throwsA(failure(RoutineMoveFailureKind.malformedData)));
    expect(g.writes, 0);
  });

  test('same destination and invalid token never dispatch', () async {
    final g = FakeMoveGateway();
    final r = repo(g);
    final target = await inspect(r);
    await expectLater(move(r, target, to: source),
      throwsA(failure(RoutineMoveFailureKind.invalidRequest)));
    await expectLater(move(r, target, token: 'bad'),
      throwsA(failure(RoutineMoveFailureKind.invalidRequest)));
    expect(g.writes, 0);
    expect(await move(r, target), RoutineMoveResult.confirmed);
  });

  test('successful target is single use; next Move needs new inspect', () async {
    final g = FakeMoveGateway();
    final r = repo(g);
    final target = await inspect(r);
    expect(await move(r, target), RoutineMoveResult.confirmed);
    await expectLater(move(r, target),
      throwsA(failure(RoutineMoveFailureKind.staleTarget)));
    expect(g.writes, 1);
  });

  for (final e in <(String, String, RoutineMoveFailureKind)>[
    ('42501', 'permission denied', RoutineMoveFailureKind.forbidden),
    ('P0002', 'routine_move_not_found', RoutineMoveFailureKind.notFound),
    ('P0001', 'routine_move_revision_conflict',
      RoutineMoveFailureKind.revisionConflict),
    ('P0001', 'routine_move_mutation_conflict',
      RoutineMoveFailureKind.mutationConflict),
    ('28000', 'routine_move_not_authenticated',
      RoutineMoveFailureKind.unauthorized),
    ('40P01', 'deadlock detected', RoutineMoveFailureKind.transactionAborted),
    ('57014', 'canceling statement due to statement timeout',
      RoutineMoveFailureKind.transactionAborted),
    ('55P03', 'canceling statement due to lock timeout',
        RoutineMoveFailureKind.transactionAborted),
    ('53000', 'insufficient resources',
        RoutineMoveFailureKind.transactionAborted),
    ('53100', 'disk full', RoutineMoveFailureKind.transactionAborted),
    ('53200', 'out of memory', RoutineMoveFailureKind.transactionAborted),
    ('53300', 'too many connections', RoutineMoveFailureKind.unavailable),
    ('53400', 'configuration limit exceeded',
        RoutineMoveFailureKind.transactionAborted),
    ('57P03', 'database is starting up', RoutineMoveFailureKind.unavailable),
    ('429', 'rate limit', RoutineMoveFailureKind.unavailable),
    ('422', 'Unprocessable Entity', RoutineMoveFailureKind.invalidRequest),
    ('PGRST203', 'RPC overload is ambiguous',
        RoutineMoveFailureKind.unavailable),
    ('PGRST303', 'JWT claims validation or parsing failed',
        RoutineMoveFailureKind.unauthorized),
    ('PGRST300', 'No active JWT secret configured',
        RoutineMoveFailureKind.unavailable),
    ('PGRST000', 'Cannot acquire database connection',
        RoutineMoveFailureKind.unavailable),
    ('PGRST001', 'Cannot acquire database connection',
        RoutineMoveFailureKind.unavailable),
    ('PGRST002', 'Cannot acquire database connection',
        RoutineMoveFailureKind.unavailable),
    ('PGRST003', 'Cannot acquire database connection',
        RoutineMoveFailureKind.unavailable),
    ('25006', 'cannot execute INSERT in a read-only transaction',
        RoutineMoveFailureKind.unavailable),
    ('PGRST106', 'schema public is not an exposed schema',
        RoutineMoveFailureKind.unavailable),
  ]) {
    test('SQLSTATE ${e.$1} ${e.$2} is a definite rejection', () async {
      final g = FakeMoveGateway()
        ..onMove = () async => throw PostgrestException(
          message: e.$2, code: e.$1);
      final r = repo(g);
      final t = await inspect(r);
      await expectLater(move(r, t), throwsA(failure(e.$3)));
      expect(g.reads, 1, reason: 'A definite abort does not reconcile');
      expect(g.writes, 1);
    });
  }

  test('auth cycle changes after ACK: no confirmed Move', () async {
    var loginCycle = cycle;
    final g = FakeMoveGateway()
      ..onMove = () async {
        loginCycle = 'cycle-b';
        return 5;
      };
    final r = repo(g, loginCycle: () => loginCycle);
    final target = await inspect(r);
    await expectLater(move(r, target),
      throwsA(unknown(RoutineMoveUncertainty.sessionChanged)));
    expect(g.writes, 1);
    expect(g.reads, 1, reason: 'Never read old owner under new cycle');
  });

  test('timeout means unconfirmed, never blind retry at same revision', () async {
    final completer = Completer<Object?>();
    final g = FakeMoveGateway()..onMove = () => completer.future;
    final gate = RoutineMoveAttemptGate();
    final r = repo(g, gate: gate,
      timeout: const Duration(milliseconds: 25));
    final old = await inspect(r);
    await expectLater(move(r, old),
      throwsA(unknown(RoutineMoveUncertainty.stillPresent)));
    expect(completer.isCompleted, false);
    final second = repo(g, gate: gate);
    final same = await inspect(second);
    await expectLater(move(second, same),
      throwsA(unknown(RoutineMoveUncertainty.unconfirmed)));
    expect(g.writes, 1);
    completer.complete(5);
    g.row = header(program: destination, revision: 5);
    expect(await second.inspect(sourceProgramId: source, routineId: routine),
      isNull);
    // A newer revision makes the unresolved old CAS impossible. A new
    // confirmation can then move BACK, never replay the old A->B token.
    final newTarget = (await second.inspect(
      sourceProgramId: destination, routineId: routine))!;
    // This is a NEW logical Move with a new server result; not the lost ACK.
    g.onMove = () async => 6;
    expect(await move(second, newTarget, to: source),
      RoutineMoveResult.confirmed);
    expect(g.writes, 2);
  });

  test('uncertain 503 and malformed 2xx cannot claim Move success', () async {
    for (final outcome in <Object?>[
      const PostgrestException(message: 'Server unavailable', code: '503'),
      4,
      '5',
    ]) {
      final g = FakeMoveGateway()
        ..onMove = () async {
          if (outcome is PostgrestException) throw outcome;
          return outcome;
        };
      final r = repo(g);
      final target = await inspect(r);
      await expectLater(move(r, target),
        throwsA(unknown(RoutineMoveUncertainty.stillPresent)));
      expect(g.writes, 1);
    }
  });
}
