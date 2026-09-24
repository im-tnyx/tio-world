import 'workout_id_validation.dart';

/// Canonical reference to one Exercise.
///
/// A reference is identity only. It never resolves catalog content, so a
/// Routine, PlannedWorkout or WorkoutSession can refer to an Exercise that the
/// current bundled catalog does not know yet. Title, slug and legacy/source
/// numeric IDs are lookup metadata and are never accepted as identity.
///
/// ```text
/// ExerciseRef
/// ├─ CatalogExerciseRef      built-in catalog Exercise, stable ex_* value
/// └─ UserCreatedExerciseRef  user-created Exercise, canonical UUID
/// ```
sealed class ExerciseRef {
  const ExerciseRef._();

  /// References a built-in catalog Exercise by its stable `ex_*` identity.
  factory ExerciseRef.catalog(String value) = CatalogExerciseRef;

  /// References a user-created Exercise by its UUID identity.
  factory ExerciseRef.userCreated(String value) = UserCreatedExerciseRef;

  /// Decodes a serialized reference produced by [value].
  ///
  /// The two identity formats cannot overlap: a UUID never starts with `ex_`.
  factory ExerciseRef.parse(String value) {
    if (isCatalogExerciseId(value)) return CatalogExerciseRef._(value);

    final uuid = canonicalUuidOrNull(value);
    if (uuid != null) return UserCreatedExerciseRef._(uuid);

    throw FormatException('Invalid ExerciseRef: $value.');
  }

  /// Canonical serialized identity.
  String get value;
}

/// Reference to a built-in catalog Exercise.
final class CatalogExerciseRef extends ExerciseRef {
  factory CatalogExerciseRef(String value) {
    if (!isCatalogExerciseId(value)) {
      throw ArgumentError.value(
        value,
        'value',
        'must be a catalog Exercise ID such as ex_barbell_bench_press',
      );
    }

    return CatalogExerciseRef._(value);
  }

  const CatalogExerciseRef._(this.value) : super._();

  @override
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogExerciseRef && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// Reference to a user-created Exercise.
///
/// Carries identity only; ownership and persistence belong to later slices.
final class UserCreatedExerciseRef extends ExerciseRef {
  factory UserCreatedExerciseRef(String value) =>
      UserCreatedExerciseRef._(requireCanonicalUuid(value, 'value'));

  const UserCreatedExerciseRef._(this.value) : super._();

  /// Lowercase canonical UUID.
  @override
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserCreatedExerciseRef && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
