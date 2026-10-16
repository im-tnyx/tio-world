import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _owner = '11111111-1111-1111-1111-111111111111';
const _routine = '22222222-2222-2222-2222-222222222222';
const _mutation = '33333333-3333-3333-3333-333333333333';
String _id(int i) =>
    '${i.toRadixString(16).padLeft(8, '0')}-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
Map<String, dynamic> _header() => {
      'id': _routine,
      'user_id': _owner,
      'composition_revision': 1,
      'last_composition_mutation_id': _mutation
    };
http.Response _json(Object? value, [int status = 200]) =>
    http.Response(jsonEncode(value), status,
        headers: {'content-type': 'application/json'});

SupabaseClient _client(Future<http.Response> Function(http.Request) handler) {
  final client = SupabaseClient(
    'https://example.test',
    'synthetic-publishable-key',
    httpClient: MockClient((request) async {
      final response = await handler(request);
      return http.Response.bytes(response.bodyBytes, response.statusCode,
          headers: response.headers,
          request: request,
          reasonPhrase: response.reasonPhrase);
    }),
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  addTearDown(client.dispose);
  return client;
}

void main() {
  test(
      'real SDK sends owner/Routine filters, explicit ascending UUID cursor and constrained FK join',
      () async {
    final requests = <http.Request>[];
    final client = _client((request) async {
      requests.add(request);
      return _json(request.url.path.endsWith('user_workout_routines')
          ? [_header()]
          : []);
    });
    final gateway = SupabaseRoutineCompositionGateway(client);
    await gateway.readHeader(userId: _owner, routineId: _routine);
    await gateway.readEntries(
        userId: _owner, routineId: _routine, limit: 37, afterId: _id(1));
    await gateway.readSets(
        userId: _owner, routineId: _routine, limit: 37, afterId: _id(2));
    expect(requests.every((request) => request.method == 'GET'), isTrue);
    expect(requests[0].url.queryParameters['user_id'], 'eq.$_owner');
    expect(requests[0].url.queryParameters['id'], 'eq.$_routine');
    expect(requests[0].url.queryParameters['select'],
        'id,user_id,name,composition_revision,last_composition_mutation_id');
    for (final request in requests.skip(1)) {
      expect(request.url.queryParameters['order'], 'id.asc.nullslast');
      expect(request.url.queryParameters['limit'], '37');
      expect(request.url.queryParameters['user_id'], 'eq.$_owner');
    }
    expect(requests[1].url.queryParameters['routine_id'], 'eq.$_routine');
    expect(requests[1].url.queryParameters['id'], 'gt.${_id(1)}');
    expect(requests[2].url.queryParameters['id'], 'gt.${_id(2)}');
    expect(requests[2].url.queryParameters['entry.user_id'], 'eq.$_owner');
    expect(requests[2].url.queryParameters['entry.routine_id'], 'eq.$_routine');
    expect(
        requests[2].url.queryParameters['select'],
        contains(
            'entry:user_workout_routine_exercises!user_workout_routine_sets_exercise_owner_fkey!inner(id,user_id,routine_id)'));
  });

  test('name-only uses single versioned authenticated RPC with NULL Exercises',
      () async {
    final requests = <http.Request>[];
    final client = _client((request) async {
      requests.add(request);
      return _json(2);
    });
    final repository = SupabaseRoutineCompositionRepository(
      gateway: SupabaseRoutineCompositionGateway(client),
      currentUserId: () => _owner,
    );
    final command = RoutineAggregateUpdate(
      routineId: RoutineId(_routine),
      programId: ProgramId('44444444-4444-4444-4444-444444444444'),
      expectedRevision: 1,
      expectedName: 'Old Name',
      mutationId: _mutation,
      name: 'Updated Name',
    );
    expect(await repository.updateAggregate(command), 2);
    expect(requests.length, 1);
    expect(requests.single.method, 'POST');
    expect(requests.single.url.path,
        '/rest/v1/rpc/update_user_workout_routine_with_composition');
    expect(jsonDecode(requests.single.body), {
      'p_routine_id': _routine,
      'p_program_id': '44444444-4444-4444-4444-444444444444',
      'p_expected_revision': 1,
      'p_expected_name': 'Old Name',
      'p_client_mutation_id': _mutation,
      'p_name': 'Updated Name',
      'p_exercises': null,
    });
  });

  test(
      'real SDK RPC serialization has only four approved args and no direct DML',
      () async {
    final requests = <http.Request>[];
    final client = _client((request) async {
      requests.add(request);
      return _json(1);
    });
    final repository = SupabaseRoutineCompositionRepository(
      gateway: SupabaseRoutineCompositionGateway(client),
      currentUserId: () => _owner,
    );
    final command = RoutineCompositionSave(
        routineId: RoutineId(_routine),
        expectedRevision: 0,
        mutationId: _mutation,
        entries: [
          RoutineCompositionEntry(
              id: _id(2),
              exercise: ExerciseRef.userCreated(_owner),
              sets: [
                RoutineCompositionSet(
                    id: _id(9),
                    prescription:
                        SetPrescription(reps: 5, loadKg: 0, restSeconds: 0))
              ])
        ]);
    expect(await repository.save(command), 1);
    expect(requests.length, 1);
    expect(requests.single.method, 'POST');
    expect(requests.single.url.path,
        '/rest/v1/rpc/save_user_workout_routine_composition');
    expect(jsonDecode(requests.single.body), {
      'p_routine_id': _routine,
      'p_expected_revision': 0,
      'p_client_mutation_id': _mutation,
      'p_exercises': [
        {
          'id': _id(2),
          'exercise_ref': _owner,
          'sets': [
            {'id': _id(9), 'reps': 5, 'reps_max': null,
             'set_type': 'normal', 'load_kg': 0.0,
              'distance_meters': null,'duration_seconds': null,
              'rest_seconds': 0}
          ]
        }
      ],
    });
  });

  test(
      'SDK integration drains short capped pages and returns ordered complete snapshot',
      () async {
    final entries = [
      for (var i = 1; i <= 3; i++)
        {
          'id': _id(i),
          'user_id': _owner,
          'routine_id': _routine,
          'position': 3 - i,
          'catalog_exercise_id': 'ex_squat',
          'user_exercise_id': null,
        }
    ];
    final sets = [
      for (var i = 10; i <= 11; i++)
        {
          'id': _id(i),
          'user_id': _owner,
          'routine_exercise_id': _id(1),
          'position': 11 - i,
          'reps': 5,
          'reps_max': null,
          'set_type': 'normal',
          'load_kg': null,
          'distance_meters': null,
          'duration_seconds': null,
          'rest_seconds': null,
          'entry': {'id': _id(1), 'user_id': _owner, 'routine_id': _routine},
        }
    ];
    final requests = <http.Request>[];
    final client = _client((request) async {
      requests.add(request);
      if (request.url.path.endsWith('user_workout_routines')) {
        return _json([_header()]);
      }
      final rows = request.url.path.endsWith('user_workout_routine_sets')
          ? sets
          : entries;
      final cursor = request.url.queryParameters['id']?.substring(3);
      return _json(rows
          .where((row) =>
              cursor == null || (row['id'] as String).compareTo(cursor) > 0)
          .take(1)
          .toList());
    });
    final repository = SupabaseRoutineCompositionRepository(
        gateway: SupabaseRoutineCompositionGateway(client),
        currentUserId: () => _owner);
    final snapshot = (await repository.read(RoutineId(_routine)))!;
    expect(snapshot.entries.map((e) => e.id), [_id(3), _id(2), _id(1)]);
    expect(snapshot.entries.last.sets.map((s) => s.id), [_id(11), _id(10)]);
    expect(requests.length, 9);
    expect(requests.every((request) => request.method == 'GET'), isTrue);
  });

  test(
      'SDK transport loss after commit performs one POST then read reconciliation',
      () async {
    var posts = 0, gets = 0;
    final client = _client((request) async {
      if (request.method == 'POST') {
        posts++;
        throw http.ClientException('synthetic lost reply');
      }
      gets++;
      return _json(request.url.path.endsWith('user_workout_routines')
          ? [_header()]
          : []);
    });
    final repository = SupabaseRoutineCompositionRepository(
        gateway: SupabaseRoutineCompositionGateway(client),
        currentUserId: () => _owner);
    expect(
        await repository.save(RoutineCompositionSave(
            routineId: RoutineId(_routine),
            expectedRevision: 0,
            mutationId: _mutation)),
        1);
    expect(posts, 1);
    expect(gets, 4);
  });

  test('SDK malformed HTTP 200 reconciles once or leaves the outcome unknown',
      () async {
    for (final committed in [true, false]) {
      var posts = 0, gets = 0;
      final client = _client((request) async {
        if (request.method == 'POST') {
          posts++;
          return http.Response('<html>synthetic truncated reply', 200);
        }
        gets++;
        final header = _header()
          ..['composition_revision'] = committed ? 1 : 0
          ..['last_composition_mutation_id'] = committed ? _mutation : null;
        return _json(
            request.url.path.endsWith('user_workout_routines') ? [header] : []);
      });
      final repository = SupabaseRoutineCompositionRepository(
          gateway: SupabaseRoutineCompositionGateway(client),
          currentUserId: () => _owner);
      final result = repository.save(RoutineCompositionSave(
          routineId: RoutineId(_routine),
          expectedRevision: 0,
          mutationId: _mutation));
      if (committed) {
        expect(await result, 1);
      } else {
        await expectLater(
            result, throwsA(isA<RoutineCompositionSaveOutcomeUnknown>()));
      }
      expect(posts, 1);
      expect(gets, 4);
    }
  });

  for (final code in ['PGRST301', 'PGRST302', 'PGRST303']) {
    test('SDK structured JWT rejection $code is unauthorized for read and save',
        () async {
      final requests = <http.Request>[];
      final client = _client((request) async {
        requests.add(request);
        return _json({'code': code, 'message': 'synthetic JWT failure'}, 401);
      });
      final repository = SupabaseRoutineCompositionRepository(
          gateway: SupabaseRoutineCompositionGateway(client),
          currentUserId: () => _owner);
      final unauthorized = throwsA(isA<RoutineCompositionException>().having(
          (e) => e.kind, 'kind', RoutineCompositionFailureKind.unauthorized));
      await expectLater(repository.read(RoutineId(_routine)), unauthorized);
      await expectLater(
          repository.save(RoutineCompositionSave(
              routineId: RoutineId(_routine),
              expectedRevision: 0,
              mutationId: _mutation)),
          unauthorized);
      expect(requests.map((request) => request.method), ['GET', 'POST']);
    });
  }

  test(
      'SDK permission denial stays sanitized and never uses privileged fallback',
      () async {
    var requests = 0;
    final client = _client((request) async {
      requests++;
      return _json({
        'code': '42501',
        'message': 'synthetic sensitive backend details',
        'details': 'do not retain'
      }, 403);
    });
    final repository = SupabaseRoutineCompositionRepository(
        gateway: SupabaseRoutineCompositionGateway(client),
        currentUserId: () => _owner);
    await expectLater(
        repository.read(RoutineId(_routine)),
        throwsA(isA<RoutineCompositionException>()
            .having(
                (e) => e.kind, 'kind', RoutineCompositionFailureKind.forbidden)
            .having((e) => e.toString(), 'sanitized',
                isNot(contains('sensitive')))));
    expect(requests, 1);
  });

  test(
      'SDK missing Routine stays null; invalid JSON fails instead of returning empty',
      () async {
    var malformed = false;
    final client = _client((request) async => malformed
        ? http.Response('{ broken', 200,
            headers: {'content-type': 'application/json'})
        : _json([]));
    final repository = SupabaseRoutineCompositionRepository(
        gateway: SupabaseRoutineCompositionGateway(client),
        currentUserId: () => _owner);
    expect(await repository.read(RoutineId(_routine)), isNull);
    malformed = true;
    await expectLater(
        repository.read(RoutineId(_routine)),
        throwsA(isA<RoutineCompositionException>().having((e) => e.kind, 'kind',
            RoutineCompositionFailureKind.malformedData)));
  });
}
