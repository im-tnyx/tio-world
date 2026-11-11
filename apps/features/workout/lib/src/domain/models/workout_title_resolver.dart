/// Resolves the optional Save Workout title from the selected local date/time.
///
/// The fallback is evaluated only when Save is submitted. [selectedLocalDateTime]
/// must represent the wall-clock value currently shown by the Save Workout UI.
String resolveWorkoutTitle({
  required String? customTitle,
  required DateTime selectedLocalDateTime,
}) {
  final custom = customTitle?.trim() ?? '';
  if (custom.isNotEmpty) return custom;

  final label = switch (selectedLocalDateTime.hour) {
    >= 5 && < 12 => 'Morning',
    >= 12 && < 17 => 'Afternoon',
    >= 17 && < 21 => 'Evening',
    _ => 'Night',
  };
  return '$label Workout';
}
