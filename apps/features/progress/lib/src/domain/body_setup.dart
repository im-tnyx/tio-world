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

/// Stable semantic provenance values for canonical Body weight history.
///
/// These values are part of the Body domain contract and can be reused by a
/// future backend adapter; they are not Supabase table names.
abstract final class BodyWeightSources {
  static const onboardingSetup = 'onboarding_setup';
  static const profileSettings = 'profile_settings';
  static const bodyWeightSettings = 'body_weight_settings';
  static const manual = 'manual';
}

/// Post-onboarding Body Goal mutation payload.
///
/// Carries only user-editable goal state. Settings must never supply
/// [startingWeightKg]/`startedAt`/row identity/status — those remain owned by
/// [BodyRepository.setActiveBodyGoal]'s reconciliation logic so a Settings
/// caller cannot fabricate or corrupt goal-lifecycle history.
class BodyGoalUpdate {
  const BodyGoalUpdate({
    required this.goalType,
    this.targetWeightKg,
    this.weeklyWeightChangeKg,
  });

  final BodyGoalType goalType;
  final double? targetWeightKg;
  final double? weeklyWeightChangeKg;
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
    this.id,
    this.source,
  });

  /// Stable row identity; older current-state consumers may omit it.
  /// Every entry returned by the history API has a non-null UUID.
  final String? id;
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


abstract final class BodyWeightLogIds {
  static final RegExp _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}
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

  /// Records a new post-onboarding history row. `onboarding_setup` is reserved
  /// for [saveBodySetup] retry/reconciliation semantics and must be rejected by
  /// this command.
  Future<void> recordCurrentWeight(BodyWeightRecord record);

  /// Owner-scoped history ordered by measured_at DESC, id DESC.
  /// Signed-out reads return an empty page, never cached private data.
  Future<BodyWeightHistoryPage> getWeightHistory(BodyWeightHistoryQuery query);

  /// Returns false when the row is absent or inaccessible.
  Future<bool> updateWeightLog(BodyWeightLogEdit edit);

  /// Delete one exact row; user confirmation belongs to the later UI slice.
  Future<bool> deleteWeightLog(String id);

  /// Post-onboarding Body Goal mutation command.
  ///
  /// Same goal type as the current active goal: updates the existing active
  /// goal's target/pace in place, preserving row identity, `starting_weight_kg`
  /// (including a historical null), `started_at`, and `intent_rank`.
  ///
  /// Changed goal type: supersedes the previous active goal and creates a new
  /// active goal, snapshotting `starting_weight_kg` from the latest canonical
  /// weight when available and preserving the previous `intent_rank` when
  /// present. A directional (`loseWeight`/`gainWeight`) new goal requires a
  /// real canonical current weight to snapshot as its starting weight; when
  /// none exists, the command rejects rather than fabricating one.
  ///
  /// [update.goalType] must be `loseWeight`, `gainWeight`, or `maintainWeight`.
  /// `recomposition` is legacy decode/display-only and is rejected here.
  Future<void> setActiveBodyGoal(BodyGoalUpdate update);
}
,
  );

  static void requireValid(String id) {
    if (!_uuid.hasMatch(id)) {
      throw ArgumentError.value(id, 'id', 'Expected a weight measurement UUID.');
    }
  }
}

/// Strict keyset boundary: (measuredAt DESC, id DESC).
class BodyWeightHistoryCursor {
  const BodyWeightHistoryCursor({required this.measuredAt, required this.id});

  final DateTime measuredAt;
  final String id;
}

/// Instants, not calendar dates. The window is [fromInclusive, toExclusive).
/// The caller converts selected local calendar boundaries to absolute instants.
class BodyWeightHistoryQuery {
  const BodyWeightHistoryQuery({
    required this.fromInclusive,
    required this.toExclusive,
    this.limit = 30,
    this.before,
  });

  final DateTime fromInclusive;
  final DateTime toExclusive;
  final int limit;
  final BodyWeightHistoryCursor? before;

  void validate() {
    if (!fromInclusive.isBefore(toExclusive)) {
      throw ArgumentError('Weight history requires a positive date range.');
    }
    if (limit < 1 || limit > 100) {
      throw ArgumentError.value(limit, 'limit', 'Expected 1..100.');
    }
    final cursor = before;
    if (cursor != null) {
      BodyWeightLogIds.requireValid(cursor.id);
      if (cursor.measuredAt.isBefore(fromInclusive) ||
          !cursor.measuredAt.isBefore(toExclusive)) {
        throw ArgumentError('Weight history cursor is outside the date range.');
      }
    }
  }
}

/// A cursor is present only if more records were observed. All entries have IDs.
class BodyWeightHistoryPage {
  const BodyWeightHistoryPage({required this.entries, this.nextCursor});

  final List<BodyWeightEntry> entries;
  final BodyWeightHistoryCursor? nextCursor;
}

/// Updates only measurement values on the exact owned ID; never reassigns owner,
/// source, metadata, or Body Goal snapshot.
class BodyWeightLogEdit {
  const BodyWeightLogEdit({
    required this.id,
    required this.weightKg,
    required this.measuredAt,
  });

  final String id;
  final double weightKg;
  final DateTime measuredAt;

  void validate() {
    BodyWeightLogIds.requireValid(id);
    if (!weightKg.isFinite || weightKg <= 0) {
      throw ArgumentError.value(
        weightKg, 'weightKg', 'Must be positive and finite.',
      );
    }
  }
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

  /// Records a new post-onboarding history row. `onboarding_setup` is reserved
  /// for [saveBodySetup] retry/reconciliation semantics and must be rejected by
  /// this command.
  Future<void> recordCurrentWeight(BodyWeightRecord record);

  /// Post-onboarding Body Goal mutation command.
  ///
  /// Same goal type as the current active goal: updates the existing active
  /// goal's target/pace in place, preserving row identity, `starting_weight_kg`
  /// (including a historical null), `started_at`, and `intent_rank`.
  ///
  /// Changed goal type: supersedes the previous active goal and creates a new
  /// active goal, snapshotting `starting_weight_kg` from the latest canonical
  /// weight when available and preserving the previous `intent_rank` when
  /// present. A directional (`loseWeight`/`gainWeight`) new goal requires a
  /// real canonical current weight to snapshot as its starting weight; when
  /// none exists, the command rejects rather than fabricating one.
  ///
  /// [update.goalType] must be `loseWeight`, `gainWeight`, or `maintainWeight`.
  /// `recomposition` is legacy decode/display-only and is rejected here.
  Future<void> setActiveBodyGoal(BodyGoalUpdate update);
}
