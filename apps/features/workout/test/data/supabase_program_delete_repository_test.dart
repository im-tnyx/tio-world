import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _owner = '11111111-1111-4111-8111-111111111111';
const _otherOwner = '99999999-9999-4999-8999-999999999999';
const _cycle = 'cycle-one';
final _source = ProgramId('22222222-2222-4222-8222-222222222222');
final _destination = ProgramId('33333333-3333-4333-8333-333333333333');
final _routineOne = RoutineId('44444444-4444-4444-8444-444444444444');
final _routineTwo = RoutineId('55555555-5555-4555-8555-555555555555');
const _mutation = '66666666-6666-4666-8666-666666666666';

ProgramDeleteTarget _target({
  String owner = _owner,
  String cycle = _cycle,
  Iterable<RoutineId> routines = const [],
}) =>
    ProgramDeleteTarget(
      sourceProgramId: _source,
      expectedRoutineIds: routines,
      ownerId: owner,
      loginCycleId: cycle,
    );

Map<String, dynamic> _success({
  int moved = 0,
  ProgramId? destination,
}) =>
    {
      'deleted_program_id': _source.value,
      'destination_program_id': destination?.value,
      'moved_routine_count': moved,
    };

Matcher _failure(ProgramDeleteFailureKind kind) =>
    isA<ProgramDeleteException>().having((error) => error.kind, 'kind', kind);

Matcher _unknown(ProgramDeleteUncertainty reason) =>
    isA<ProgramDeleteOutcomeUnknown>()
        .having((error) => error.reason, 'reason', reason);

SupabaseProgramDeleteRepository _repository(
  _FakeProgramDeleteGateway gateway, {
  String? Function()? owner,
  String? Function()? cycle,
  Duration timeout = const Duration(seconds: 15),
}) =>
    SupabaseProgramDeleteRepository(
      gateway: gateway,
      attemptGate: gateway.attemptGate,
      currentUserId: owner ?? () => _owner,
      currentLoginCycleId: cycle ?? () => _cycle,
      timeout: timeout,
    );

void main() {
  test('sends the exact D1 RPC contract and validates committed success',
      () async {
    final requests = <http.Request>[];
    final client = SupabaseClient(
      'https://example.test',
      'synthetic-publishable-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode(_success(moved: 2, destination: _destination)),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    addTearDown(client.dispose);

    final repository = SupabaseProgramDeleteRepository(
      gateway: SupabaseProgramDeleteGateway(client),
      attemptGate: ProgramDeleteAttemptGate(),
      currentUserId: () => _owner,
      currentLoginCycleId: () => _cycle,
    );
    final result = await repository.delete(
      target: _target(routines: [_routineOne, _routineTwo]),
      clientMutationId: _mutation,
    );

    expect(result.deletedProgramId, _source);
    expect(result.destinationProgramId, _destination);
    expect(result.movedRoutineCount, 2);
    expect(requests, hasLength(1));
    expect(requests.single.method, 'POST');
    expect(requests.single.url.path,
        '/rest/v1/rpc/delete_user_workout_program_preserving_routines');
    expect(jsonDecode(requests.single.body), {
      'p_source_program_id': _source.value,
      'p_expected_routine_ids': [_routineOne.value, _routineTwo.value],
      'p_client_mutation_id': _mutation,
    });
  });

  test('versioned source snapshots reject wrong Program, cycle and duplicates',
      () {
    final routine = Routine(
      id: _routineOne,
      programId: _source,
      name: 'Routine 1',
    );
    final snapshot = RoutineMetadataRevision(
      routine: routine,
      revision: 4,
      loginCycleId: _cycle,
    );
    final target = ProgramDeleteTarget.fromVersionedRoutines(
      sourceProgramId: _source,
      routines: [snapshot],
      ownerId: _owner,
      loginCycleId: _cycle,
    );
    expect(target.expectedRoutineIds, [_routineOne]);

    expect(
      () => ProgramDeleteTarget.fromVersionedRoutines(
        sourceProgramId: _destination,
        routines: [snapshot],
        ownerId: _owner,
        loginCycleId: _cycle,
      ),
      throwsArgumentError,
    );
    expect(
      () => ProgramDeleteTarget.fromVersionedRoutines(
        sourceProgramId: _source,
        routines: [snapshot],
        ownerId: _owner,
        loginCycleId: 'replacement-cycle',
      ),
      throwsArgumentError,
    );
    expect(
      () => _target(routines: [_routineOne, _routineOne]),
      throwsArgumentError,
    );
  });

  test('wrong account, logout and invalid mutation fail before RPC', () async {
    final gateway = _FakeProgramDeleteGateway();
    final wrongAccount = _repository(gateway, owner: () => _otherOwner);
    await expectLater(
      wrongAccount.delete(target: _target(), clientMutationId: _mutation),
      throwsA(_failure(ProgramDeleteFailureKind.unauthorized)),
    );

    final signedOut = _repository(gateway, owner: () => null);
    await expectLater(
      signedOut.delete(target: _target(), clientMutationId: _mutation),
      throwsA(_failure(ProgramDeleteFailureKind.unauthorized)),
    );

    final invalidMutation = _repository(gateway);
    await expectLater(
      invalidMutation.delete(target: _target(), clientMutationId: 'bad'),
      throwsA(_failure(ProgramDeleteFailureKind.invalidRequest)),
    );
    expect(gateway.writes, 0);
  });

  for (final entry in <(String, String, ProgramDeleteFailureKind)>[
    (
      '42501',
      'permission denied',
      ProgramDeleteFailureKind.permissionUnavailable
    ),
    (
      'PGRST202',
      'function not found',
      ProgramDeleteFailureKind.permissionUnavailable
    ),
    (
      'P0001',
      'program_delete_default_forbidden',
      ProgramDeleteFailureKind.defaultProtected
    ),
    (
      'P0001',
      'program_delete_membership_conflict',
      ProgramDeleteFailureKind.staleMembership
    ),
  ]) {
    test('${entry.$2} is definite and never retried', () async {
      final gateway = _FakeProgramDeleteGateway()
        ..onDelete = () async => throw PostgrestException(
              message: entry.$2,
              code: entry.$1,
            );
      final repository = _repository(gateway);
      final target = _target(routines: [_routineOne]);

      await expectLater(
        repository.delete(target: target, clientMutationId: _mutation),
        throwsA(_failure(entry.$3)),
      );
      await expectLater(
        repository.delete(target: target, clientMutationId: _mutation),
        throwsA(_failure(ProgramDeleteFailureKind.staleMembership)),
      );
      expect(gateway.writes, 1);
    });
  }

  test(
      'successful response with wrong identity/count is UNKNOWN, not rejection',
      () async {
    final gateway = _FakeProgramDeleteGateway()
      ..onDelete = () async => {
            'deleted_program_id': _destination.value,
            'destination_program_id': null,
            'moved_routine_count': 0,
          };
    final repository = _repository(gateway);
    final target = _target(routines: [_routineOne]);

    await expectLater(
      repository.delete(target: target, clientMutationId: _mutation),
      throwsA(_unknown(ProgramDeleteUncertainty.malformedResponse)),
    );
    await expectLater(
      repository.delete(target: target, clientMutationId: _mutation),
      throwsA(_unknown(ProgramDeleteUncertainty.unconfirmed)),
    );
    expect(gateway.writes, 1);
  });

  test('empty Program accepts an existing canonical default destination',
      () async {
    final gateway = _FakeProgramDeleteGateway()
      ..onDelete = () async => _success(destination: _destination);
    final repository = _repository(gateway);

    final result = await repository.delete(
      target: _target(),
      clientMutationId: _mutation,
    );

    expect(result.deletedProgramId, _source);
    expect(result.destinationProgramId, _destination);
    expect(result.movedRoutineCount, 0);
    expect(gateway.writes, 1);
  });

  test('empty Program accepts a null destination when no default exists',
      () async {
    final gateway = _FakeProgramDeleteGateway()
      ..onDelete = () async => _success();
    final repository = _repository(gateway);

    final result = await repository.delete(
      target: _target(),
      clientMutationId: _mutation,
    );

    expect(result.destinationProgramId, isNull);
    expect(result.movedRoutineCount, 0);
    expect(gateway.writes, 1);
  });

  test('definite rejection allows only a fresh target and mutation', () async {
    var calls = 0;
    final gateway = _FakeProgramDeleteGateway()
      ..onDelete = () async {
        if (calls++ == 0) {
          throw const PostgrestException(
            message: 'program_delete_membership_conflict',
            code: 'P0001',
          );
        }
        return _success(moved: 2, destination: _destination);
      };
    final repository = _repository(gateway);
    final firstTarget = _target(routines: [_routineOne]);

    await expectLater(
      repository.delete(target: firstTarget, clientMutationId: _mutation),
      throwsA(_failure(ProgramDeleteFailureKind.staleMembership)),
    );
    await expectLater(
      repository.delete(target: firstTarget, clientMutationId: _mutation),
      throwsA(_failure(ProgramDeleteFailureKind.staleMembership)),
    );
    await expectLater(
      repository.delete(
        target: firstTarget,
        clientMutationId: '77777777-7777-4777-8777-777777777777',
      ),
      throwsA(_failure(ProgramDeleteFailureKind.staleMembership)),
    );

    final refreshedTarget = _target(routines: [_routineOne, _routineTwo]);
    final result = await repository.delete(
      target: refreshedTarget,
      clientMutationId: '88888888-8888-4888-8888-888888888888',
    );
    expect(result.movedRoutineCount, 2);
    expect(gateway.writes, 2);
  });

  test('all definite rejection attempts remain consumed', () async {
    var calls = 0;
    final gateway = _FakeProgramDeleteGateway()
      ..onDelete = () async {
        calls++;
        if (calls <= 2) {
          throw const PostgrestException(
            message: 'program_delete_membership_conflict',
            code: 'P0001',
          );
        }
        return _success();
      };
    final repository = _repository(gateway);
    final firstTarget = _target(routines: [_routineOne]);
    final secondTarget = _target(routines: [_routineOne, _routineTwo]);

    await expectLater(
      repository.delete(target: firstTarget, clientMutationId: _mutation),
      throwsA(_failure(ProgramDeleteFailureKind.staleMembership)),
    );
    await expectLater(
      repository.delete(
        target: secondTarget,
        clientMutationId: '77777777-7777-4777-8777-777777777777',
      ),
      throwsA(_failure(ProgramDeleteFailureKind.staleMembership)),
    );
    await expectLater(
      repository.delete(
        target: _target(routines: [_routineOne]),
        clientMutationId: _mutation,
      ),
      throwsA(_failure(ProgramDeleteFailureKind.staleMembership)),
    );

    final result = await repository.delete(
      target: _target(),
      clientMutationId: '88888888-8888-4888-8888-888888888888',
    );
    expect(result.movedRoutineCount, 0);
    expect(gateway.writes, 3);
  });

  test('timeout stays UNKNOWN without a missing-source read or retry',
      () async {
    final gateway = _FakeProgramDeleteGateway()
      ..onDelete = () async => throw TimeoutException('lost ACK');
    final repository = _repository(gateway);
    final target = _target(routines: [_routineOne]);

    await expectLater(
      repository.delete(target: target, clientMutationId: _mutation),
      throwsA(_unknown(ProgramDeleteUncertainty.unconfirmed)),
    );
    await expectLater(
      repository.delete(target: target, clientMutationId: _mutation),
      throwsA(_unknown(ProgramDeleteUncertainty.unconfirmed)),
    );
    expect(gateway.writes, 1);
  });

  test('UNKNOWN blocks a fresh target and mutation without retry', () async {
    final gateway = _FakeProgramDeleteGateway()
      ..onDelete = () async => throw TimeoutException('lost ACK');
    final repository = _repository(gateway);

    await expectLater(
      repository.delete(
        target: _target(routines: [_routineOne]),
        clientMutationId: _mutation,
      ),
      throwsA(_unknown(ProgramDeleteUncertainty.unconfirmed)),
    );
    await expectLater(
      repository.delete(
        target: _target(routines: [_routineOne, _routineTwo]),
        clientMutationId: '77777777-7777-4777-8777-777777777777',
      ),
      throwsA(_unknown(ProgramDeleteUncertainty.unconfirmed)),
    );
    expect(gateway.writes, 1);
  });

  test('logout or account switch during a valid response is UNKNOWN', () async {
    var owner = _owner;
    var cycle = _cycle;
    final gateway = _FakeProgramDeleteGateway()
      ..onDelete = () async {
        owner = _otherOwner;
        cycle = 'replacement-cycle';
        return _success(moved: 0);
      };
    final repository = _repository(
      gateway,
      owner: () => owner,
      cycle: () => cycle,
    );

    await expectLater(
      repository.delete(target: _target(), clientMutationId: _mutation),
      throwsA(_unknown(ProgramDeleteUncertainty.sessionChanged)),
    );
    expect(gateway.writes, 1);
  });

  test('empty snapshot requires a null destination', () async {
    final gateway = _FakeProgramDeleteGateway();
    final repository = _repository(gateway);
    final result = await repository.delete(
      target: _target(),
      clientMutationId: _mutation,
    );
    expect(result.destinationProgramId, isNull);
    expect(result.movedRoutineCount, 0);

    // The adapter sends stable identity only; it never uses a Program name as
    // deletion authority. Server-side default protection is covered above.
    expect(gateway.lastSourceProgramId, _source.value);
  });

  test('concurrent requests for one Program are single-flight', () async {
    final server = Completer<Object?>();
    final gateway = _FakeProgramDeleteGateway()..onDelete = () => server.future;
    final repository = _repository(gateway);
    final target = _target(routines: [_routineOne]);

    final first = repository.delete(
      target: target,
      clientMutationId: _mutation,
    );
    await expectLater(
      repository.delete(
        target: _target(routines: [_routineTwo]),
        clientMutationId: '77777777-7777-4777-8777-777777777777',
      ),
      throwsA(_failure(ProgramDeleteFailureKind.inProgress)),
    );
    expect(gateway.writes, 1);

    server.complete(_success(moved: 1, destination: _destination));
    await first;
    expect(gateway.writes, 1);
  });
}

final class _FakeProgramDeleteGateway implements ProgramDeleteGateway {
  final ProgramDeleteAttemptGate attemptGate = ProgramDeleteAttemptGate();
  Future<Object?> Function()? onDelete;
  int writes = 0;
  String? lastSourceProgramId;

  @override
  Future<Object?> delete({
    required String sourceProgramId,
    required List<String> expectedRoutineIds,
    required String clientMutationId,
  }) async {
    writes++;
    lastSourceProgramId = sourceProgramId;
    return await (onDelete?.call() ?? Future<Object?>.value(_success()));
  }
}
