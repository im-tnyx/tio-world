/// Stable persisted Custom Exercise measurement-profile identity.
///
/// Display labels and compact UI tags are presentation concerns. These values
/// are durable storage tokens only; they do not expand set execution semantics.
enum ExerciseType {
  weightReps('weight_reps'),
  distanceDuration('distance_duration'),
  duration('duration'),
  dumbbellX2Simultaneous('dumbbell_x2_simultaneous'),
  dumbbellX1AlternatingSides('dumbbell_x1_alternating_sides'),
  dumbbellX1Simultaneous('dumbbell_x1_simultaneous'),
  dumbbellX2AlternatingLegs('dumbbell_x2_alternating_legs'),
  dumbbellX1AlternatingLegs('dumbbell_x1_alternating_legs'),
  fullBodyweight('full_bodyweight'),
  assistedBodyweight('assisted_bodyweight'),
  stepsDuration('steps_duration');

  const ExerciseType(this.storageValue);

  final String storageValue;

  static ExerciseType fromStorageValue(String value) {
    for (final type in values) {
      if (type.storageValue == value) return type;
    }
    throw FormatException('Unknown Exercise type: $value');
  }
}
