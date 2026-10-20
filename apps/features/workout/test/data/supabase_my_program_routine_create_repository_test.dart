import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _owner = '11111111-1111-4111-8111-111111111111';
const _routine = '22222222-2222-4222-8222-222222222222';
const _mutation = '33333333-3333-4333-8333-333333333333';
const _entry = '44444444-4444-4444-8444-444444444444';
const _set = '55555555-5555-4555-8555-555555555555';

MyProgramRoutineCreateCommand _command({String name = 'Routine 1'}) =>
    MyProgramRoutineCreateCommand(
      routineId: RoutineId(_routine),
      name: name,
      mutationId: _mutation,
      entries: [
        RoutineCompositionEntry(
          id: _entry,
          exercise: ExerciseRef.catalog('ex_bench_press'),
          sets: [
            RoutineCompositionSet(
              id: _set,
              prescription: SetPrescription(reps: 1),
            ),
          ],
        ),
      ],
    );

SupabaseClient _client(
    Future<http.Response> Function(http.Request) respond) =>
    SupabaseClient(
      'https://example.test',
      'synthetic-publishable-key',
      httpClient: MockClient(respond),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );

void main() {
  test('programless RPC sends frozen composition and parses server identity',
      () async {
    final requests = <http.Request>[];
    final client = _client((request) async {
      requests.add(request);
      return http.Response(
        jsonEncode({'program_id': _owner, 'composition_revision': 1}),
        200,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    });
    addTearDown(client.dispose);
    final repo = SupabaseMyProgramRoutineCreateRepository(
      client: client,
      currentUserId: () => _owner,
    );
    final cmd = _command(name: '  Routine 1  ');
    final result = await repo.createInMyProgram(cmd);
    expect(result.programId, ProgramId(_owner));
    expect(result.compositionRevision, 1);
    expect(requests, hasLength(1));
    expect(requests.single.method, 'POST');
    expect(requests.single.url.path,
        '/rest/v1/rpc/create_user_workout_routine_in_my_program');

    final sent = jsonDecode(requests.single.body) as Map<String, dynamic>;
    expect(sent.keys.toSet(), {
      'p_routine_id', 'p_name', 'p_client_mutation_id', 'p_exercises',
    });
    expect(sent, isNot(contains('p_program_id')));
    expect(sent['p_routine_id'], _routine);
    expect(sent['p_name'], 'Routine 1');
    expect(sent['p_client_mutation_id'], _mutation);
    final entries = sent['p_exercises'] as List<dynamic>;
    expect(entries, hasLength(1));
    final entry = entries.single as Map<String, dynamic>;
    expect(entry['id'], _entry);
    expect(entry['exercise_ref'], 'ex_bench_press');
    final set = (entry['sets'] as List<dynamic>).single
        as Map<String, dynamic>;
    expect(set['id'], _set);
    expect(set['reps'], 1);
  });

  test('signed-out attempt fails before I/O', () async {
    var requests = 0;
    final client = _client((request) async {
      requests++;
      return http.Response('{}', 200, request: request);
    });
    addTearDown(client.dispose);
    final repo = SupabaseMyProgramRoutineCreateRepository(
      client: client,
      currentUserId: () => null,
    );
    await expectLater(
      repo.createInMyProgram(_command()),
      throwsA(isA<RoutineCompositionException>().having(
          (e) => e.kind, 'kind',
          RoutineCompositionFailureKind.unauthorized)),
    );
    expect(requests, 0);
  });

  test('account switch after committed ACK is UNKNOWN', () async {
    var owner = _owner;
    var requests = 0;
    final client = _client((request) async {
      requests++;
      owner = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
      return http.Response(
        jsonEncode({'program_id': _owner, 'composition_revision': 1}),
        200,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    });
    addTearDown(client.dispose);
    final repo = SupabaseMyProgramRoutineCreateRepository(
      client: client, currentUserId: () => owner);
    await expectLater(
      repo.createInMyProgram(_command()),
      throwsA(isA<RoutineCompositionSaveOutcomeUnknown>().having(
          (e) => e.reason, 'reason',
          RoutineCompositionSaveUncertainty.authChanged)),
    );
    expect(requests, 1);
  });

  for (final (code, status, kind) in [
    ('42501', 403, RoutineCompositionFailureKind.forbidden),
    ('22023', 400, RoutineCompositionFailureKind.invalidRequest),
    ('25001', 400, RoutineCompositionFailureKind.invalidRequest),
    ('PGRST202', 404, RoutineCompositionFailureKind.invalidRequest),
    ('PGRST301', 401, RoutineCompositionFailureKind.unauthorized),
  ]) {
    test('known rejection $code is definite, never retried', () async {
      var owner = _owner;
      var requests = 0;
      final client = _client((request) async {
        requests++;
        // A definite rollback is still definite after a client auth change.
        owner = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
        return http.Response(
          jsonEncode({'code': code, 'message': 'Rejected'}),
          status,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      });
      addTearDown(client.dispose);
      final repo = SupabaseMyProgramRoutineCreateRepository(
        client: client, currentUserId: () => owner);
      await expectLater(
        repo.createInMyProgram(_command()),
        throwsA(isA<RoutineCompositionException>().having(
            (e) => e.kind, 'kind', kind)),
      );
      expect(requests, 1);
    });
  }

  for (final badPayload in [
    {'program_id': _owner, 'composition_revision': 2},
    {'program_id': 'not-a-uuid', 'composition_revision': 1},
    {'program_id': _owner},
    1,
    null,
  ]) {
    test('malformed RPC ACK $badPayload is UNKNOWN', () async {
      var requests = 0;
      final client = _client((request) async {
        requests++;
        return http.Response(
          jsonEncode(badPayload),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      });
      addTearDown(client.dispose);
      final repo = SupabaseMyProgramRoutineCreateRepository(
        client: client, currentUserId: () => _owner);
      await expectLater(repo.createInMyProgram(_command()),
          throwsA(isA<RoutineCompositionSaveOutcomeUnknown>()));
      expect(requests, 1);
    });
  }

  test('server 5xx remains UNKNOWN, never automatically replays write',
      () async {
    var requests = 0;
    final client = _client((request) async {
      requests++;
      return http.Response(
        jsonEncode({'code': 'XX000', 'message': 'Unknown server result'}),
        500,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    });
    addTearDown(client.dispose);
    final repo = SupabaseMyProgramRoutineCreateRepository(
      client: client, currentUserId: () => _owner);
    await expectLater(repo.createInMyProgram(_command()),
        throwsA(isA<RoutineCompositionSaveOutcomeUnknown>()));
    expect(requests, 1);
  });

  test('no name, exercise or duplicate Set identity can reach adapter', () {
    expect(() => _command(name: '  '), throwsArgumentError);
    expect(
      () => MyProgramRoutineCreateCommand(
        routineId: RoutineId(_routine),
        name: 'Test',
        mutationId: _mutation,
        entries: const [],
      ), throwsArgumentError,
    );
    expect(
      () => MyProgramRoutineCreateCommand(
        routineId: RoutineId(_routine),
        name: 'Test',
        mutationId: _mutation,
        entries: [
          RoutineCompositionEntry(
            id: _entry,
            exercise: ExerciseRef.catalog('ex_bench_press'),
            sets: [RoutineCompositionSet(
              id: _set, prescription: SetPrescription(reps: 1),
            )],
          ),
          RoutineCompositionEntry(
            id: '66666666-6666-4666-8666-666666666666',
            exercise: ExerciseRef.catalog('ex_bench_press'),
            sets: [RoutineCompositionSet(
              id: _set, prescription: SetPrescription(reps: 2),
            )],
          ),
        ],
      ), throwsArgumentError,
    );
  });

  test('confirmed persisted composition is evidence, not default ownership',
      () {
    final cmd = _command();
    final snapshot = RoutineCompositionSnapshot(
      routineId: cmd.routineId,
      revision: 1,
      lastMutationId: cmd.mutationId,
      entries: cmd.entries,
    );
    expect(cmd.confirmsPersistedRoutine(snapshot), isTrue);
    final mismatch = RoutineCompositionSnapshot(
      routineId: cmd.routineId,
      revision: 1,
      lastMutationId: 'ffffffff-ffff-4fff-8fff-ffffffffffff',
      entries: cmd.entries,
    );
    expect(cmd.confirmsPersistedRoutine(mismatch), isFalse);
  });
}
