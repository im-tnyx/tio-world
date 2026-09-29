import 'routine_exercise.dart';
import 'routine_id.dart';

/// Canonical ordered composition for one Routine.
///
/// Composition is intentionally separate from the currently persisted minimal
/// `Routine(id, programId, name)` entity. Existing Routine persistence does not
/// store Exercise/set composition yet, so keeping this value contract separate
/// prevents callers from assuming composition is already durable.
final class RoutineComposition {
  RoutineComposition({
    required this.routineId,
    List<RoutineExercise> exercises = const [],
  }) : exercises = List<RoutineExercise>.unmodifiable(
          List<RoutineExercise>.of(exercises),
        );

  /// Identity of the Routine whose template this composition describes.
  final RoutineId routineId;

  /// Ordered Exercise entries.
  ///
  /// The same Exercise may appear more than once. An empty list is valid until
  /// a later builder/execution-readiness policy requires otherwise.
  final List<RoutineExercise> exercises;

  static bool _listsEqual(
    List<RoutineExercise> a,
    List<RoutineExercise> b,
  ) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutineComposition &&
          other.routineId == routineId &&
          _listsEqual(other.exercises, exercises);

  @override
  int get hashCode => Object.hash(routineId, Object.hashAll(exercises));
}
