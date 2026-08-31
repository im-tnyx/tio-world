import '../models/nutrition_target_field.dart';
import '../models/nutrition_targets_data.dart';

/// Outcome of checking whether a target set is internally coherent.
class NutritionTargetCoherence {
  const NutritionTargetCoherence._({
    required this.isEvaluable,
    required this.macroCalories,
    required this.targetCalories,
  });

  /// The relationship is undefined until Calories and all three macros exist.
  const NutritionTargetCoherence.notEvaluable()
      : this._(isEvaluable: false, macroCalories: null, targetCalories: null);

  final bool isEvaluable;
  final double? macroCalories;
  final int? targetCalories;

  /// Absolute distance between the calorie target and what the macros imply.
  double? get differenceKcal {
    if (!isEvaluable) return null;
    return (macroCalories! - targetCalories!).abs();
  }

  /// Beyond the tolerance the row is materially inconsistent and cannot save.
  ///
  /// A partial row is never blocked: with any of the four values missing there
  /// is nothing to compare, and treating a null as zero would fabricate a value
  /// and produce a false block.
  bool get blocksSave {
    if (!isEvaluable) return false;
    return differenceKcal! > NutritionTargetEditor.coherenceToleranceKcal;
  }
}

/// Pure editing rules for the core five Nutrition Targets.
///
/// Kept out of the widget layer so the provenance and coherence contracts can
/// be exercised directly, without pumping a screen.
abstract final class NutritionTargetEditor {
  /// Allowed drift between the calorie target and macro-derived calories.
  ///
  /// The recommendation rounds each macro independently, so rows written by
  /// onboarding already sit a few kcal off exact. Requiring equality would flag
  /// every shipped `recommended` row as invalid the first time it was opened.
  static const coherenceToleranceKcal = 5;

  static const _proteinKcalPerGram = 4;
  static const _carbohydrateKcalPerGram = 4;
  static const _fatKcalPerGram = 9;

  /// Fiber is deliberately excluded: it is an independent target, not part of
  /// the energy relationship between calories and the three macros.
  static NutritionTargetCoherence coherenceOf(NutritionTargetsData targets) {
    final calories = targets.caloriesKcal;
    final protein = targets.proteinGrams;
    final carbohydrate = targets.carbohydrateGrams;
    final fat = targets.fatGrams;

    if (calories == null ||
        protein == null ||
        carbohydrate == null ||
        fat == null) {
      return const NutritionTargetCoherence.notEvaluable();
    }

    final macroCalories = (protein * _proteinKcalPerGram) +
        (carbohydrate * _carbohydrateKcalPerGram) +
        (fat * _fatKcalPerGram);

    return NutritionTargetCoherence._(
      isEvaluable: true,
      macroCalories: macroCalories,
      targetCalories: calories,
    );
  }

  /// Current value of [field], or null when unset.
  static num? valueOf(
      NutritionTargetsData targets, NutritionTargetField field) {
    return switch (field) {
      NutritionTargetField.calories => targets.caloriesKcal,
      NutritionTargetField.protein => targets.proteinGrams,
      NutritionTargetField.carbohydrate => targets.carbohydrateGrams,
      NutritionTargetField.fat => targets.fatGrams,
      NutritionTargetField.fiber => targets.fiberGrams,
    };
  }

  /// Applies one explicit user edit, preserving everything else exactly.
  ///
  /// The repository's `upsert` replaces the whole row, so this rebuilds the
  /// complete object rather than mutating a field: every untouched target,
  /// `recommendationMetadata`, and previously recorded custom intent survive.
  static NutritionTargetsData applyEdit(
    NutritionTargetsData current, {
    required NutritionTargetField field,
    required num? value,
  }) {
    final customizedFields = <String>{
      ...current.customizedFields,
      // Custom intent only ever accumulates here. A user typing a value that
      // happens to equal an old recommendation has still made that field their
      // own; only an explicit Reset-to-Recommended flow may clear it.
      field.storageValue,
    };

    final next = NutritionTargetsData(
      caloriesKcal: field == NutritionTargetField.calories
          ? value?.round()
          : current.caloriesKcal,
      proteinGrams: field == NutritionTargetField.protein
          ? value?.toDouble()
          : current.proteinGrams,
      carbohydrateGrams: field == NutritionTargetField.carbohydrate
          ? value?.toDouble()
          : current.carbohydrateGrams,
      fatGrams: field == NutritionTargetField.fat
          ? value?.toDouble()
          : current.fatGrams,
      fiberGrams: field == NutritionTargetField.fiber
          ? value?.toDouble()
          : current.fiberGrams,
      customizationState: current.customizationState,
      customizedFields: customizedFields,
      // Never rewritten by an edit. Regenerating or clearing it would destroy
      // the provenance of the original recommendation.
      recommendationMetadata: current.recommendationMetadata,
    );

    return NutritionTargetsData(
      caloriesKcal: next.caloriesKcal,
      proteinGrams: next.proteinGrams,
      carbohydrateGrams: next.carbohydrateGrams,
      fatGrams: next.fatGrams,
      fiberGrams: next.fiberGrams,
      customizationState: _resolveState(next),
      customizedFields: customizedFields,
      recommendationMetadata: next.recommendationMetadata,
    );
  }

  /// Resolves provenance from the resulting row.
  ///
  /// Evaluated against what is actually persisted, so filling or clearing a
  /// field is accounted for rather than judged against a stale pre-edit view.
  static NutritionTargetCustomizationState _resolveState(
    NutritionTargetsData resulting,
  ) {
    final populated = NutritionTargetField.values
        .where((field) => valueOf(resulting, field) != null)
        .toList(growable: false);

    final customized = resulting.customizedFields;

    // Every value the row actually holds is the user's own.
    if (populated.isNotEmpty &&
        populated.every((field) => customized.contains(field.storageValue))) {
      return NutritionTargetCustomizationState.custom;
    }

    // Some recommended values survive alongside the user's edits.
    if (customized.isNotEmpty) {
      return NutritionTargetCustomizationState.mixed;
    }

    return resulting.customizationState;
  }
}
