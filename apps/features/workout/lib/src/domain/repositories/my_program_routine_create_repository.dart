import 'package:tio_shared/shared.dart';

import 'routine_composition_repository.dart';

/// Immutable programless Create command for the *server-owned* My Program.
///
/// This command deliberately has no ProgramId: a default Program may not yet
/// exist when an owner opens Library Create. Only the atomic server RPC may
/// resolve/create it; no placeholder Program or separate client INSERT is legal.
final class MyProgramRoutineCreateCommand {
  MyProgramRoutineCreateCommand({
    required this.routineId,
    required String name,
    required String mutationId,
    required List<RoutineCompositionEntry> entries,
    Map<String, ExerciseType?> expectedCustomTypes = const {},
  })  : name = name.trim(),
        // The canonical composer normalizes a validated UUID to lowercase.
        // Persist that identity so read-back confirmation can match the RPC.
        mutationId = RoutineCompositionSave(
          routineId: routineId,
          expectedRevision: 0,
          mutationId: mutationId,
          entries: entries,
          expectedCustomTypes: expectedCustomTypes,
        ).mutationId,
        entries = List.unmodifiable(entries),
        expectedCustomTypes = Map.unmodifiable(expectedCustomTypes) {
    // A nonempty Exercise without Sets passes the basic composition envelope
    // but the atomic #568 RPC rejects it. Block it before any dispatch.
    if (this.name.isEmpty || this.entries.isEmpty ||
        this.entries.any((entry) => entry.sets.isEmpty)) {
      throw ArgumentError('Create requires a name, Exercise and Set.');
    }
  }

  final RoutineId routineId;
  final String name;
  final String mutationId;
  final List<RoutineCompositionEntry> entries;
  final Map<String, ExerciseType?> expectedCustomTypes;

  /// Positive composition evidence only. The caller must also prove that the
  /// Routine belongs to the authenticated owner's is_default Program; never
  /// infer ownership from a matching mutable Program display name.
  bool confirmsPersistedRoutine(RoutineCompositionSnapshot snapshot) {
    if (snapshot.routineId != routineId) return false;
    // A later revision may have been created by a different mutation.
    // Without a server-verified history chain, it cannot prove that this
    // particular pending Create committed; fail closed on superseded state.
    if (snapshot.revision > 1) return false;
    if (snapshot.revision != 1 || snapshot.lastMutationId != mutationId) {
      return false;
    }
    return snapshot.hasSameContent(RoutineCompositionSave(
      routineId: routineId,
      expectedRevision: 0,
      mutationId: mutationId,
      entries: entries,
    ));
  }
}

/// ACK from the atomic default resolver. Never treat a non-ACK, malformed
/// response or a mere owner/name match as proof of persisted Routine identity.
final class MyProgramRoutineCreateReceipt {
  MyProgramRoutineCreateReceipt({
    required this.programId,
    required this.compositionRevision,
  }) {
    if (compositionRevision != 1) {
      throw ArgumentError.value(
          compositionRevision, 'compositionRevision', 'Expected revision 1');
    }
  }

  final ProgramId programId;
  final int compositionRevision;
}

/// Staged first-Routine RPC capability. The hosted EXECUTE grant is withheld
/// until full Flutter pending/UNKNOWN reconciliation and release QA are ready.
abstract interface class MyProgramRoutineCreateRepository {
  /// Sends exactly one transaction request. No automatic retry or fallback.
  /// If ACK is lost, caller must preserve this command and reconcile by reads.
  Future<MyProgramRoutineCreateReceipt> createInMyProgram(
      MyProgramRoutineCreateCommand command);
}
