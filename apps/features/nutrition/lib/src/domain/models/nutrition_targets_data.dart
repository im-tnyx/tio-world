enum NutritionTargetCustomizationState {
  unknown,
  recommended,
  custom,
  mixed,
}

extension NutritionTargetCustomizationStateStorage
    on NutritionTargetCustomizationState {
  String get storageValue => switch (this) {
        NutritionTargetCustomizationState.unknown => 'unknown',
        NutritionTargetCustomizationState.recommended => 'recommended',
        NutritionTargetCustomizationState.custom => 'custom',
        NutritionTargetCustomizationState.mixed => 'mixed',
      };
}

NutritionTargetCustomizationState parseNutritionTargetCustomizationState(
  Object? raw,
) {
  return switch (raw) {
    'unknown' => NutritionTargetCustomizationState.unknown,
    'recommended' => NutritionTargetCustomizationState.recommended,
    'custom' => NutritionTargetCustomizationState.custom,
    'mixed' => NutritionTargetCustomizationState.mixed,
    _ => throw FormatException(
        'Invalid canonical Nutrition customization_state: $raw',
      ),
  };
}

/// Canonical daily Nutrition targets owned by `user_nutrition_targets`.
///
/// Null numeric values mean unknown/unset. Recommendation calculations may use
/// additional Body/Profile/Wellness inputs, but those inputs are not persisted
/// through this owner contract.
class NutritionTargetsData {
  const NutritionTargetsData({
    this.caloriesKcal,
    this.proteinGrams,
    this.carbohydrateGrams,
    this.fatGrams,
    this.fiberGrams,
    this.customizationState = NutritionTargetCustomizationState.unknown,
    this.customizedFields = const {},
    this.recommendationMetadata = const {},
  });

  final int? caloriesKcal;
  final double? proteinGrams;
  final double? carbohydrateGrams;
  final double? fatGrams;
  final double? fiberGrams;
  final NutritionTargetCustomizationState customizationState;
  final Set<String> customizedFields;
  final Map<String, Object?> recommendationMetadata;

  /// Mirrors live storage-level constraints without inventing narrower product
  /// or clinical ranges.
  void validate() {
    if (caloriesKcal != null && caloriesKcal! <= 0) {
      throw ArgumentError.value(
        caloriesKcal,
        'caloriesKcal',
        'Expected a positive value when present.',
      );
    }
    _requireNonnegativeFinite(proteinGrams, 'proteinGrams');
    _requireNonnegativeFinite(carbohydrateGrams, 'carbohydrateGrams');
    _requireNonnegativeFinite(fatGrams, 'fatGrams');
    _requireNonnegativeFinite(fiberGrams, 'fiberGrams');
  }
}

void _requireNonnegativeFinite(double? value, String name) {
  if (value != null && (!value.isFinite || value < 0)) {
    throw ArgumentError.value(
      value,
      name,
      'Expected a finite value greater than or equal to zero.',
    );
  }
}
