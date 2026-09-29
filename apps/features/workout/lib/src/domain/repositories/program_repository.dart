import 'package:tio_shared/shared.dart';

/// Persistence boundary for user-owned Programs.
///
/// Program lifecycle deletion/archive semantics are intentionally absent until
/// that product contract is separately locked.
abstract interface class ProgramRepository {
  Future<List<Program>> list();

  Future<void> create(Program program);

  Future<void> rename({
    required ProgramId id,
    required String name,
  });
}
