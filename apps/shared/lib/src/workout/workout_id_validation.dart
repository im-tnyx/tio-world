// Internal syntax checks shared by the Workout identity value objects.
//
// Deliberately not exported by `workout.dart`: callers construct the typed
// value objects instead of validating raw strings themselves.

/// Built-in catalog Exercise identity: `ex_` followed by one or more
/// lowercase alphanumeric segments separated by single underscores.
final _catalogExerciseId = RegExp(r'^ex_[a-z0-9]+(?:_[a-z0-9]+)*$');

/// Canonical UUID text, version-agnostic, either letter case.
final _canonicalUuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Whether [value] is a well-formed built-in catalog Exercise identity.
///
/// Syntax only: a well-formed identity absent from the bundled catalog is
/// still valid, so an older client can hold a reference to a newer Exercise.
bool isCatalogExerciseId(String value) => _catalogExerciseId.hasMatch(value);

/// Returns the lowercase canonical form of [value], or `null` when [value] is
/// not canonical UUID text. Surrounding whitespace is never trimmed.
String? canonicalUuidOrNull(String value) =>
    _canonicalUuid.hasMatch(value) ? value.toLowerCase() : null;

/// Returns the lowercase canonical UUID for [value] or throws an
/// [ArgumentError] naming [name].
String requireCanonicalUuid(String value, String name) {
  final canonical = canonicalUuidOrNull(value);
  if (canonical == null) {
    throw ArgumentError.value(value, name, 'must be a canonical UUID string');
  }
  return canonical;
}
