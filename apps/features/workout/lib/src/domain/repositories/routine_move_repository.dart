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
    if (name.trim().isEmpty || expectedRevision < 0 ||
        ownerId.trim().isEmpty || loginCycleId.trim().isEmpty) {
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
  unauthorized, forbidden, notFound, revisionConflict, mutationConflict,
  staleTarget, invalidRequest, transactionAborted, malformedData,
  inProgress, unavailable,
}
final class RoutineMoveException implements Exception {
  const RoutineMoveException(this.kind);
  final RoutineMoveFailureKind kind;
  @override
  String toString() => 'RoutineMoveException(${kind.name})';
}
enum RoutineMoveUncertainty { unconfirmed, sessionChanged, absentOnRead, stillPresent }
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

/// Optional Workout-owned capability, separate from RoutineRepository.
/// An uncertain request must never be retried with a new token or assumed done.
abstract interface class RoutineMoveRepository {
  Future<RoutineMoveTarget?> inspect({
    required ProgramId sourceProgramId, required RoutineId routineId,
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
