import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/routine_composition_repository.dart';
import '../../domain/repositories/routine_create_repository.dart';
import 'supabase_routine_composition_repository.dart';

typedef RoutineCreateCurrentUserId = String? Function();

/// Calls only the reviewed transactional Create RPC (GitHub #536).
/// It deliberately cannot fall back to metadata INSERT + composition Save.
final class SupabaseRoutineCreateRepository implements RoutineCreateRepository {
  SupabaseRoutineCreateRepository({
    required SupabaseClient client,
    RoutineCreateCurrentUserId? currentUserId,
  })  : _client = client,
        _currentUserId = currentUserId ?? (() => client.auth.currentUser?.id);

  final SupabaseClient _client;
  final RoutineCreateCurrentUserId _currentUserId;

  @override
  Future<int> create(RoutineCreateCommand command) async {
    final owner = _currentUserId()?.trim();
    if (owner == null || owner.isEmpty) {
      throw const RoutineCompositionException(
        RoutineCompositionFailureKind.unauthorized,
      );
    }
    // Reuse the exact same validated payload codec as Edit, with the immutable
    // routine+mutation UUIDs. An RPC success is one atomic DB transaction.
    final payload = SupabaseRoutineCompositionRepository.payload(
      RoutineCompositionSave(
        routineId: command.routine.id,
        expectedRevision: 0,
        mutationId: command.mutationId,
        entries: command.entries,
      ),
    );
    try {
      final result = await _client.rpc<Object?>(
        'create_user_workout_routine_with_composition',
        params: {
          'p_routine_id': command.routine.id.value,
          'p_program_id': command.routine.programId.value,
          'p_name': command.routine.name,
          'p_client_mutation_id': command.mutationId,
          'p_exercises': payload,
        },
      ).retry(enabled: false).timeout(const Duration(seconds: 15));
      if (_currentUserId()?.trim() != owner) {
        throw const RoutineCompositionSaveOutcomeUnknown(
          reason: RoutineCompositionSaveUncertainty.authChanged,
        );
      }
      if (result is int && result == 1) return 1;
      throw const RoutineCompositionSaveOutcomeUnknown();
    } on PostgrestException catch (error) {
      if (_currentUserId()?.trim() != owner) {
        throw const RoutineCompositionSaveOutcomeUnknown(
          reason: RoutineCompositionSaveUncertainty.authChanged,
        );
      }
      // Mirror the composition adapter: these are definite SQL/Auth
      // rejections (including PostgREST JWT failures), not ambiguous writes.
      // Preserve outcomeUnknown for transport/5xx or malformed 2xx only.
      final kind = switch (error.code) {
        '28000' || '28P01' || '401' ||
        'PGRST301' || 'PGRST302' || 'PGRST303' =>
          RoutineCompositionFailureKind.unauthorized,
        '42501' || '403' =>
          RoutineCompositionFailureKind.forbidden,
        '22023' || '22P02' || '22003' || '23514' ||
        '23503' || '23505' || 'P0001' || 'P0002' || 'PGRST202' =>
          RoutineCompositionFailureKind.invalidRequest,
        _ => null,
      };
      if (kind != null) {
        throw RoutineCompositionException(kind);
      }
      // Like the existing Edit adapter, any other ordinary HTTP 4xx is
      // a definite rejection. Do not freeze an editable Create draft for
      // validation/conflict/throttle failures with numeric HTTP codes.
      final httpCode = int.tryParse(error.code ?? '');
      if (httpCode != null && httpCode >= 400 && httpCode < 500) {
        throw const RoutineCompositionException(
          RoutineCompositionFailureKind.invalidRequest,
        );
      }
      // Transport/connection, 5xx or malformed 2xx may follow a commit.
      throw const RoutineCompositionSaveOutcomeUnknown();
    } on RoutineCompositionException {
      rethrow;
    } on RoutineCompositionSaveOutcomeUnknown {
      rethrow;
    } catch (_) {
      throw const RoutineCompositionSaveOutcomeUnknown();
    }
  }
}
