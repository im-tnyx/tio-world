import 'package:flutter/services.dart';

/// Typing limits for the Workout Routine Set *draft* input surfaces.
///
/// These are input-hygiene boundaries, not new backend constraints:
/// Postgres Reps and Rest use signed int32; Weight has no domain maximum.
/// A compact Weight field permits up to six whole and three fractional
/// digits in either display unit, without adding a Flutter character counter.
abstract final class RoutineSetInputLimits {
  static const int maxInt32 = 2147483647;
  static const int maxIntegerDigits = 10;
  static const int maxRepsDigits = 6;
  static const int maxReps = 999999;
  static const int maxWeightWholeDigits = 6;
  static const int maxWeightFractionDigits = 3;

  static final RegExp _wholeNumberPattern = RegExp(r'^[0-9]{0,10}
  static final RegExp _weightPattern =
      RegExp(r'^[0-9]{0,6}(?:\.[0-9]{0,3})?$');

  /// Allows empty/zero drafts; the owning validator still requires Reps > 0.
  /// Rejects an invalid edit or pasted value without truncating a different
  /// number into something that could be persisted accidentally.
  static final TextInputFormatter int32 = TextInputFormatter.withFunction(
    (previous, proposed) {
      if (!_wholeNumberPattern.hasMatch(proposed.text)) return previous;
      if (proposed.text.isEmpty) return proposed;
      final value = int.tryParse(proposed.text);
      return value != null && value <= maxInt32 ? proposed : previous;
    },
  );

  /// Reps and range Min/Max use the same six whole-digit hygiene as Weight
  /// while keeping the database's int32 maximum as a separate safety bound.
  /// Invalid typing/pasting is rejected, never silently truncated.
  static final TextInputFormatter reps = TextInputFormatter.withFunction(
    (previous, proposed) {
      if (!_repsPattern.hasMatch(proposed.text)) return previous;
      if (proposed.text.isEmpty) return proposed;
      final value = int.tryParse(proposed.text);
      return value != null && value <= maxReps ? proposed : previous;
    },
  );

  /// KG/LB display only. Preserves transient blank and '.' input and rejects
  /// extra dots or precision beyond the visible three decimals.
  static final TextInputFormatter weight = TextInputFormatter.withFunction(
    (previous, proposed) =>
        _weightPattern.hasMatch(proposed.text) ? proposed : previous,
  );
}
);
  static final RegExp _repsPattern = RegExp(r'^[0-9]{0,6}
  static final RegExp _weightPattern =
      RegExp(r'^[0-9]{0,6}(?:\.[0-9]{0,3})?$');

  /// Allows empty/zero drafts; the owning validator still requires Reps > 0.
  /// Rejects an invalid edit or pasted value without truncating a different
  /// number into something that could be persisted accidentally.
  static final TextInputFormatter int32 = TextInputFormatter.withFunction(
    (previous, proposed) {
      if (!_wholeNumberPattern.hasMatch(proposed.text)) return previous;
      if (proposed.text.isEmpty) return proposed;
      final value = int.tryParse(proposed.text);
      return value != null && value <= maxInt32 ? proposed : previous;
    },
  );

  /// KG/LB display only. Preserves transient blank and '.' input and rejects
  /// extra dots or precision beyond the visible three decimals.
  static final TextInputFormatter weight = TextInputFormatter.withFunction(
    (previous, proposed) =>
        _weightPattern.hasMatch(proposed.text) ? proposed : previous,
  );
}
);
  static final RegExp _weightPattern =
      RegExp(r'^[0-9]{0,6}(?:\.[0-9]{0,3})?$');

  /// Allows empty/zero drafts; the owning validator still requires Reps > 0.
  /// Rejects an invalid edit or pasted value without truncating a different
  /// number into something that could be persisted accidentally.
  static final TextInputFormatter int32 = TextInputFormatter.withFunction(
    (previous, proposed) {
      if (!_wholeNumberPattern.hasMatch(proposed.text)) return previous;
      if (proposed.text.isEmpty) return proposed;
      final value = int.tryParse(proposed.text);
      return value != null && value <= maxInt32 ? proposed : previous;
    },
  );

  /// KG/LB display only. Preserves transient blank and '.' input and rejects
  /// extra dots or precision beyond the visible three decimals.
  static final TextInputFormatter weight = TextInputFormatter.withFunction(
    (previous, proposed) =>
        _weightPattern.hasMatch(proposed.text) ? proposed : previous,
  );
}
