/// Canonical lifecycle state of an Exercise.
///
/// Archiving keeps an Exercise resolvable for references and history; storage
/// and archive behavior belong to later persistence slices.
enum ExerciseStatus {
  active,
  archived,
}
