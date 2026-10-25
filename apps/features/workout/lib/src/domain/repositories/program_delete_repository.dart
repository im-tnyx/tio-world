import 'package:tio_shared/shared.dart';

/// One owner-scoped, server-read snapshot frozen before Program confirmation.
///
/// It is a one-use capability, not a caller-composed list of guessed IDs.
final class ProgramDeleteTarget {
  ProgramDeleteTarget({
    required this.sourceProgramId,
    required this.name,
    required Iterable<RoutineId> expectedRoutineIds,
    required this.ownerId,
    required this.loginCycleId,
  }) : expectedRoutineIds = List.unmodifiable(expectedRoutineIds) {
    if (name.trim().isEmpty || ownerId.trim().isEmpty ||
        loginCycleId.trim().isEmpty ||
        this.expectedRoutineIds.length > 20000 ||
        this.expectedRoutineIds.toSet().length != this.expectedRoutineIds.length) {
      throw ArgumentError('Invalid Program Delete target.');
    }
  }

  final ProgramId sourceProgramId;
  final String name;
  final List<RoutineId> expectedRoutineIds;
  final String ownerId;
  final String loginCycleId;
}

enum ProgramDeleteFailureKind {
  unauthorized,
  defaultProtected,
  notFound,
  membershipConflict,
  staleTarget,
  invalidRequest,
  malformedData,
  inProgress,
  forbidden,
  transactionAborted,
  unavailable,
}

/// Sanitized definite failure: never propagate a provider payload into UI.
final class ProgramDeleteException implements Exception {
  const ProgramDeleteException(this.kind);
  final ProgramDeleteFailureKind kind;

  @override
  String toString() => 'ProgramDeleteException(${kind.name})';
}

enum ProgramDeleteUncertainty {
  unconfirmed,
  sourceAbsentOnRead,
  sourceStillVisible,
  sessionChanged,
}

/// No durable receipt exists for the server operation, so a timeout cannot
/// become CONFIRMED solely because the source Program disappears on read.
final class ProgramDeleteOutcomeUnknown implements Exception {
  const ProgramDeleteOutcomeUnknown(this.reason);
  final ProgramDeleteUncertainty reason;

  @override
  String toString() => 'ProgramDeleteOutcomeUnknown(${reason.name})';
}

/// Only a validated explicit successful RPC response can confirm this result.
enum ProgramDeleteResult { confirmed }

/// Separate Program-wide protected Delete capability; legacy
/// ProgramRepository.list/create/rename and all screen contracts stay intact.
abstract interface class ProgramDeleteRepository {
  /// Null for an owner-invisible Program. Canonical My Program must be denied.
  /// Reads the exact owner Program and its current Routine UUID membership.
  Future<ProgramDeleteTarget?> inspect(ProgramId sourceProgramId);

  /// Executes one protected atomic RPC; no client table DELETE or implicit
  /// retry. A failed/unknown attempt cannot be replayed using the same target.
  Future<ProgramDeleteResult> delete(
    ProgramDeleteTarget target, {
    required String mutationId,
  });

  /// Read-only evidence after ambiguous dispatch. ALWAYS remains UNKNOWN:
  /// absent source does not prove this request committed (nor RLS visibility).
  /// Unconfirmed operations remain blocked for this owner/Program.
  Future<ProgramDeleteOutcomeUnknown> verifyUnknown(ProgramId sourceProgramId);
}
