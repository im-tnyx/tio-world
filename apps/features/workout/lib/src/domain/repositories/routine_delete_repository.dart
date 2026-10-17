import 'package:tio_shared/shared.dart';

/// The confirmed owner-readable Routine revision, frozen BEFORE a destructive
/// confirmation. The session marker is an app login-cycle identity, not a token.
final class RoutineDeleteTarget {
  RoutineDeleteTarget({
    required this.routineId,
    required this.programId,
    required this.name,
    required this.expectedRevision,
    required this.ownerId,
    required this.loginCycleId,
  }) {
    if (expectedRevision < 0 || name.trim().isEmpty ||
        ownerId.trim().isEmpty || loginCycleId.trim().isEmpty) {
      throw ArgumentError('Invalid Routine Delete target.');
    }
  }

  final RoutineId routineId;
  final ProgramId programId;
  final String name;
  final int expectedRevision;
  final String ownerId;
  final String loginCycleId;
}

enum RoutineDeleteFailureKind {
  unauthorized,
  forbidden,
  notFound,
  revisionConflict,
  staleTarget,
  transactionAborted,
  invalidRequest,
  malformedData,
  inProgress,
  unavailable,
}

/// Sanitized definite no-delete result; raw provider errors never reach UI.
final class RoutineDeleteException implements Exception {
  const RoutineDeleteException(this.kind);
  final RoutineDeleteFailureKind kind;

  @override
  String toString() => 'RoutineDeleteException(${kind.name})';
}

enum RoutineDeleteUncertainty { unconfirmed, absentOnRead, stillPresent, sessionChanged }

/// The request might have committed. Never blindly retry this write.
final class RoutineDeleteOutcomeUnknown implements Exception {
  const RoutineDeleteOutcomeUnknown({
    this.reason = RoutineDeleteUncertainty.unconfirmed,
    this.observedRevision,
    this.observedProgramId,
  });

  final RoutineDeleteUncertainty reason;
  final int? observedRevision;
  final ProgramId? observedProgramId;

  @override
  String toString() => 'RoutineDeleteOutcomeUnknown(${reason.name})';
}

/// Only the RPC's explicit boolean true is confirmed. An absent row after
/// an ambiguous request can also mean RLS invisibility or an in-flight write;
/// it must remain an uncertain outcome, never reported as success.
enum RoutineDeleteResult { confirmed }

/// Separate capability; legacy metadata RoutineRepository is unchanged.
abstract interface class RoutineDeleteRepository {
  /// Null means the selected Routine is not currently visible under this
  /// Program. Signed-out, switched-session and unreadable data fail closed.
  Future<RoutineDeleteTarget?> inspect({
    required ProgramId programId,
    required RoutineId routineId,
  });

  /// One revision-CAS RPC per freshly inspected target. Even definite failure
  /// consumes that target; another confirmation requires another inspect().
  /// No implicit write retry or new revision adoption. Ambiguous outcomes
  /// remain guarded across login cycles for the same owner and Routine.
  Future<RoutineDeleteResult> delete(RoutineDeleteTarget target);
}
