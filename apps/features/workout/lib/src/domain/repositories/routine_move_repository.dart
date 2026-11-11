import 'package:tio_shared/shared.dart';

/// An owner-scoped snapshot; a card's unversioned Routine is not authority.
final class RoutineMoveTarget {
  RoutineMoveTarget({
    required this.routineId,
    required this.sourceProgramId,
    required this.name,
    required this.expectedRevision,
    required this.ownerId,
    required this.loginCycleId,
  }) {
    if (name.trim().isEmpty ||
        expectedRevision < 0 ||
        ownerId.trim().isEmpty ||
        loginCycleId.trim().isEmpty) {
      throw ArgumentError('Invalid Routine Move target.');
    }
  }
  final RoutineId routineId;
  final ProgramId sourceProgramId;
  final String name;
  final int expectedRevision;
  final String ownerId;
  final String loginCycleId;
}

enum RoutineMoveFailureKind {
  unauthorized,
  forbidden,
  notFound,
  revisionConflict,
  mutationConflict,
  staleTarget,
  invalidRequest,
  transactionAborted,
  malformedData,
  inProgress,
  unavailable,
}

final class RoutineMoveException implements Exception {
  const RoutineMoveException(this.kind);
  final RoutineMoveFailureKind kind;
  @override
  String toString() => 'RoutineMoveException(${kind.name})';
}

enum RoutineMoveUncertainty {
  unconfirmed,
  sessionChanged,
  absentOnRead,
  stillPresent
}

final class RoutineMoveOutcomeUnknown implements Exception {
  const RoutineMoveOutcomeUnknown({
    this.reason = RoutineMoveUncertainty.unconfirmed,
    this.observedRevision,
    this.observedProgramId,
  });
  final RoutineMoveUncertainty reason;
  final int? observedRevision;
  final ProgramId? observedProgramId;
  @override
  String toString() => 'RoutineMoveOutcomeUnknown(${reason.name})';
}

enum RoutineMoveResult { confirmed }

/// A read-only check of the *original* ambiguous write, never a retry.
/// An exact latest persisted server mutation token is required for confirmed.
/// Negative/early owner reads are not proof the original RPC was rejected.
enum RoutineMoveReadbackKind {
  confirmedLatestMutation,
  notConfirmed,
  superseded,
  absentOnRead,
  readUnavailable,
}

final class RoutineMoveReadback {
  const RoutineMoveReadback({
    required this.kind,
    this.observedProgramId,
    this.observedRevision,
  });
  final RoutineMoveReadbackKind kind;
  final ProgramId? observedProgramId;
  final int? observedRevision;
}

/// Optional recovery capability for an UNKNOWN Move within its original
/// authenticated login cycle. Does not authorize new Move writes.
abstract interface class RoutineMoveUnknownVerifier {
  /// Verify only this caller's attempted write, not an older UNKNOWN write
  /// at the same Routine ID. The token must match the frozen attempt.
  Future<RoutineMoveReadback> verifyUnknown({
    required RoutineId routineId,
    required String mutationId,
  });
}

/// Optional Workout-owned capability, separate from RoutineRepository.
/// An uncertain request must never be retried with a new token or assumed done.
abstract interface class RoutineMoveRepository {
  Future<RoutineMoveTarget?> inspect({
    required ProgramId sourceProgramId,
    required RoutineId routineId,
  });
  Future<RoutineMoveResult> move({
    required RoutineMoveTarget target,
    required ProgramId destinationProgramId,
    required String mutationId,
  });
}

/// Optional, single-RPC Create Program + Move Routine capability.
/// Implementations must share the existing Move attempt/unknown gate so
/// new-Program and existing-Program moves cannot dispatch concurrently.
abstract interface class RoutineCreateMoveRepository {
  Future<RoutineMoveResult> createAndMove({
    required RoutineMoveTarget target,
    required ProgramId newProgramId,
    required String newProgramName,
    required String mutationId,
  });
}

/// Immutable authority captured only after a server-confirmed atomic
/// Create & Move. The protected full-Undo RPC validates these values again;
/// presentation state is never treated as persistence truth.
final class RoutineCreateMoveUndoReceipt {
  RoutineCreateMoveUndoReceipt({
    required this.routineId,
    required this.originalProgramId,
    required this.originalProgramName,
    required this.createdProgramId,
    required this.originalMoveMutationId,
    required this.expectedRevision,
    required this.ownerId,
    required this.loginCycleId,
  }) {
    if (originalProgramId == createdProgramId ||
        originalProgramName.trim().isEmpty ||
        !_isUuid(originalMoveMutationId) ||
        expectedRevision < 1 ||
        expectedRevision == 9223372036854775807 ||
        !_isUuid(ownerId) ||
        loginCycleId.trim().isEmpty) {
      throw ArgumentError('Invalid Create & Move Undo receipt.');
    }
  }

  final RoutineId routineId;
  final ProgramId originalProgramId;
  final String originalProgramName;
  final ProgramId createdProgramId;
  final String originalMoveMutationId;

  /// The confirmed post-Create & Move revision (the RPC's returned bigint).
  final int expectedRevision;
  final String ownerId;
  final String loginCycleId;

  static bool _isUuid(String value) => RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(value);
}

/// One protected RPC that restores the Routine and removes only the exact
/// eligible Program created by the same atomic Create & Move operation.
abstract interface class RoutineCreateMoveUndoRepository
    implements RoutineCreateMoveUndoUnknownVerifier {
  Future<RoutineMoveResult> undoCreateAndMove({
    required RoutineCreateMoveUndoReceipt receipt,
    required String undoMutationId,
  });
}

/// Read-only exact-token verifier for an ambiguous full-Undo request.
abstract interface class RoutineCreateMoveUndoUnknownVerifier {
  Future<RoutineMoveReadback> verifyUnknownCreateMoveUndo({
    required RoutineCreateMoveUndoReceipt receipt,
    required String undoMutationId,
  });
}
