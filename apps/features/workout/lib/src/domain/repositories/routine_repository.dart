import 'package:tio_shared/shared.dart';

import 'routine_composition_repository.dart';

/// Persistence boundary for user-owned Routines nested under Programs.
///
/// Composition and destructive/move lifecycle semantics are intentionally
/// absent until those product contracts are separately locked.
abstract interface class RoutineRepository {
  Future<List<Routine>> list(ProgramId programId);

  Future<void> create(Routine routine);

  Future<void> rename({
    required RoutineId id,
    required String name,
  });
}

/// One owner-scoped list-time snapshot. Revision is separate from the
/// canonical Routine identity and must be frozen before a metadata write.
final class RoutineMetadataRevision {
  RoutineMetadataRevision({required this.routine, required this.revision,
    required this.loginCycleId}) {
    if (revision < 0) throw ArgumentError.value(revision, 'revision');
    if (loginCycleId.trim().isEmpty) {
      throw ArgumentError.value(loginCycleId, 'loginCycleId');
    }
  }

  final Routine routine;
  final int revision;
  final String loginCycleId;
}

/// Optional protected metadata capability. Legacy RoutineRepository consumers
/// may still list/create, but cannot perform an unversioned rename.
abstract interface class RoutineVersionedRenameRepository {
  Future<List<RoutineMetadataRevision>> listVersioned(ProgramId programId);
  Future<int> renameVersioned(RoutineAggregateUpdate command, {
    required String expectedLoginCycleId,
  });
}
