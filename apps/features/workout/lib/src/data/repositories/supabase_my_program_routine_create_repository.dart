import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/repositories/my_program_routine_create_repository.dart';
import '../../domain/repositories/routine_composition_repository.dart';
import 'supabase_routine_composition_repository.dart';

typedef MyProgramCreateCurrentUserId = String? Function();

/// Staged #568 client adapter for the server-authoritative lazy My Program
/// transaction. No UI/provider consumes it while hosted EXECUTE is withheld.
/// The existing Program-scoped Create repository remains untouched.
final class SupabaseMyProgramRoutineCreateRepository
    implements MyProgramRoutineCreateRepository {
  SupabaseMyProgramRoutineCreateRepository({
    required SupabaseClient client,
    MyProgramCreateCurrentUserId? currentUserId,
  })  : _client = client,
        _currentUserId = currentUserId ?? (() => client.auth.currentUser?.id);

  final SupabaseClient _client;
  final MyProgramCreateCurrentUserId _currentUserId;

  @override
  Future<MyProgramRoutineCreateReceipt> createInMyProgram(
      MyProgramRoutineCreateCommand command) async {
    final owner = _currentUserId()?.trim();
    if (owner == null || owner.isEmpty) {
      throw const RoutineCompositionException(
        RoutineCompositionFailureKind.unauthorized,
      );
    }

    // Use exactly the established Create/Edit codec; never produce a
    // separate Program INSERT or metadata-only Routine write.
    final payload = SupabaseRoutineCompositionRepository.payload(
      RoutineCompositionSave(
        routineId: command.routineId,
        expectedRevision: 0,
        mutationId: command.mutationId,
        entries: command.entries,
        expectedCustomTypes: command.expectedCustomTypes,
      ),
    );

    try {
      final result = await _client.rpc<Object?>(
        'create_user_workout_routine_in_my_program',
        params: {
          'p_routine_id': command.routineId.value,
          'p_name': command.name,
          'p_client_mutation_id': command.mutationId,
          'p_exercises': payload,
        },
      ).retry(enabled: false).timeout(const Duration(seconds: 15));

      // The old owner may have committed; that does not authorize disclosing
      // the returned Program or reporting success to a different login.
      if (_currentUserId()?.trim() != owner) {
        throw const RoutineCompositionSaveOutcomeUnknown(
          reason: RoutineCompositionSaveUncertainty.authChanged,
        );
      }

      if (result is! Map<String, dynamic>) {
        throw const RoutineCompositionSaveOutcomeUnknown();
      }
      final id = result['program_id'];
      final revision = result['composition_revision'];
      if (id is! String || revision is! int || revision != 1) {
        throw const RoutineCompositionSaveOutcomeUnknown();
      }
      try {
        return MyProgramRoutineCreateReceipt(
          programId: ProgramId(id),
          compositionRevision: revision,
        );
      } on ArgumentError {
        // Malformed ACK is *not* proof of failed persistence.
        throw const RoutineCompositionSaveOutcomeUnknown();
      }
    } on PostgrestException catch (error) {
      // Known transactional SQLSTATE/Auth rejections prove rollback.
      // Other HTTP statuses are not sufficient evidence of rollback:
      // a gateway may have dropped an ACK after commit.
      final kind = switch (error.code) {
        '28000' || '28P01' ||
        'PGRST301' || 'PGRST302' || 'PGRST303' =>
          RoutineCompositionFailureKind.unauthorized,
        '42501' =>
          RoutineCompositionFailureKind.forbidden,
        '22023' || '22P02' || '22003' || '23514' ||
        '23503' || '23505' || 'P0001' || 'P0002' ||
        '25001' || 'PGRST202' || 'PGRST203' =>
          RoutineCompositionFailureKind.invalidRequest,
        _ => null,
      };
      if (kind != null) {
        throw RoutineCompositionException(kind);
      }
      // An unrecognized numeric HTTP 4xx is not proof that an intermediate
      // gateway/auth/proxy did not lose the ACK after a committed transaction.
      // Only the explicit SQLSTATE/PostgREST pre-execution codes above are
      // definite. Everything else stays UNKNOWN with frozen mutation IDs.
      if (_currentUserId()?.trim() != owner) {
        throw const RoutineCompositionSaveOutcomeUnknown(
          reason: RoutineCompositionSaveUncertainty.authChanged,
        );
      }
      throw const RoutineCompositionSaveOutcomeUnknown();
    } on RoutineCompositionException {
      rethrow;
    } on RoutineCompositionSaveOutcomeUnknown {
      rethrow;
    } catch (_) {
      // A timeout, network exception or SDK parse failure is UNKNOWN,
      // never a reason to auto-create a second Routine/default Program.
      throw const RoutineCompositionSaveOutcomeUnknown();
    }
  }
}
