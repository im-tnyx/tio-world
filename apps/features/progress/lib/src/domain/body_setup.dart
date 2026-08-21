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

/// Active Body Goal data used during onboarding setup persistence.
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

/// One canonical current-weight/history entry.
class BodyWeightEntry {
  const BodyWeightEntry({
    required this.weightKg,
    required this.measuredAt,
    this.source,
  });

  final double weightKg;
  final DateTime measuredAt;

  /// Provenance such as `onboarding_setup`, `profile_settings`, or a future
  /// backend/device source. Null is preserved for legacy rows rather than
  /// inventing provenance.
  final String? source;
}

/// Explicit command payload for recording a new post-onboarding weight row.
class BodyWeightRecord {
  const BodyWeightRecord({
    required this.weightKg,
    required this.measuredAt,
    required this.source,
  });

  final double weightKg;
  final DateTime measuredAt;
  final String source;
}

/// Canonical active Body Goal read model.
class BodyGoalState {
  const BodyGoalState({
    required this.goalType,
    this.startingWeightKg,
    this.targetWeightKg,
    this.weeklyWeightChangeKg,
    this.intentRank,
    this.startedAt,
  });

  final BodyGoalType goalType;
  final double? startingWeightKg;
  final double? targetWeightKg;
  final double? weeklyWeightChangeKg;
  final int? intentRank;
  final DateTime? startedAt;
}

/// Canonical Body state. Missing values remain null/unknown; repositories must
/// never fabricate a current weight or infer a Body Goal from numeric state.
class BodyState {
  const BodyState({
    this.latestWeight,
    this.activeGoal,
  });

  final BodyWeightEntry? latestWeight;
  final BodyGoalState? activeGoal;
}

/// Narrow onboarding setup persistence boundary.
///
/// Keeping this interface small lets onboarding persist the Body owner without
/// depending on post-onboarding read/history commands.
abstract interface class BodySetupRepository {
  Future<void> saveBodySetup(BodySetupData data);
}

/// Full canonical Body owner contract used by app-level composition after
/// onboarding. The domain API is backend-neutral; Supabase table details stay
/// inside the data adapter.
abstract interface class BodyRepository implements BodySetupRepository {
  Future<BodyState> getBodyState();

  /// Records a new history row. This is intentionally separate from
  /// [saveBodySetup], whose onboarding retry semantics may reconcile a single
  /// onboarding snapshot instead of appending uncontrolled duplicates.
  Future<void> recordCurrentWeight(BodyWeightRecord record);
}
