import 'package:supabase_flutter/supabase_flutter.dart';

/// Narrow transport interface for Supabase workout session tables and RPCs.
abstract interface class WorkoutSessionGateway {
  /// Stable keyset page of owner-scoped completed headers (one extra row).
  Future<List<Map<String, dynamic>>> readCompletedHistoryHeaders(
    String userId, {
    required int limit,
    DateTime? beforeCompletedAtUtc,
    String? beforeId,
  });

  /// Batched performed rows for a bounded page of session IDs.
  Future<List<Map<String, dynamic>>> readHistoryPerformedSets(
    String userId,
    List<String> sessionIds, {
    required int offset,
    required int limit,
  });

  /// Reads the single active or paused session header for the given [userId],
  /// or returns `null` if none exists.
  Future<Map<String, dynamic>?> readActiveSessionHeader(String userId);

  /// Reads the session header by [sessionId] for the given [userId],
  /// or returns `null` if not found.
  Future<Map<String, dynamic>?> readSessionHeader(
    String userId,
    String sessionId,
  );

  /// Owner-scoped completed header for a History Detail deep link.
  Future<Map<String, dynamic>?> readCompletedHistoryHeader(
    String userId,
    String sessionId,
  );

  /// Reads performed sets for the given [sessionId] and [userId] ordered by
  /// `session_exercise_index ASC, set_index ASC`.
  Future<List<Map<String, dynamic>>> readPerformedSets(
    String userId,
    String sessionId, {
    int limit = 500,
    int? afterSessionExerciseIndex,
    int? afterSetIndex,
  });

  /// Invokes `public.rpc_start_workout_session`.
  Future<Map<String, dynamic>> rpcStartWorkoutSession(
    Map<String, dynamic> params,
  );

  /// Invokes `public.rpc_pause_workout_session`.
  Future<Map<String, dynamic>> rpcPauseWorkoutSession(
    Map<String, dynamic> params,
  );

  /// Invokes `public.rpc_resume_workout_session`.
  Future<Map<String, dynamic>> rpcResumeWorkoutSession(
    Map<String, dynamic> params,
  );

  /// Invokes `public.rpc_log_workout_performed_set`.
  Future<Map<String, dynamic>> rpcLogWorkoutPerformedSet(
    Map<String, dynamic> params,
  );

  /// Invokes `public.rpc_remove_workout_performed_set`.
  Future<void> rpcRemoveWorkoutPerformedSet(
    Map<String, dynamic> params,
  );

  /// Invokes `public.rpc_complete_workout_session_v2`.
  Future<Map<String, dynamic>> rpcCompleteWorkoutSession(
    Map<String, dynamic> params,
  );

  /// Atomically commits one owner-scoped Save-only workout.
  Future<Map<String, dynamic>> rpcSaveWorkoutDraft(
    Map<String, dynamic> params,
  );

  /// Invokes `public.rpc_discard_workout_session`.
  Future<Map<String, dynamic>> rpcDiscardWorkoutSession(
    Map<String, dynamic> params,
  );
}

/// Production implementation of [WorkoutSessionGateway] backed by [SupabaseClient].
final class SupabaseWorkoutSessionGateway implements WorkoutSessionGateway {
  const SupabaseWorkoutSessionGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> readCompletedHistoryHeaders(
    String userId, {
    required int limit,
    DateTime? beforeCompletedAtUtc,
    String? beforeId,
  }) async {
    var query = _client
        .from('user_workout_sessions')
        .select('id,user_id,status,completed_at_utc,started_at_utc,'
            'accumulated_paused_microseconds,workout_title,workout_at_utc,'
            'workout_utc_offset_minutes,notes,gym_name,'
            'workout_duration_seconds,routine_snapshot')
        .eq('user_id', userId)
        .eq('status', 'completed');
    if (beforeCompletedAtUtc != null && beforeId != null) {
      final instant = beforeCompletedAtUtc.toUtc().toIso8601String();
      query = query.or('completed_at_utc.lt.$instant,'
          'and(completed_at_utc.eq.$instant,id.lt.$beforeId)');
    }
    final response = await query
        .order('completed_at_utc', ascending: false)
        .order('id', ascending: false)
        .limit(limit)
        .retry(enabled: false);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  @override
  Future<List<Map<String, dynamic>>> readHistoryPerformedSets(
    String userId,
    List<String> sessionIds, {
    required int offset,
    required int limit,
  }) async {
    if (sessionIds.isEmpty) return const [];
    final response = await _client
        .from('user_workout_performed_sets')
        .select('session_id,user_id,exercise_ref,session_exercise_index,'
            'set_index,reps,load_kg,is_skipped,completed_at_utc')
        .eq('user_id', userId)
        .inFilter('session_id', sessionIds)
        .order('session_id')
        .order('session_exercise_index')
        .order('set_index')
        .range(offset, offset + limit - 1)
        .retry(enabled: false);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>?> readActiveSessionHeader(String userId) async {
    final response = await _client
        .from('user_workout_sessions')
        .select()
        .eq('user_id', userId)
        .inFilter('status', const ['active', 'paused'])
        .maybeSingle()
        .retry(enabled: false);

    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<Map<String, dynamic>?> readSessionHeader(
    String userId,
    String sessionId,
  ) async {
    final response = await _client
        .from('user_workout_sessions')
        .select()
        .eq('user_id', userId)
        .eq('id', sessionId)
        .maybeSingle()
        .retry(enabled: false);

    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<Map<String, dynamic>?> readCompletedHistoryHeader(
    String userId,
    String sessionId,
  ) async {
    final response = await _client
        .from('user_workout_sessions')
        .select()
        .eq('user_id', userId)
        .eq('id', sessionId)
        .eq('status', 'completed')
        .maybeSingle()
        .retry(enabled: false);
    return response == null ? null : Map<String, dynamic>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> readPerformedSets(
    String userId,
    String sessionId, {
    int limit = 500,
    int? afterSessionExerciseIndex,
    int? afterSetIndex,
  }) async {
    var query = _client
        .from('user_workout_performed_sets')
        .select()
        .eq('user_id', userId)
        .eq('session_id', sessionId);

    if (afterSessionExerciseIndex != null && afterSetIndex != null) {
      query = query.or(
        'session_exercise_index.gt.$afterSessionExerciseIndex,and(session_exercise_index.eq.$afterSessionExerciseIndex,set_index.gt.$afterSetIndex)',
      );
    }

    final response = await query
        .order('session_exercise_index', ascending: true)
        .order('set_index', ascending: true)
        .limit(limit)
        .retry(enabled: false);

    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>> rpcStartWorkoutSession(
    Map<String, dynamic> params,
  ) async {
    final response = await _client
        .rpc<Object?>('rpc_start_workout_session', params: params)
        .retry(enabled: false);
    return _toMap(response, 'rpc_start_workout_session');
  }

  @override
  Future<Map<String, dynamic>> rpcPauseWorkoutSession(
    Map<String, dynamic> params,
  ) async {
    final response = await _client
        .rpc<Object?>('rpc_pause_workout_session', params: params)
        .retry(enabled: false);
    return _toMap(response, 'rpc_pause_workout_session');
  }

  @override
  Future<Map<String, dynamic>> rpcResumeWorkoutSession(
    Map<String, dynamic> params,
  ) async {
    final response = await _client
        .rpc<Object?>('rpc_resume_workout_session', params: params)
        .retry(enabled: false);
    return _toMap(response, 'rpc_resume_workout_session');
  }

  @override
  Future<Map<String, dynamic>> rpcLogWorkoutPerformedSet(
    Map<String, dynamic> params,
  ) async {
    final response = await _client
        .rpc<Object?>('rpc_log_workout_performed_set', params: params)
        .retry(enabled: false);
    return _toMap(response, 'rpc_log_workout_performed_set');
  }

  @override
  Future<void> rpcRemoveWorkoutPerformedSet(
    Map<String, dynamic> params,
  ) async {
    await _client
        .rpc<void>('rpc_remove_workout_performed_set', params: params)
        .retry(enabled: false);
  }

  @override
  Future<Map<String, dynamic>> rpcCompleteWorkoutSession(
    Map<String, dynamic> params,
  ) async {
    final response = await _client
        .rpc<Object?>('rpc_complete_workout_session_v2', params: params)
        .retry(enabled: false);
    return _toMap(response, 'rpc_complete_workout_session_v2');
  }

  @override
  Future<Map<String, dynamic>> rpcSaveWorkoutDraft(
    Map<String, dynamic> params,
  ) async {
    final response = await _client
        .rpc<Object?>('rpc_save_workout_session_v1', params: params)
        .retry(enabled: false);
    return _toMap(response, 'rpc_save_workout_session_v1');
  }

  @override
  Future<Map<String, dynamic>> rpcDiscardWorkoutSession(
    Map<String, dynamic> params,
  ) async {
    final response = await _client
        .rpc<Object?>('rpc_discard_workout_session', params: params)
        .retry(enabled: false);
    return _toMap(response, 'rpc_discard_workout_session');
  }

  static Map<String, dynamic> _toMap(Object? response, String rpcName) {
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    throw FormatException(
      'RPC $rpcName returned invalid response shape (expected map, got ${response.runtimeType})',
    );
  }
}
