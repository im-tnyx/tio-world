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

  static const double _precisionTolerance = 1e-9;

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

  /// Parses [text] without changing its numeric value, then applies the same
  /// amount policy used by mutation controllers.
  static ManualNutritionAmountValidation validateText({
    required ManualNutritionAmountField field,
    required String text,
  }) {
    final value = double.tryParse(text.trim());
    if (value == null) {
      return const ManualNutritionAmountValidation.invalid(
        ManualNutritionAmountError.invalidNumber,
      );
    }
    final error = validateAmount(field: field, value: value);
    if (error != null) return ManualNutritionAmountValidation.invalid(error);
    return ManualNutritionAmountValidation.valid(value);
  }

  /// Validates an already-parsed numeric value without quantizing or rounding
  /// it before persistence.
  static ManualNutritionAmountError? validateAmount({
    required ManualNutritionAmountField field,
    required num value,
  }) {
    if (!value.isFinite) return ManualNutritionAmountError.invalidNumber;

    final spec = specFor(field);
    if (value < spec.minimum) return ManualNutritionAmountError.negative;
    if (value > spec.maximum) {
      return ManualNutritionAmountError.aboveMaximum;
    }
    if (_hasExcessPrecision(value, spec.maximumFractionalDigits)) {
      return ManualNutritionAmountError.excessPrecision;
    }
    return null;
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

  static bool _hasExcessPrecision(num value, int maximumFractionalDigits) {
    final scale = math.pow(10, maximumFractionalDigits).toDouble();
    final scaled = value.toDouble() * scale;
    final nearestInteger = scaled.roundToDouble();
    return (scaled - nearestInteger).abs() > _precisionTolerance;
  }
}
