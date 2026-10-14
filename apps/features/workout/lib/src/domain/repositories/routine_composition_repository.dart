import 'package:tio_shared/shared.dart';

/// Persistence identity around an existing canonical prescription value.
final class RoutineCompositionSet {
  RoutineCompositionSet({required String id, required this.prescription})
      : id = _uuid(id) {
    if ((prescription.reps ?? 0) > 2147483647 ||
        (prescription.repsMax ?? 0) > 2147483647 ||
        (prescription.durationSeconds ?? 0) > 2147483647 ||
        (prescription.restSeconds ?? 0) > 2147483647) {
      throw ArgumentError('Prescription exceeds PostgreSQL integer range.');
    }
  }

  final String id;
  final SetPrescription prescription;

  @override
  bool operator ==(Object other) =>
      other is RoutineCompositionSet &&
      id == other.id &&
      prescription == other.prescription;

  @override
  int get hashCode => Object.hash(id, prescription);
}

/// Identified persistence envelope, not another canonical Exercise definition.
final class RoutineCompositionEntry {
  RoutineCompositionEntry({
    required String id,
    required this.exercise,
    List<RoutineCompositionSet> sets = const [],
  })  : id = _uuid(id),
        sets = List.unmodifiable(sets) {
    _unique(this.sets.map((set) => set.id));
  }

  final String id;
  final ExerciseRef exercise;
  final List<RoutineCompositionSet> sets;

  RoutineExercise get domain => RoutineExercise(
        exercise: exercise,
        sets: sets.map((set) => set.prescription).toList(growable: false),
      );

  @override
  bool operator ==(Object other) =>
      other is RoutineCompositionEntry &&
      id == other.id &&
      exercise == other.exercise &&
      _equal(sets, other.sets);

  @override
  int get hashCode => Object.hash(id, exercise, Object.hashAll(sets));
}

/// Complete, revision-validated owner snapshot; an empty draft is valid.
final class RoutineCompositionSnapshot {
  RoutineCompositionSnapshot({
    required this.routineId,
    required int revision,
    String? lastMutationId,
    List<RoutineCompositionEntry> entries = const [],
  })  : revision = _revision(revision),
        lastMutationId = lastMutationId == null ? null : _uuid(lastMutationId),
        entries = _entries(entries);

  final RoutineId routineId;
  final int revision;
  final String? lastMutationId;
  final List<RoutineCompositionEntry> entries;

  RoutineComposition get composition => RoutineComposition(
        routineId: routineId,
        exercises: entries.map((entry) => entry.domain).toList(growable: false),
      );

  bool hasSameContent(RoutineCompositionSave command) =>
      routineId == command.routineId && _equal(entries, command.entries);
}

/// Freeze once per logical mutation. Retry this exact object after uncertainty.
/// IDs are allocated by the caller when entries/sets are created, never by I/O.
final class RoutineCompositionSave {
  RoutineCompositionSave({
    required this.routineId,
    required int expectedRevision,
    required String mutationId,
    List<RoutineCompositionEntry> entries = const [],
  })  : expectedRevision = _revision(expectedRevision),
        mutationId = _uuid(mutationId),
        entries = _entries(entries);

  final RoutineId routineId;
  final int expectedRevision;
  final String mutationId;
  final List<RoutineCompositionEntry> entries;
}

enum RoutineCompositionFailureKind {
  unauthorized,
  forbidden,
  notFound,
  exerciseUnavailable,
  invalidRequest,
  revisionConflict,
  mutationConflict,
  integrityConflict,
  malformedData,
  readConflict,
  unavailable,
}

/// Sanitized failure category: never retains backend messages or health data.
final class RoutineCompositionException implements Exception {
  const RoutineCompositionException(this.kind);

  final RoutineCompositionFailureKind kind;

  @override
  String toString() => 'RoutineCompositionException(${kind.name})';
}

enum RoutineCompositionSaveUncertainty { unconfirmed, superseded, authChanged }

/// A request may have committed. This is not permission to start a new mutation.
final class RoutineCompositionSaveOutcomeUnknown implements Exception {
  const RoutineCompositionSaveOutcomeUnknown({
    this.reason = RoutineCompositionSaveUncertainty.unconfirmed,
    this.observedRevision,
  });

  final RoutineCompositionSaveUncertainty reason;
  final int? observedRevision;

  @override
  String toString() => 'RoutineCompositionSaveOutcomeUnknown(${reason.name})';
}

abstract interface class RoutineCompositionRepository {
  /// Null means an inaccessible/missing Routine, not a failed or partial read.
  /// Signed-out access fails before I/O. Independent requests are revision-
  /// validated, not one database transaction. Sustained contention can fail.
  Future<RoutineCompositionSnapshot?> read(RoutineId routineId);

  /// Calls the authenticated atomic RPC once. No implicit write retry/rebase.
  /// A valid server revision is authoritative, including idempotent replay.
  Future<int> save(RoutineCompositionSave command);
}

String _uuid(String value) {
  if (!RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
      .hasMatch(value)) {
    throw ArgumentError('Composition identity must be a canonical UUID.');
  }
  return value.toLowerCase();
}

int _revision(int value) {
  if (value < 0) throw ArgumentError('Revision must be nonnegative.');
  return value;
}

List<RoutineCompositionEntry> _entries(List<RoutineCompositionEntry> values) {
  final frozen = List<RoutineCompositionEntry>.unmodifiable(values);
  _unique(frozen.map((entry) => entry.id));
  _unique(frozen.expand((entry) => entry.sets).map((set) => set.id));
  return frozen;
}

void _unique(Iterable<String> ids) {
  final seen = <String>{};
  for (final id in ids) {
    if (!seen.add(id)) throw ArgumentError('Duplicate composition identity.');
  }
}

bool _equal<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
