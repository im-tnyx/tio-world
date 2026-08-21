/// Canonical Body Goal values shared across app modes.
enum BodyGoalType {
  loseWeight,
  gainWeight,
  maintainWeight,
  recomposition,
}

extension BodyGoalTypeStorage on BodyGoalType {
  String get storageValue => switch (this) {
        BodyGoalType.loseWeight => 'lose_weight',
        BodyGoalType.gainWeight => 'gain_weight',
        BodyGoalType.maintainWeight => 'maintain_weight',
        BodyGoalType.recomposition => 'recomposition',
      };
}

/// Active Body Goal state persisted by the Body owner.
class BodyGoalSetupData {
  const BodyGoalSetupData({
    required this.goalType,
    this.targetWeightKg,
    this.weeklyWeightChangeKg,
    this.intentRank,
  });

  final BodyGoalType goalType;
  final double? targetWeightKg;
  final double? weeklyWeightChangeKg;

  /// Position of the Body intent in the unified Goal selection (1 = primary,
  /// 2 = supporting). Null is reserved for migrated/unknown ordering.
  final int? intentRank;
}

/// Completion-time Body data owned by Progress/Body persistence.
///
/// Current weight may be absent for compatibility with incomplete legacy
/// drafts. When present it is recorded without fabricating a default.
class BodySetupData {
  const BodySetupData({
    this.currentWeightKg,
    this.activeGoal,
  });

  final double? currentWeightKg;
  final BodyGoalSetupData? activeGoal;
}

/// Canonical setup-time Body persistence boundary.
abstract interface class BodySetupRepository {
  Future<void> saveBodySetup(BodySetupData data);
}
