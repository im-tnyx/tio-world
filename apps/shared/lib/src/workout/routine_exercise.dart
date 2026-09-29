import 'exercise_ref.dart';
import 'set_prescription.dart';

/// One ordered Exercise entry inside a [RoutineComposition].
///
/// Repeated references to the same Exercise are allowed. Entry ordering is
/// carried by the containing list; this slice intentionally does not invent a
/// durable composition-row identity before composition persistence is designed.
final class RoutineExercise {
  RoutineExercise({
    required this.exercise,
    List<SetPrescription> sets = const [],
  }) : sets = List<SetPrescription>.unmodifiable(
          List<SetPrescription>.of(sets),
        );

  /// Canonical catalog or user-created Exercise identity.
  final ExerciseRef exercise;

  /// Ordered prescribed sets for this Exercise entry.
  ///
  /// An empty list is valid for an incomplete/draft Routine composition.
  final List<SetPrescription> sets;

  static bool _listsEqual(
    List<SetPrescription> a,
    List<SetPrescription> b,
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
      other is RoutineExercise &&
          other.exercise == exercise &&
          _listsEqual(other.sets, sets);

  @override
  int get hashCode => Object.hash(exercise, Object.hashAll(sets));
}
