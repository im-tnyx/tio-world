import 'package:tio_shared/shared.dart';

import 'routine_composition_repository.dart';

/// Immutable single-transaction Create command. The Routine and mutation IDs
/// are generated once, before network I/O, and never regenerated on retry.
final class RoutineCreateCommand {
  RoutineCreateCommand({
    required this.routine,
    required String mutationId,
    required List<RoutineCompositionEntry> entries,
  })  : mutationId = mutationId,
        entries = List.unmodifiable(entries) {
    if (routine.name.trim().isEmpty || entries.isEmpty) {
      throw ArgumentError('Create requires a name and an Exercise.');
    }
    // The canonical value objects validate IDs/Set payloads; also enforce
    // global uniqueness across the entire new Routine composition.
    RoutineCompositionSave(
      routineId: routine.id,
      expectedRevision: 0,
      mutationId: mutationId,
      entries: entries,
    );
  }

  final Routine routine;
  final String mutationId;
  final List<RoutineCompositionEntry> entries;
}

/// Only the reviewed atomic Create RPC may fulfill this interface.
/// Direct metadata INSERT followed by composition Save is never valid.
abstract interface class RoutineCreateRepository {
  /// Returns canonical revision 1 after confirmed atomic Create.
  /// Transport uncertainty must be surfaced, never silently retried.
  Future<int> create(RoutineCreateCommand command);
}
