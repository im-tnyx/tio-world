import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_workout/workout.dart';

const _owner = '11111111-1111-4111-a111-111111111111';
const _session = '22222222-2222-4222-a222-222222222222';

http.Response _json(Object? value, [int status = 200]) => http.Response(
      jsonEncode(value),
      status,
      headers: {'content-type': 'application/json'},
    );

SupabaseClient _client(Future<http.Response> Function(http.Request) handler) {
  final client = SupabaseClient(
    'https://example.test',
    'synthetic-publishable-key',
    httpClient: MockClient((request) async {
      final response = await handler(request);
      return http.Response.bytes(
        response.bodyBytes,
        response.statusCode,
        headers: response.headers,
        request: request,
        reasonPhrase: response.reasonPhrase,
      );
    }),
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  addTearDown(client.dispose);
  return client;
}

void main() {
  group('SupabaseWorkoutSessionGateway', () {
    test('History headers filter completed owner and use stable keyset order',
        () async {
      http.Request? captured;
      final client = _client((request) async {
        captured = request;
        return _json([]);
      });
      final cursor = DateTime.utc(2026, 11, 11, 9);
      await SupabaseWorkoutSessionGateway(client).readCompletedHistoryHeaders(
        _owner,
        limit: 6,
        beforeCompletedAtUtc: cursor,
        beforeId: _session,
      );
      final query = captured!.url.queryParameters;
      expect(captured!.url.path, '/rest/v1/user_workout_sessions');
      expect(query['user_id'], 'eq.$_owner');
      expect(query['status'], 'eq.completed');
      expect(query['select'], contains('revision'));
      expect(
          query['order'], 'completed_at_utc.desc.nullslast,id.desc.nullslast');
      expect(query['limit'], '6');
      expect(query['or'], contains('id.lt.$_session'));
      expect(query['or'], contains('completed_at_utc.lt.'));
    });

    test('History performed rows use one bounded owner and session batch',
        () async {
      http.Request? captured;
      final client = _client((request) async {
        captured = request;
        return _json([]);
      });
      await SupabaseWorkoutSessionGateway(client).readHistoryPerformedSets(
        _owner,
        [_session],
        offset: 1000,
        limit: 1000,
      );
      expect(captured!.url.path, '/rest/v1/user_workout_performed_sets');
      expect(captured!.url.queryParameters['user_id'], 'eq.$_owner');
      expect(captured!.url.queryParameters['session_id'], contains(_session));
      expect(captured!.url.queryParameters['select'], contains('reps,load_kg'));
      expect(captured!.url.queryParameters['offset'], '1000');
      expect(captured!.url.queryParameters['limit'], '1000');
    });

    test(
        'readActiveSessionHeader queries user_workout_sessions with owner and active/paused filters',
        () async {
      http.Request? captured;
      final client = _client((request) async {
        captured = request;
        return _json([
          {
            'id': _session,
            'user_id': _owner,
            'status': 'active',
          }
        ]);
      });

      final gateway = SupabaseWorkoutSessionGateway(client);
      final result = await gateway.readActiveSessionHeader(_owner);

      expect(result, isNotNull);
      expect(result!['id'], _session);
      expect(captured!.url.path, '/rest/v1/user_workout_sessions');
      expect(captured!.url.queryParameters['user_id'], 'eq.$_owner');
      expect(
        captured!.url.queryParameters['status'],
        'in.("active","paused")',
      );
    });

    test(
        'readSessionHeader queries user_workout_sessions with owner and session ID filters',
        () async {
      http.Request? captured;
      final client = _client((request) async {
        captured = request;
        return _json([
          {
            'id': _session,
            'user_id': _owner,
            'status': 'completed',
          }
        ]);
      });

      final gateway = SupabaseWorkoutSessionGateway(client);
      final result = await gateway.readSessionHeader(_owner, _session);

      expect(result, isNotNull);
      expect(result!['id'], _session);
      expect(captured!.url.path, '/rest/v1/user_workout_sessions');
      expect(captured!.url.queryParameters['user_id'], 'eq.$_owner');
      expect(captured!.url.queryParameters['id'], 'eq.$_session');
    });

    test('Detail header filters completed status, owner and session ID',
        () async {
      http.Request? captured;
      final client = _client((request) async {
        captured = request;
        return _json([]);
      });
      final gateway = SupabaseWorkoutSessionGateway(client);

      expect(
          await gateway.readCompletedHistoryHeader(_owner, _session), isNull);
      expect(captured!.url.path, '/rest/v1/user_workout_sessions');
      expect(captured!.url.queryParameters['user_id'], 'eq.$_owner');
      expect(captured!.url.queryParameters['id'], 'eq.$_session');
      expect(captured!.url.queryParameters['status'], 'eq.completed');
    });

    test(
        'readPerformedSets applies deterministic ordering and cursor pagination',
        () async {
      http.Request? captured;
      final client = _client((request) async {
        captured = request;
        return _json([
          {
            'id': '33333333-3333-4333-a333-333333333333',
            'session_id': _session,
            'user_id': _owner,
            'session_exercise_index': 0,
            'set_index': 0,
          }
        ]);
      });

      final gateway = SupabaseWorkoutSessionGateway(client);
      final results = await gateway.readPerformedSets(
        _owner,
        _session,
        limit: 100,
        afterSessionExerciseIndex: 0,
        afterSetIndex: 2,
      );

      expect(results.length, 1);
      expect(captured!.url.path, '/rest/v1/user_workout_performed_sets');
      expect(captured!.url.queryParameters['session_id'], 'eq.$_session');
      expect(captured!.url.queryParameters['order'],
          'session_exercise_index.asc.nullslast,set_index.asc.nullslast');
      expect(
        captured!.url.queryParameters['or'],
        '(session_exercise_index.gt.0,and(session_exercise_index.eq.0,set_index.gt.2))',
      );
    });

    test('rpcStartWorkoutSession posts parameters to rpc_start_workout_session',
        () async {
      http.Request? captured;
      final client = _client((request) async {
        captured = request;
        return _json({
          'id': _session,
          'revision': 1,
          'status': 'active',
        });
      });

      final gateway = SupabaseWorkoutSessionGateway(client);
      final params = {'p_session_id': _session};
      final result = await gateway.rpcStartWorkoutSession(params);

      expect(result['id'], _session);
      expect(captured!.method, 'POST');
      expect(captured!.url.path, '/rest/v1/rpc/rpc_start_workout_session');
      expect(jsonDecode(captured!.body), params);
    });

    test('rpcPauseWorkoutSession posts parameters to rpc_pause_workout_session',
        () async {
      http.Request? captured;
      final client = _client((request) async {
        captured = request;
        return _json({
          'id': _session,
          'revision': 2,
          'status': 'paused',
        });
      });

      final gateway = SupabaseWorkoutSessionGateway(client);
      final params = {
        'p_session_id': _session,
        'p_expected_revision': 1,
      };
      final result = await gateway.rpcPauseWorkoutSession(params);

      expect(result['status'], 'paused');
      expect(captured!.url.path, '/rest/v1/rpc/rpc_pause_workout_session');
    });

    test(
        'rpcResumeWorkoutSession posts parameters to rpc_resume_workout_session',
        () async {
      http.Request? captured;
      final client = _client((request) async {
        captured = request;
        return _json({
          'id': _session,
          'revision': 3,
          'status': 'active',
        });
      });

      final gateway = SupabaseWorkoutSessionGateway(client);
      final params = {
        'p_session_id': _session,
        'p_expected_revision': 2,
      };
      final result = await gateway.rpcResumeWorkoutSession(params);

      expect(result['status'], 'active');
      expect(captured!.url.path, '/rest/v1/rpc/rpc_resume_workout_session');
    });

    test('rpcLogWorkoutPerformedSet posts parameters and returns child set row',
        () async {
      http.Request? captured;
      final client = _client((request) async {
        captured = request;
        return _json({
          'id': '44444444-4444-4444-a444-444444444444',
          'session_id': _session,
          'exercise_ref': 'ex_bench_press',
        });
      });

      final gateway = SupabaseWorkoutSessionGateway(client);
      final params = {
        'p_set_id': '44444444-4444-4444-a444-444444444444',
        'p_session_id': _session,
      };
      final result = await gateway.rpcLogWorkoutPerformedSet(params);

      expect(result['exercise_ref'], 'ex_bench_press');
      expect(captured!.url.path, '/rest/v1/rpc/rpc_log_workout_performed_set');
    });

    test(
        'rpcRemoveWorkoutPerformedSet invokes rpc_remove_workout_performed_set',
        () async {
      http.Request? captured;
      final client = _client((request) async {
        captured = request;
        return _json(null);
      });

      final gateway = SupabaseWorkoutSessionGateway(client);
      final params = {
        'p_set_id': '44444444-4444-4444-a444-444444444444',
        'p_session_id': _session,
        'p_expected_session_revision': 2,
      };
      await gateway.rpcRemoveWorkoutPerformedSet(params);

      expect(
          captured!.url.path, '/rest/v1/rpc/rpc_remove_workout_performed_set');
    });

    test('rpcCompleteWorkoutSession posts parameters and returns session row',
        () async {
      http.Request? captured;
      final client = _client((request) async {
        captured = request;
        return _json({
          'id': _session,
          'revision': 5,
          'status': 'completed',
        });
      });

      final gateway = SupabaseWorkoutSessionGateway(client);
      final params = {
        'p_session_id': _session,
        'p_expected_revision': 4,
      };
      final result = await gateway.rpcCompleteWorkoutSession(params);

      expect(result['status'], 'completed');
      expect(
          captured!.url.path, '/rest/v1/rpc/rpc_complete_workout_session_v2');
    });

    test('rpcDiscardWorkoutSession posts parameters and returns session row',
        () async {
      http.Request? captured;
      final client = _client((request) async {
        captured = request;
        return _json({
          'id': _session,
          'revision': 5,
          'status': 'discarded',
        });
      });

      final gateway = SupabaseWorkoutSessionGateway(client);
      final params = {
        'p_session_id': _session,
        'p_expected_revision': 4,
        'p_discard_reason': 'Injury',
      };
      final result = await gateway.rpcDiscardWorkoutSession(params);

      expect(result['status'], 'discarded');
      expect(captured!.url.path, '/rest/v1/rpc/rpc_discard_workout_session');
    });

    test('throws FormatException if RPC returns unexpected non-map value',
        () async {
      final client = _client((request) async => _json(['unexpected', 'list']));
      final gateway = SupabaseWorkoutSessionGateway(client);

      expect(
        () => gateway.rpcStartWorkoutSession({}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
