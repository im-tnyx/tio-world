import 'package:supabase_flutter/supabase_flutter.dart';

/// Narrow Data API transport; child writes are intentionally absent.
abstract interface class RoutineCompositionGateway {
  Future<Map<String, dynamic>?> readHeader({
    required String userId,
    required String routineId,
  });

  Future<List<Map<String, dynamic>>> readEntries({
    required String userId,
    required String routineId,
    required int limit,
    String? afterId,
  });

  Future<List<Map<String, dynamic>>> readSets({
    required String userId,
    required String routineId,
    required int limit,
    String? afterId,
  });

  Future<Object?> save({
    required String routineId,
    required int expectedRevision,
    required String mutationId,
    required List<Map<String, dynamic>> exercises,
  });
}

final class SupabaseRoutineCompositionGateway
    implements RoutineCompositionGateway {
  SupabaseRoutineCompositionGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> readHeader({
    required String userId,
    required String routineId,
  }) async =>
      await _client
          .from('user_workout_routines')
          .select(
              'id,user_id,composition_revision,last_composition_mutation_id')
          .eq('user_id', userId)
          .eq('id', routineId)
          .maybeSingle()
          .retry(enabled: false);

  @override
  Future<List<Map<String, dynamic>>> readEntries({
    required String userId,
    required String routineId,
    required int limit,
    String? afterId,
  }) async {
    var query = _client
        .from('user_workout_routine_exercises')
        .select(
            'id,user_id,routine_id,position,catalog_exercise_id,user_exercise_id')
        .eq('user_id', userId)
        .eq('routine_id', routineId);
    if (afterId != null) query = query.gt('id', afterId);
    return await query
        .order('id', ascending: true)
        .limit(limit)
        .retry(enabled: false);
  }

  @override
  Future<List<Map<String, dynamic>>> readSets({
    required String userId,
    required String routineId,
    required int limit,
    String? afterId,
  }) async {
    var query = _client
        .from('user_workout_routine_sets')
        .select(
            'id,user_id,routine_exercise_id,position,reps,reps_max,set_type,load_kg,rest_seconds,'
            'entry:user_workout_routine_exercises!user_workout_routine_sets_exercise_owner_fkey!inner(id,user_id,routine_id)')
        .eq('user_id', userId)
        .eq('entry.user_id', userId)
        .eq('entry.routine_id', routineId);
    if (afterId != null) query = query.gt('id', afterId);
    return await query
        .order('id', ascending: true)
        .limit(limit)
        .retry(enabled: false);
  }

  @override
  Future<Object?> save({
    required String routineId,
    required int expectedRevision,
    required String mutationId,
    required List<Map<String, dynamic>> exercises,
  }) async =>
      await _client
          .rpc<Object?>('save_user_workout_routine_composition', params: {
        'p_routine_id': routineId,
        'p_expected_revision': expectedRevision,
        'p_client_mutation_id': mutationId,
        'p_exercises': exercises,
      }).retry(enabled: false);
}
