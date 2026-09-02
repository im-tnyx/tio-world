import 'package:tio_shared/shared.dart';

enum NutrientGoalType { maximum, target }

enum NutrientGoalComparison { atMost, lessThan, target }

enum AdditionalNutrientGoalWriteCapability { writable, unsupportedSchema }

/// One configured Additional Nutrient Goal.
///
/// Presence in [AdditionalNutrientGoalSet] means enabled. A null
/// [customValue] means "use the current recommendation"; a number, including
/// zero, is an explicit override.
final class AdditionalNutrientGoal {
  const AdditionalNutrientGoal({
    required this.nutrientId,
    this.customValue,
  });

  final NutrientId nutrientId;
  final double? customValue;

  bool get usesRecommendation => customValue == null;

  void validate() {
    if (!AdditionalNutrientGoalSet.authorizedNutrients.contains(nutrientId)) {
      throw ArgumentError.value(
        nutrientId,
        'nutrientId',
        'Nutrient is outside Additional Nutrient Goals V1.',
      );
    }
    final value = customValue;
    if (value != null && (!value.isFinite || value < 0)) {
      throw ArgumentError.value(
        value,
        'customValue',
        'Expected a finite nonnegative value.',
      );
    }
  }
}

/// Typed V1 goal configuration. Raw persistence JSON never enters this type.
final class AdditionalNutrientGoalSet {
  const AdditionalNutrientGoalSet.empty()
      : _goals = const {},
        writeCapability = AdditionalNutrientGoalWriteCapability.writable;

  const AdditionalNutrientGoalSet.unsupported()
      : _goals = const {},
        writeCapability =
            AdditionalNutrientGoalWriteCapability.unsupportedSchema;

  AdditionalNutrientGoalSet.fromGoals(
    Iterable<AdditionalNutrientGoal> goals, {
    this.writeCapability = AdditionalNutrientGoalWriteCapability.writable,
  }) : _goals = Map.unmodifiable({
          for (final goal in goals) goal.nutrientId: goal,
        }) {
    validate();
  }

  static const authorizedNutrients = <NutrientId>{
    NutrientId.saturatedFat,
    NutrientId.transFat,
    NutrientId.sodium,
    NutrientId.vitaminD,
  };

  final Map<NutrientId, AdditionalNutrientGoal> _goals;
  final AdditionalNutrientGoalWriteCapability writeCapability;

  Iterable<AdditionalNutrientGoal> get goals => _goals.values;
  bool get isWritable =>
      writeCapability == AdditionalNutrientGoalWriteCapability.writable;
  bool get isEmpty => _goals.isEmpty;

  AdditionalNutrientGoal? operator [](NutrientId nutrientId) =>
      _goals[nutrientId];

  bool contains(NutrientId nutrientId) => _goals.containsKey(nutrientId);

  AdditionalNutrientGoalSet withGoal(AdditionalNutrientGoal goal) {
    _requireWritable();
    goal.validate();
    return AdditionalNutrientGoalSet.fromGoals([
      ..._goals.values.where((candidate) => candidate.nutrientId != goal.nutrientId),
      goal,
    ]);
  }

  AdditionalNutrientGoalSet without(NutrientId nutrientId) {
    _requireWritable();
    return AdditionalNutrientGoalSet.fromGoals(
      _goals.values.where((goal) => goal.nutrientId != nutrientId),
    );
  }

  void validate() {
    if (!isWritable && _goals.isNotEmpty) {
      throw StateError('Unsupported Additional Nutrient Goals are read-only.');
    }
    for (final goal in _goals.values) {
      goal.validate();
    }
  }

  void _requireWritable() {
    if (!isWritable) {
      throw StateError(
        'This Additional Nutrient Goals schema is newer and read-only.',
      );
    }
  }
}

