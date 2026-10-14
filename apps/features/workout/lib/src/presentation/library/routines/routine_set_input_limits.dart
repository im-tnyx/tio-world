import 'package:flutter/services.dart';

/// Typing hygiene for Workout Routine Set drafts, independent of SQL bounds.
/// Reps targets are three whole digits; displayed KG/LB can use six whole
/// digits and three decimal digits. Invalid typing and paste are rejected
/// without silently truncating a value.
abstract final class RoutineSetInputLimits {
  static const int maxInt32 = 2147483647;
  static const int maxIntegerDigits = 10;
  static const int maxRepsDigits = 3;
  static const int maxReps = 999;
  static const int maxWeightWholeDigits = 6;
  static const int maxWeightFractionDigits = 3;

  static final RegExp _wholeNumberPattern = RegExp(r'^[0-9]{0,10}$');
  static final RegExp _repsPattern = RegExp(r'^[0-9]{0,3}$');
  static final RegExp _weightPattern =
      RegExp(r'^[0-9]{0,6}(?:\.[0-9]{0,3})?$');

  /// Rest remains bounded by int32 rather than the Reps-specific 3 digits.
  static final TextInputFormatter int32 = TextInputFormatter.withFunction(
    (previous, proposed) {
      if (!_wholeNumberPattern.hasMatch(proposed.text)) return previous;
      if (proposed.text.isEmpty) return proposed;
      final value = int.tryParse(proposed.text);
      return value != null && value <= maxInt32 ? proposed : previous;
    },
  );

  /// Reps/Range Min/Max: at most 3 whole digits, 000–999 as draft text.
  /// Whether a particular value is valid to persist is owned by the editor.
  static final TextInputFormatter reps = TextInputFormatter.withFunction(
    (previous, proposed) {
      if (!_repsPattern.hasMatch(proposed.text)) return previous;
      if (proposed.text.isEmpty) return proposed;
      final value = int.tryParse(proposed.text);
      return value != null && value <= maxReps ? proposed : previous;
    },
  );

  static final TextInputFormatter weight = TextInputFormatter.withFunction(
    (previous, proposed) =>
        _weightPattern.hasMatch(proposed.text) ? proposed : previous,
  );
}
