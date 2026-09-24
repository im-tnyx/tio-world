import 'package:tio_shared/shared.dart';

/// Validated built-in Exercise catalog of canonical [Exercise] values.
///
/// [all] keeps every Exercise, including archived ones, in deterministic
/// display order: display name ignoring case, then [ExerciseRef] value.
/// Browse and search consumers use `ExerciseCatalogQuery`, which hides
/// archived exercises.
final class ExerciseCatalog {
  factory ExerciseCatalog(Iterable<Exercise> exercises) {
    final byRef = <ExerciseRef, Exercise>{};
    for (final exercise in exercises) {
      if (byRef.containsKey(exercise.ref)) {
        throw ArgumentError.value(
          exercise.ref.value,
          'exercises',
          'must not contain duplicate ExerciseRefs',
        );
      }
      byRef[exercise.ref] = exercise;
    }

    final ordered = byRef.values.toList()..sort(_compareForDisplay);
    return ExerciseCatalog._(
      List<Exercise>.unmodifiable(ordered),
      Map<ExerciseRef, Exercise>.unmodifiable(byRef),
    );
  }

  const ExerciseCatalog._(this.all, this._byRef);

  final List<Exercise> all;
  final Map<ExerciseRef, Exercise> _byRef;

  bool get isEmpty => all.isEmpty;

  Exercise? byRef(ExerciseRef ref) => _byRef[ref];

  static int _compareForDisplay(Exercise a, Exercise b) {
    final byName =
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    if (byName != 0) return byName;
    return a.ref.value.compareTo(b.ref.value);
  }
}
