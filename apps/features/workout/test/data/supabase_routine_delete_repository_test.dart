import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _owner = '11111111-1111-4111-8111-111111111111';
const _other = '99999999-9999-4999-8999-999999999999';
const _cycle = 'cycle-one';
final _program = ProgramId('22222222-2222-4222-8222-222222222222');
final _otherProgram = ProgramId('33333333-3333-4333-8333-333333333333');
final _routine = RoutineId('44444444-4444-4444-8444-444444444444');

Map<String, dynamic> _header({
  String owner = _owner,
  ProgramId? program,
  int revision = 4,
  String name = 'Routine 1',
}) => {
  'id': _routine.value,
  'user_id': owner,
  'program_id': (program ?? _program).value,
  'name': name,
  'composition_revision': revision,
};

Matcher _failure(RoutineDeleteFailureKind kind) =>
    isA<RoutineDeleteException>().having((e) => e.kind, 'kind', kind);

Matcher _unknown(RoutineDeleteUncertainty reason) =>
    isA<RoutineDeleteOutcomeUnknown>()
        .having((e) => e.reason, 'reason', reason);

Future<RoutineDeleteTarget> _target(
    SupabaseRoutineDeleteRepository repository) async =>
    (await repository.inspect(programId: _program, routineId: _routine))!;

void main() {
  test('SDK owner-filtered inspect then one revision-CAS RPC, never table DELETE',
      () async {
    final sent = <http.Request>[];
    final client = SupabaseClient(
      'https://example.test',
      'synthetic-publishable-key',
      httpClient: MockClient((request) async {
        sent.add(request);
        if (request.method == 'GET') {
          return http.Response(jsonEncode(_header()), 200,
              headers: {'content-type': 'application/json'},
              request: request);
        }
        return http.Response('true', 200,
            headers: {'content-type': 'application/json'}, request: request);
      }),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    addTearDown(client.dispose);
    final repository = SupabaseRoutineDeleteRepository(
      gateway: SupabaseRoutineDeleteGateway(client),
      currentUserId: () => _owner,
      currentLoginCycleId: () => _cycle,
    );
    final target = await _target(repository);
    expect(target.routineId, _routine);
    expect(target.programId, _program);
    expect(target.expectedRevision, 4);
    expect(target.name, 'Routine 1');
    expect(target.loginCycleId, _cycle);
    expect(await repository.delete(target), RoutineDeleteResult.confirmed);
    expect(sent, hasLength(2));
    expect(sent.first.method, 'GET');
    expect(sent.first.url.path, '/rest/v1/user_workout_routines');
    expect(sent.first.url.queryParameters['user_id'], 'eq.$_owner');
    expect(sent.first.url.queryParameters['id'], 'eq.${_routine.value}');
    expect(sent.last.method, 'POST');
    expect(sent.last.url.path,
        '/rest/v1/rpc/delete_user_workout_routine');
    expect(jsonDecode(sent.last.body), {
      'p_routine_id': _routine.value,
      'p_program_id': _program.value,
      'p_expected_revision': 4,
    });
  });

  test('missing authentication or login cycle fails before any I/O', () async {
    final gateway = _Gateway();
    final signedOut = gateway.repo(owner: () => null);
    await expectLater(
      signedOut.inspect(programId: _program, routineId: _routine),
      throwsA(_failure(RoutineDeleteFailureKind.unauthorized)),
    );
    final missingCycle = gateway.repo(cycle: () => null);
    await expectLater(
      missingCycle.inspect(programId: _program, routineId: _routine),
      throwsA(_failure(RoutineDeleteFailureKind.unauthorized)),
    );
    expect(gateway.reads, 0);
    expect(gateway.writes, 0);
  });

  test('inspect freezes trusted owner, Program, name and revision', () async {
    final gateway = _Gateway();
    final target = await _target(gateway.repo());
    expect(gateway.reads, 1);
    expect(gateway.lastOwner, _owner);
    expect(gateway.lastRoutine, _routine.value);
    expect(target.ownerId, _owner);
    expect(target.programId, _program);
    expect(target.expectedRevision, 4);
    expect(target.name, 'Routine 1');
    expect(gateway.writes, 0, reason: 'Preview/cancel cannot write');
  });

  test('inspect rejects wrong Program and malformed/foreign owner rows',
      () async {
    final gateway = _Gateway();
    final repository = gateway.repo();
    expect(await repository.inspect(
        programId: _otherProgram, routineId: _routine), isNull);
    gateway.row = _header(owner: _other);
    await expectLater(_target(repository),
        throwsA(_failure(RoutineDeleteFailureKind.malformedData)));
    gateway.row = _header()..['composition_revision'] = '4';
    await expectLater(_target(repository),
        throwsA(_failure(RoutineDeleteFailureKind.malformedData)));
    expect(gateway.writes, 0);
  });

  for (final entry in <(String, String, RoutineDeleteFailureKind)>[
    ('28000', 'routine_delete_not_authenticated',
        RoutineDeleteFailureKind.unauthorized),
    ('42501', 'permission denied', RoutineDeleteFailureKind.forbidden),
    ('P0002', 'routine_delete_not_found',
        RoutineDeleteFailureKind.notFound),
    ('P0001', 'routine_delete_revision_conflict',
        RoutineDeleteFailureKind.revisionConflict),
    ('22023', 'invalid_routine_delete_request',
        RoutineDeleteFailureKind.invalidRequest),
    ('PGRST202', 'RPC missing', RoutineDeleteFailureKind.unavailable),
  ]) {
    test('definite Delete ${entry.$1} maps without retry or reconciliation',
        () async {
      final gateway = _Gateway()
        ..onDelete = () async => throw PostgrestException(
              message: entry.$2, code: entry.$1);
      final repository = gateway.repo();
      final target = await _target(repository);
      await expectLater(repository.delete(target),
          throwsA(_failure(entry.$3)));
      expect(gateway.writes, 1);
      expect(gateway.reads, 1);
    });
  }

  for (final entry in <(String, int, RoutineDeleteFailureKind)>[
    ('23502', 400, RoutineDeleteFailureKind.invalidRequest),
    ('40P01', 500, RoutineDeleteFailureKind.transactionAborted),
    ('40001', 409, RoutineDeleteFailureKind.transactionAborted),
  ]) {
    test('real SDK PostgREST SQLSTATE ${entry.$1} is definite, not uncertain',
        () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://example.test',
        'synthetic-publishable-key',
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.method == 'GET') {
            return http.Response(jsonEncode(_header()), 200,
                headers: {'content-type': 'application/json'},
                request: request);
          }
          return http.Response(
            jsonEncode({
              'code': entry.$1,
              'message': 'definite postgres rollback',
              'details': null,
              'hint': null,
            }),
            entry.$2,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      addTearDown(client.dispose);
      final repository = SupabaseRoutineDeleteRepository(
        gateway: SupabaseRoutineDeleteGateway(client),
        currentUserId: () => _owner,
        currentLoginCycleId: () => _cycle,
      );
      final target = await _target(repository);
      await expectLater(repository.delete(target),
          throwsA(_failure(entry.$3)));
      expect(requests, hasLength(2),
          reason: 'no readback or automatic repeated DELETE after SQL abort');
      expect(requests.last.url.path,
          '/rest/v1/rpc/delete_user_workout_routine');
    });
  }

  test('definite rejection wins when login cycle changed mid-flight',
      () async {
    var cycle = _cycle;
    final gateway = _Gateway()
      ..onDelete = () async {
        cycle = 'new-cycle';
        throw const PostgrestException(
          message: 'routine_delete_revision_conflict', code: 'P0001');
      };
    final repo = gateway.repo(cycle: () => cycle);
    final target = await _target(repo);
    await expectLater(repo.delete(target),
        throwsA(_failure(RoutineDeleteFailureKind.revisionConflict)));
    expect(gateway.writes, 1);
    expect(gateway.reads, 1);
  });

  test('true RPC response after owner switch is NOT confirmed', () async {
    var owner = _owner;
    final gateway = _Gateway()
      ..onDelete = () async {
        owner = _other;
        return true;
      };
    final repo = gateway.repo(owner: () => owner);
    final target = await _target(repo);
    await expectLater(repo.delete(target),
        throwsA(_unknown(RoutineDeleteUncertainty.sessionChanged)));
    expect(gateway.reads, 1, reason: 'Never read old user under new auth');
    expect(gateway.writes, 1);
  });

  test('same-user new login cycle revokes RPC outcome', () async {
    var cycle = _cycle;
    final gateway = _Gateway()
      ..onDelete = () async {
        cycle = 'new-cycle';
        return true;
      };
    final repo = gateway.repo(cycle: () => cycle);
    final target = await _target(repo);
    await expectLater(repo.delete(target),
        throwsA(_unknown(RoutineDeleteUncertainty.sessionChanged)));
    expect(gateway.writes, 1);
    expect(gateway.reads, 1);
  });

  test('ambiguous timeout plus absent read never claims successful Delete',
      () async {
    final gateway = _Gateway()
      ..onDelete = () async {
        // Simulated lost ACK after the owner Routine was deleted elsewhere.
        return await Future<Object?>.error(TimeoutException('timed out'));
      };
    final repo = gateway.repo();
    final target = await _target(repo);
    gateway.row = null;
    await expectLater(repo.delete(target),
        throwsA(_unknown(RoutineDeleteUncertainty.absentOnRead)));
    expect(gateway.reads, 2);
    expect(gateway.writes, 1);
    await expectLater(repo.delete(target),
        throwsA(_unknown(RoutineDeleteUncertainty.unconfirmed)));
    expect(gateway.writes, 1);
  });

  test('unknown 5xx with still-present Routine is frozen until re-inspected',
      () async {
    final gateway = _Gateway()
      ..onDelete = () async => throw const PostgrestException(
          message: 'Server unavailable', code: '503');
    final repository = gateway.repo();
    final target = await _target(repository);
    gateway.row = _header(program: _otherProgram, revision: 5);
    await expectLater(
      repository.delete(target),
      throwsA(isA<RoutineDeleteOutcomeUnknown>()
          .having((e) => e.reason, 'reason',
              RoutineDeleteUncertainty.stillPresent)
          .having((e) => e.observedRevision, 'revision', 5)
          .having((e) => e.observedProgramId, 'program', _otherProgram)),
    );
    await expectLater(repository.delete(target),
        throwsA(_unknown(RoutineDeleteUncertainty.unconfirmed)));
    expect(gateway.writes, 1);
    expect(await repository.inspect(
        programId: _program, routineId: _routine), isNull);
    // A fresh, explicitly confirmed target in the NEW Program can replace
    // the frozen old action; no old-Program delete is silently retried.
    final moved = (await repository.inspect(
        programId: _otherProgram, routineId: _routine))!;
    expect(moved.expectedRevision, 5);
    expect(moved.programId, _otherProgram);
  });

  test('timed-out server call stays blocked on same-revision read',
      () async {
    // Dart's timeout does NOT cancel the underlying database request.
    final server = Completer<Object?>();
    final gateway = _Gateway()..onDelete = () => server.future;
    final repository = gateway.repo(
      timeout: const Duration(milliseconds: 25),
    );
    final original = await _target(repository);
    await expectLater(repository.delete(original),
        throwsA(_unknown(RoutineDeleteUncertainty.stillPresent)));
    expect(server.isCompleted, false);
    expect(gateway.writes, 1);

    // This read can race the still-running server Delete. It must NOT
    // unlock a second irreversible RPC at the original CAS revision.
    final sameRevision = await _target(repository);
    expect(sameRevision.expectedRevision, original.expectedRevision);
    await expectLater(repository.delete(sameRevision),
        throwsA(_unknown(RoutineDeleteUncertainty.unconfirmed)));
    expect(gateway.writes, 1);

    // Late server completion does not retroactively resolve the client ACK.
    server.complete(true);
    await expectLater(repository.delete(sameRevision),
        throwsA(_unknown(RoutineDeleteUncertainty.unconfirmed)));
    expect(gateway.writes, 1);

    // A strictly newer committed revision proves the old CAS cannot delete.
    gateway.row = _header(revision: 5);
    final changed = await _target(repository);
    expect(changed.expectedRevision, 5);
    gateway.onDelete = () async => true;
    await expectLater(repository.delete(original),
        throwsA(_failure(RoutineDeleteFailureKind.revisionConflict)));
    expect(gateway.writes, 1);
    expect(await repository.delete(changed), RoutineDeleteResult.confirmed);
    expect(gateway.writes, 2);
  });

  test('absent or older owner read never clears uncertain Delete guard',
      () async {
    final gateway = _Gateway()
      ..onDelete = () async => throw TimeoutException('lost ack');
    final repository = gateway.repo();
    await expectLater(repository.delete(await _target(repository)),
        throwsA(_unknown(RoutineDeleteUncertainty.stillPresent)));
    gateway.row = null;
    expect(await repository.inspect(
        programId: _program, routineId: _routine), isNull);
    gateway.row = _header(revision: 3);
    final old = await _target(repository);
    await expectLater(repository.delete(old),
        throwsA(_unknown(RoutineDeleteUncertainty.unconfirmed)));
    expect(gateway.writes, 1);
  });

  test('definite rejected Delete consumes target until a fresh inspect',
      () async {
    final gateway = _Gateway()
      ..onDelete = () async => throw const PostgrestException(
            message: 'permission denied', code: '42501');
    final repository = gateway.repo();
    final first = await _target(repository);
    await expectLater(repository.delete(first),
        throwsA(_failure(RoutineDeleteFailureKind.forbidden)));
    expect(gateway.writes, 1);

    // Same frozen object can never dispatch a second RPC, even though
    // the read revision and authentication are unchanged.
    await expectLater(repository.delete(first),
        throwsA(_failure(RoutineDeleteFailureKind.staleTarget)));
    expect(gateway.writes, 1);

    final second = await _target(repository);
    expect(second.expectedRevision, first.expectedRevision);
    gateway.onDelete = () async => true;
    expect(await repository.delete(second), RoutineDeleteResult.confirmed);
    expect(gateway.writes, 2);
    await expectLater(repository.delete(second),
        throwsA(_failure(RoutineDeleteFailureKind.staleTarget)));
    expect(gateway.writes, 2);
  });

  test('ambiguous Delete stays guarded across same-owner relogin',
      () async {
    var cycle = _cycle;
    final pendingServer = Completer<Object?>();
    final gateway = _Gateway()..onDelete = () => pendingServer.future;
    final repository = gateway.repo(
      cycle: () => cycle,
      timeout: const Duration(milliseconds: 25),
    );
    final cycleA = await _target(repository);
    await expectLater(repository.delete(cycleA),
        throwsA(_unknown(RoutineDeleteUncertainty.stillPresent)));
    expect(pendingServer.isCompleted, false);
    expect(gateway.writes, 1);

    // The SDK's timed-out request may remain active with the old JWT.
    cycle = 'cycle-two';
    final cycleB = await _target(repository);
    expect(cycleB.expectedRevision, cycleA.expectedRevision);
    await expectLater(repository.delete(cycleB),
        throwsA(_unknown(RoutineDeleteUncertainty.unconfirmed)));
    expect(gateway.writes, 1);
    pendingServer.complete(true);
    await expectLater(repository.delete(cycleB),
        throwsA(_unknown(RoutineDeleteUncertainty.unconfirmed)));
    expect(gateway.writes, 1);

    gateway.row = _header(revision: 5);
    final newer = await _target(repository);
    expect(newer.expectedRevision, 5);
    gateway.onDelete = () async => true;
    await expectLater(repository.delete(cycleB),
        throwsA(_failure(RoutineDeleteFailureKind.staleTarget)));
    expect(gateway.writes, 1);
    expect(await repository.delete(newer), RoutineDeleteResult.confirmed);
    expect(gateway.writes, 2);
  });

  test('reconciliation read failure remains unknown; never fake absence',
      () async {
    final gateway = _Gateway()
      ..onDelete = () async => throw TimeoutException('offline');
    final repository = gateway.repo();
    final target = await _target(repository);
    gateway.readError = TimeoutException('read offline');
    await expectLater(repository.delete(target),
        throwsA(_unknown(RoutineDeleteUncertainty.unconfirmed)));
    expect(gateway.writes, 1);
    await expectLater(repository.delete(target),
        throwsA(_unknown(RoutineDeleteUncertainty.unconfirmed)));
    expect(gateway.writes, 1);
  });

  test('login cycle switch during readback never confirms old-owner outcome',
      () async {
    var cycle = _cycle;
    final gateway = _Gateway()
      ..onDelete = () async => throw TimeoutException('lost Delete ACK');
    gateway.onRead = () async {
      // The first owner read prepares the target; the second is readback
      // while the user's login cycle is revoked.
      if (gateway.reads == 2) cycle = 'replacement-cycle';
      return _header();
    };
    final repository = gateway.repo(cycle: () => cycle);
    final target = await _target(repository);
    await expectLater(repository.delete(target),
        throwsA(_unknown(RoutineDeleteUncertainty.sessionChanged)));
    expect(gateway.reads, 2);
    expect(gateway.writes, 1);
    // A frozen target from the old login cycle cannot be dispatched again.
    await expectLater(repository.delete(target),
        throwsA(_failure(RoutineDeleteFailureKind.unauthorized)));
    expect(gateway.writes, 1);
  });

  test('malformed successful response readback still-present is unknown',
      () async {
    final gateway = _Gateway()
      ..onDelete = () async => false;
    final repository = gateway.repo();
    final target = await _target(repository);
    await expectLater(repository.delete(target),
        throwsA(_unknown(RoutineDeleteUncertainty.stillPresent)));
    expect(gateway.reads, 2);
    expect(gateway.writes, 1);
  });

  test('concurrent Delete for same Routine makes only one RPC', () async {
    final completer = Completer<Object?>();
    final gateway = _Gateway()
      ..onDelete = () => completer.future;
    final repository = gateway.repo();
    final target = await _target(repository);
    final first = repository.delete(target);
    await expectLater(repository.delete(target),
        throwsA(_failure(RoutineDeleteFailureKind.inProgress)));
    expect(gateway.writes, 1);
    completer.complete(true);
    expect(await first, RoutineDeleteResult.confirmed);
    expect(gateway.writes, 1);
  });
}

final class _Gateway implements RoutineDeleteGateway {
  Map<String, dynamic>? row = _header();
  Future<Object?> Function()? onDelete;
  Future<Map<String, dynamic>?> Function()? onRead;
  Object? readError;
  int reads = 0;
  int writes = 0;
  String? lastOwner;
  String? lastRoutine;

  SupabaseRoutineDeleteRepository repo({
    String? Function()? owner,
    String? Function()? cycle,
    Duration timeout = const Duration(seconds: 15),
  }) => SupabaseRoutineDeleteRepository(
    gateway: this,
    currentUserId: owner ?? () => _owner,
    currentLoginCycleId: cycle ?? () => _cycle,
    timeout: timeout,
  );

  @override
  Future<Map<String, dynamic>?> readOwnedHeader({
    required String userId,
    required String routineId,
  }) async {
    reads++;
    lastOwner = userId;
    lastRoutine = routineId;
    if (readError != null) throw readError!;
    if (onRead != null) return await onRead!();
    return row;
  }

  @override
  Future<Object?> delete({
    required String routineId,
    required String programId,
    required int expectedRevision,
  }) async {
    writes++;
    return await (onDelete?.call() ?? Future<Object?>.value(true));
  }
}
