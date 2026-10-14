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

  /// TIME text uses an explicit minutes:seconds target (e.g. 12:30).
  /// A partial field can remain visible while typing but blocks Save.
  /// At most 6 minute digits; even 999999:59 fits the int32 SQL contract.
  static final RegExp _timeDraftPattern =
      RegExp(r'^[0-9]{0,6}(?::[0-5]?[0-9]?)?$');
  static final RegExp _timeCompletePattern =
      RegExp(r'^([0-9]{1,6}):([0-5][0-9])$');
  static final TextInputFormatter time = TextInputFormatter.withFunction(
    (previous, proposed) => _timeDraftPattern.hasMatch(proposed.text)
        ? proposed
        : previous,
  );

  static int? parseDurationSeconds(String text) {
    final match = _timeCompletePattern.firstMatch(text.trim());
    if (match == null) return null;
    final minutes = int.tryParse(match.group(1)!);
    final seconds = int.tryParse(match.group(2)!);
    if (minutes == null || seconds == null) return null;
    final total = minutes * 60 + seconds;
    return total <= maxInt32 ? total : null;
  }

  static String displayDurationSeconds(int? seconds) {
    if (seconds == null) return '';
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  /// Canonical meters -> KM up to the governed 3-digit fractional UI cap.
  static String displayDistanceKm(double? meters) {
    if (meters == null) return '';
    return (meters / 1000).toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
