import 'package:tio_shared/shared.dart';

import 'routine_repository.dart';

/// Explicit owner-scoped authority captured from one complete versioned
/// Routine read. Program names and unversioned card state are never authority
/// for a destructive lifecycle operation.
final class ProgramDeleteTarget {
  factory ProgramDeleteTarget({
    required ProgramId sourceProgramId,
    required Iterable<RoutineId> expectedRoutineIds,
    required String ownerId,
    required String loginCycleId,
  }) {
    final ids = List<RoutineId>.of(expectedRoutineIds, growable: false);
    if (ids.length > 20000) {
      throw ArgumentError.value(
        expectedRoutineIds,
        'expectedRoutineIds',
        'must contain at most 20000 Routine IDs',
      );
    }
    if (ids.toSet().length != ids.length) {
      throw ArgumentError.value(
        expectedRoutineIds,
        'expectedRoutineIds',
        'must not contain duplicate Routine IDs',
      );
    }
    return ProgramDeleteTarget._(
      sourceProgramId: sourceProgramId,
      expectedRoutineIds: List.unmodifiable(ids),
      ownerId: _requireOwner(ownerId),
      loginCycleId: _requireCycle(loginCycleId),
    );
  }

  /// Builds the delete authority from the existing versioned Routine read
  /// contract. Every row must still belong to the requested source Program
  /// and the captured login cycle.
  factory ProgramDeleteTarget.fromVersionedRoutines({
    required ProgramId sourceProgramId,
    required Iterable<RoutineMetadataRevision> routines,
    required String ownerId,
    required String loginCycleId,
  }) {
    final cycle = _requireCycle(loginCycleId);
    final snapshots = List<RoutineMetadataRevision>.of(routines);
    for (final snapshot in snapshots) {
      if (snapshot.routine.programId != sourceProgramId ||
          snapshot.loginCycleId != cycle) {
        throw ArgumentError.value(
          routines,
          'routines',
          'must be one complete source-Program snapshot for this login cycle',
        );
      }
    }
    return ProgramDeleteTarget(
      sourceProgramId: sourceProgramId,
      expectedRoutineIds: snapshots.map((snapshot) => snapshot.routine.id),
      ownerId: ownerId,
      loginCycleId: cycle,
    );
  }

  const ProgramDeleteTarget._({
    required this.sourceProgramId,
    required this.expectedRoutineIds,
    required this.ownerId,
    required this.loginCycleId,
  });

  final ProgramId sourceProgramId;
  final List<RoutineId> expectedRoutineIds;
  final String ownerId;
  final String loginCycleId;

  static String _requireOwner(String value) {
    final owner = value.trim().toLowerCase();
    if (!RegExp(
      r'^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$',
    ).hasMatch(owner)) {
      throw ArgumentError.value(value, 'ownerId', 'must be a UUID');
    }
    return owner;
  }

  static String _requireCycle(String value) {
    final cycle = value.trim();
    if (cycle.isEmpty) {
      throw ArgumentError.value(value, 'loginCycleId', 'must not be empty');
    }
    return cycle;
  }
}

enum ProgramDeleteFailureKind {
  unauthorized,
  permissionUnavailable,
  notFound,
  defaultProtected,
  staleMembership,
  invalidRequest,
  transactionAborted,
  malformedData,
  inProgress,
  unavailable,
}

final class ProgramDeleteException implements Exception {
  const ProgramDeleteException(this.kind);

  final ProgramDeleteFailureKind kind;

  @override
  String toString() => 'ProgramDeleteException(${kind.name})';
}

enum ProgramDeleteUncertainty {
  unconfirmed,
  malformedResponse,
  sessionChanged,
}

/// The RPC may have committed. There is no automatic destructive retry and
/// no missing-source inference because D1 has no durable client receipt.
final class ProgramDeleteOutcomeUnknown implements Exception {
  const ProgramDeleteOutcomeUnknown({
    this.reason = ProgramDeleteUncertainty.unconfirmed,
  });

  final ProgramDeleteUncertainty reason;

  @override
  String toString() => 'ProgramDeleteOutcomeUnknown(${reason.name})';
}

final class ProgramDeleteResult {
  const ProgramDeleteResult({
    required this.deletedProgramId,
    required this.destinationProgramId,
    required this.movedRoutineCount,
  });

  final ProgramId deletedProgramId;
  final ProgramId? destinationProgramId;
  final int movedRoutineCount;
}

/// Dormant D2A capability. No production caller is wired in this slice.
abstract interface class ProgramDeleteRepository {
  Future<ProgramDeleteResult> delete({
    required ProgramDeleteTarget target,
    required String clientMutationId,
  });
}
