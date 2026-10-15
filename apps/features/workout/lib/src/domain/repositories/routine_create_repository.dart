import 'package:tio_shared/shared.dart';

import 'routine_composition_repository.dart';

/// Immutable single-transaction Create command. The Routine and mutation IDs
/// are generated once, before network I/O, and never regenerated on retry.
final class RoutineCreateCommand {
  RoutineCreateCommand({
    required this.routine,
    required String mutationId,
    required List<RoutineCompositionEntry> entries,
    Map<String, ExerciseType?> expectedCustomTypes = const {},
  })  : expectedCustomTypes = Map.unmodifiable(expectedCustomTypes),
         mutationId = mutationId,
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
      expectedCustomTypes: expectedCustomTypes,
    );
  }

  final Routine routine;
  final String mutationId;
  final List<RoutineCompositionEntry> entries;
  final Map<String, ExerciseType?> expectedCustomTypes;

  /// Positive read-only evidence that this unique Routine ID was committed.
  /// Revision 1 must match the original mutation and complete payload.
  /// A later revision means the already-persisted Routine has since been
  /// edited; the original mutation/content no longer describe current truth.
  /// Caller must separately verify owning Program and authenticated session.
  bool confirmsPersistedRoutine(RoutineCompositionSnapshot snapshot) {
    if (snapshot.routineId != routine.id) return false;
    if (snapshot.revision > 1) {
      // The reviewed composition writer only advances revision through a
      // committed mutation. This confirms persistence, NOT original content.
      return snapshot.lastMutationId != null;
    }
    if (snapshot.revision != 1 || snapshot.lastMutationId != mutationId) {
      return false;
    }
    return snapshot.hasSameContent(RoutineCompositionSave(
      routineId: routine.id,
      expectedRevision: 0,
      mutationId: mutationId,
      entries: entries,
    ));
  }
}

/// Only the reviewed atomic Create RPC may fulfill this interface.
/// Direct metadata INSERT followed by composition Save is never valid.
abstract interface class RoutineCreateRepository {
  /// Returns canonical revision 1 after confirmed atomic Create.
  /// Transport uncertainty must be surfaced, never silently retried.
  Future<int> create(RoutineCreateCommand command);
}
