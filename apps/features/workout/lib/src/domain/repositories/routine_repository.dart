import 'package:tio_shared/shared.dart';

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
