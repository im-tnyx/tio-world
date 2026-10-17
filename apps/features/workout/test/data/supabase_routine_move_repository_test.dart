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
  int reads = 0, writes = 0;
  Future<Object?> Function()? onMove;
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
}

SupabaseRoutineMoveRepository repo(
  FakeMoveGateway gateway, {
  RoutineMoveAttemptGate? gate,
  String? Function()? user,
  String? Function()? loginCycle,
  Duration timeout = const Duration(seconds: 15),
}) => SupabaseRoutineMoveRepository(
  gateway: gateway, attemptGate: gate ?? RoutineMoveAttemptGate(),
  currentUserId: user ?? () => owner,
  currentLoginCycleId: loginCycle ?? () => cycle,
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
