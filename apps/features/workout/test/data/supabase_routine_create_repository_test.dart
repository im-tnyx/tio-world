import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

void main() {
  test('real SDK calls one atomic Create RPC and preserves default Set 1',
      () async {
    final requests = <http.Request>[];
    final client = SupabaseClient('https://example.test',
      'synthetic-publishable-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response('1', 200,
          headers: {'content-type': 'application/json'}, request: request);
      }),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    addTearDown(client.dispose);
    final repository = SupabaseRoutineCreateRepository(
      client: client,
      currentUserId: () => '11111111-1111-4111-8111-111111111111',
    );
    final request = RoutineCreateCommand(
      routine: Routine(
        id: RoutineId('22222222-2222-4222-8222-222222222222'),
        programId: ProgramId('11111111-1111-4111-8111-111111111111'),
        name: 'Routine 1',
      ),
      mutationId: '33333333-3333-4333-8333-333333333333',
      entries: [
        RoutineCompositionEntry(
          id: '44444444-4444-4444-8444-444444444444',
          exercise: ExerciseRef.catalog('ex_bench_press'),
          sets: [RoutineCompositionSet(
            id: '55555555-5555-4555-8555-555555555555',
            prescription: SetPrescription(),
          )],
        ),
      ],
    );
    expect(await repository.create(request), 1);
    expect(requests, hasLength(1));
    expect(requests.single.method, 'POST');
    expect(requests.single.url.path,
        '/rest/v1/rpc/create_user_workout_routine_with_composition');
    expect(jsonDecode(requests.single.body), {
      'p_routine_id': request.routine.id.value,
      'p_program_id': request.routine.programId.value,
      'p_name': 'Routine 1',
      'p_client_mutation_id': request.mutationId,
      'p_exercises': [
        {
          'id': request.entries.single.id,
          'exercise_ref': 'ex_bench_press',
          'sets': [
            {
              'id': request.entries.single.sets.single.id,
              'reps': null,
              'reps_max': null,
              'set_type': 'normal',
              'load_kg': null,
              'distance_meters': null,
              'duration_seconds': null,
              'rest_seconds': null,
            }
          ],
        }
      ],
    });
  });

  for (final code in ['PGRST301', 'PGRST302', 'PGRST303', '28P01']) {
    test('definite Create Auth $code remains retryable, not uncertain', () async {
      var requests = 0;
      final client = SupabaseClient(
        'https://example.test', 'synthetic-publishable-key',
        httpClient: MockClient((request) async {
          requests++;
          return http.Response(
            jsonEncode({'code': code, 'message': 'Authentication rejected'}),
            401,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      addTearDown(client.dispose);
      final repo = SupabaseRoutineCreateRepository(
        client: client,
        currentUserId: () => '11111111-1111-4111-8111-111111111111',
      );
      await expectLater(
        repo.create(_testCreateCommand()),
        throwsA(isA<RoutineCompositionException>().having(
          (e) => e.kind, 'kind', RoutineCompositionFailureKind.unauthorized,
        )),
      );
      expect(requests, 1); // Never issue an automatic second Create.
    });
  }


  for (final status in [400, 404, 409, 422, 429]) {
    test('HTTP $status Create rejection is definite and does not retry',
        () async {
      var requests = 0;
      final client = SupabaseClient(
        'https://example.test', 'synthetic-publishable-key',
        httpClient: MockClient((request) async {
          requests++;
          return http.Response(
            jsonEncode({'code': '$status', 'message': 'Request rejected'}),
            status,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      addTearDown(client.dispose);
      final repo = SupabaseRoutineCreateRepository(
        client: client,
        currentUserId: () => '11111111-1111-4111-8111-111111111111',
      );
      await expectLater(
        repo.create(_testCreateCommand()),
        throwsA(isA<RoutineCompositionException>().having(
          (e) => e.kind, 'kind',
          RoutineCompositionFailureKind.invalidRequest,
        )),
      );
      expect(requests, 1);
    });
  }

  test('PGRST203 overload ambiguity is a definite pre-execution rejection',
      () async {
    var requests = 0;
    final client = SupabaseClient(
      'https://example.test', 'synthetic-publishable-key',
      httpClient: MockClient((request) async {
        requests++;
        return http.Response(
          jsonEncode({
            'code': 'PGRST203',
            'message': 'RPC overload is ambiguous',
          }),
          300,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    addTearDown(client.dispose);
    final repo = SupabaseRoutineCreateRepository(
      client: client,
      currentUserId: () => '11111111-1111-4111-8111-111111111111',
    );
    await expectLater(
      repo.create(_testCreateCommand()),
      throwsA(isA<RoutineCompositionException>().having(
        (e) => e.kind, 'kind',
        RoutineCompositionFailureKind.invalidRequest,
      )),
    );
    expect(requests, 1, reason: 'Never retry an atomic Create automatically');
  });

  test('uncertain Create server error keeps frozen-mutation outcome', () async {
    var requests = 0;
    final client = SupabaseClient(
      'https://example.test', 'synthetic-publishable-key',
      httpClient: MockClient((request) async {
        requests++;
        return http.Response(
          jsonEncode({'code': 'XX000', 'message': 'Server failure'}),
          500,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    addTearDown(client.dispose);
    final repo = SupabaseRoutineCreateRepository(
      client: client,
      currentUserId: () => '11111111-1111-4111-8111-111111111111',
    );
    await expectLater(
      repo.create(_testCreateCommand()),
      throwsA(isA<RoutineCompositionSaveOutcomeUnknown>()),
    );
    expect(requests, 1);
  });

}

RoutineCreateCommand _testCreateCommand() => RoutineCreateCommand(
  routine: Routine(
    id: RoutineId('22222222-2222-4222-8222-222222222222'),
    programId: ProgramId('11111111-1111-4111-8111-111111111111'),
    name: 'Routine 1',
  ),
  mutationId: '33333333-3333-4333-8333-333333333333',
  entries: [
    RoutineCompositionEntry(
      id: '44444444-4444-4444-8444-444444444444',
      exercise: ExerciseRef.catalog('ex_bench_press'),
      sets: [
        RoutineCompositionSet(
          id: '55555555-5555-4555-8555-555555555555',
          prescription: SetPrescription(),
        ),
      ],
    ),
  ],
);
