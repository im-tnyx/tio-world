import 'dart:math' as math;

/// Quick Add / Quick Edit nutrition fields governed by the manual/coarse
/// amount policy.
enum ManualNutritionAmountField {
  calories,
  carbs,
  protein,
  fat,
}

/// Authoritative numeric limits for one manual/coarse nutrition field.
final class ManualNutritionAmountSpec {
  const ManualNutritionAmountSpec({
    required this.minimum,
    required this.maximum,
    required this.maximumFractionalDigits,
  });

  final num minimum;
  final num maximum;
  final int maximumFractionalDigits;
}

/// Why a manual/coarse nutrition amount is invalid.
enum ManualNutritionAmountError {
  invalidNumber,
  negative,
  aboveMaximum,
  excessPrecision,
}

/// Typed result for text validation at the presentation boundary.
final class ManualNutritionAmountValidation {
  const ManualNutritionAmountValidation.valid(this.value) : error = null;

  const ManualNutritionAmountValidation.invalid(this.error) : value = null;

  final num? value;
  final ManualNutritionAmountError? error;

  bool get isValid => error == null;
}

/// Shared V1 amount policy for manual/coarse Quick Add and Quick Edit facts.
///
/// This policy intentionally does not narrow the generic [NutritionSnapshot]
/// contract. It governs only the user-entered manual/coarse surface and is
/// consumed again at the mutation boundary so direct controller calls cannot
/// bypass the same limits.
final class ManualNutritionAmountPolicy {
  const ManualNutritionAmountPolicy._();

  // IEEE-754 double machine epsilon. Precision validation scales this by the
  // value magnitude and a small ULP budget so normal arithmetic noise is
  // accepted without turning meaningful hidden decimal tails into valid input.
  static const double _doubleEpsilon = 2.220446049250313e-16;
  static const double _precisionUlps = 8;

  static const ManualNutritionAmountSpec _caloriesSpec =
      ManualNutritionAmountSpec(
    minimum: 0,
    maximum: 10000,
    maximumFractionalDigits: 1,
  );

  static const ManualNutritionAmountSpec _macroSpec = ManualNutritionAmountSpec(
    minimum: 0,
    maximum: 1000,
    maximumFractionalDigits: 1,
  );

  static ManualNutritionAmountSpec specFor(ManualNutritionAmountField field) {
    return switch (field) {
      ManualNutritionAmountField.calories => _caloriesSpec,
      ManualNutritionAmountField.carbs ||
      ManualNutritionAmountField.protein ||
      ManualNutritionAmountField.fat => _macroSpec,
    };
  }

  /// Parses [text] without changing its numeric value, while enforcing the raw
  /// user-entered fractional-digit contract before numeric precision tolerance.
  /// Scientific notation is intentionally unsupported on this manual surface:
  /// it can hide effective fractional precision from the visible text.
  static ManualNutritionAmountValidation validateText({
    required ManualNutritionAmountField field,
    required String text,
  }) {
    final normalized = text.trim();
    final value = double.tryParse(normalized);
    if (value == null) {
      return const ManualNutritionAmountValidation.invalid(
        ManualNutritionAmountError.invalidNumber,
      );
    }

    final rangeError = _validateRange(field: field, value: value);
    if (rangeError != null) {
      return ManualNutritionAmountValidation.invalid(rangeError);
    }

    if (_usesExponentNotation(normalized)) {
      return const ManualNutritionAmountValidation.invalid(
        ManualNutritionAmountError.excessPrecision,
      );
    }

    final spec = specFor(field);
    if (_hasExcessTextPrecision(
      normalized,
      spec.maximumFractionalDigits,
    )) {
      return const ManualNutritionAmountValidation.invalid(
        ManualNutritionAmountError.excessPrecision,
      );
    }

    if (_hasExcessPrecision(value, spec.maximumFractionalDigits)) {
      return const ManualNutritionAmountValidation.invalid(
        ManualNutritionAmountError.excessPrecision,
      );
    }
    return ManualNutritionAmountValidation.valid(value);
  }

  /// Validates an already-parsed numeric value without quantizing or rounding
  /// it before persistence.
  static ManualNutritionAmountError? validateAmount({
    required ManualNutritionAmountField field,
    required num value,
  }) {
    final rangeError = _validateRange(field: field, value: value);
    if (rangeError != null) return rangeError;

    final spec = specFor(field);
    if (_hasExcessPrecision(value, spec.maximumFractionalDigits)) {
      return ManualNutritionAmountError.excessPrecision;
    }
    return null;
  }

  /// Returns a canonical editor string only for values already accepted by the
  /// numeric policy. This is for rehydrating durable values such as
  /// `0.1 + 0.2`, whose binary representation may stringify with a long tail.
  /// Invalid legacy values deliberately return null so callers can preserve the
  /// stored representation and continue blocking save until the user fixes it.
  static String? canonicalEditorText({
    required ManualNutritionAmountField field,
    required num value,
  }) {
    if (validateAmount(field: field, value: value) != null) return null;

    final spec = specFor(field);
    var text = value.toDouble().toStringAsFixed(spec.maximumFractionalDigits);
    if (text.contains('.')) {
      text = text.replaceFirst(RegExp(r'0+$'), '');
      text = text.replaceFirst(RegExp(r'\.$'), '');
    }
    return text;
  }

  /// Mutation-boundary validation for the four Quick Add / Quick Edit fields.
  /// Optional macros remain absent when null; explicit zero remains a value.
  static bool areAmountsValid({
    required num caloriesKcal,
    num? carbohydrateGrams,
    num? proteinGrams,
    num? fatGrams,
  }) {
    if (validateAmount(
          field: ManualNutritionAmountField.calories,
          value: caloriesKcal,
        ) !=
        null) {
      return false;
    }

    for (final candidate in <(ManualNutritionAmountField, num?)>[
      (ManualNutritionAmountField.carbs, carbohydrateGrams),
      (ManualNutritionAmountField.protein, proteinGrams),
      (ManualNutritionAmountField.fat, fatGrams),
    ]) {
      final value = candidate.$2;
      if (value != null &&
          validateAmount(field: candidate.$1, value: value) != null) {
        return false;
      }
    }
    return true;
  }

  static ManualNutritionAmountError? _validateRange({
    required ManualNutritionAmountField field,
    required num value,
  }) {
    if (!value.isFinite) return ManualNutritionAmountError.invalidNumber;

    final spec = specFor(field);
    if (value < spec.minimum) return ManualNutritionAmountError.negative;
    if (value > spec.maximum) {
      return ManualNutritionAmountError.aboveMaximum;
    }
    return null;
  }

  static bool _usesExponentNotation(String text) {
    return text.contains('e') || text.contains('E');
  }

  static bool _hasExcessTextPrecision(
    String text,
    int maximumFractionalDigits,
  ) {
    final decimalIndex = text.indexOf('.');
    if (decimalIndex < 0) return false;
    final fractionalDigits = text.length - decimalIndex - 1;
    return fractionalDigits > maximumFractionalDigits;
  }

  static bool _hasExcessPrecision(num value, int maximumFractionalDigits) {
    final scale = math.pow(10, maximumFractionalDigits).toDouble();
    final scaled = value.toDouble() * scale;
    final nearestInteger = scaled.roundToDouble();
    final difference = (scaled - nearestInteger).abs();
    final magnitude = math
        .max(1.0, math.max(scaled.abs(), nearestInteger.abs()))
        .toDouble();
    final tolerance = _precisionUlps * _doubleEpsilon * magnitude;
    return difference > tolerance;
  }
}
