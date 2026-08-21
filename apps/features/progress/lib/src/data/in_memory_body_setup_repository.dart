import '../domain/body_setup.dart';

/// Non-durable fallback for tests/local harnesses without an initialized
/// Supabase client. Production persistence uses [SupabaseBodySetupRepository].
class InMemoryBodySetupRepository implements BodyRepository {
  InMemoryBodySetupRepository({DateTime Function()? now})
      : _now = now ?? DateTime.now;

  static const _onboardingWeightSource = 'onboarding_setup';

  final DateTime Function() _now;
  final List<BodyWeightEntry> _weightEntries = <BodyWeightEntry>[];

  BodySetupData? _data;
  BodyGoalState? _activeGoal;

  BodySetupData? get data => _data;
  List<BodyWeightEntry> get weightEntries => List.unmodifiable(_weightEntries);

  @override
  Future<void> saveBodySetup(BodySetupData data) async {
    _validateSetup(data);
    _data = data;
    final now = _now().toUtc();

    final currentWeight = data.currentWeightKg;
    if (currentWeight != null) {
      final onboardingIndex = _weightEntries.lastIndexWhere(
        (entry) => entry.source == _onboardingWeightSource,
      );
      final entry = BodyWeightEntry(
        weightKg: currentWeight,
        measuredAt: now,
        source: _onboardingWeightSource,
      );
      if (onboardingIndex == -1) {
        _weightEntries.add(entry);
      } else {
        _weightEntries[onboardingIndex] = entry;
      }
    }

    final requested = data.activeGoal;
    if (requested == null) {
      _activeGoal = null;
      return;
    }

    final previous = _activeGoal;
    final sameGoalType = previous?.goalType == requested.goalType;
    _activeGoal = BodyGoalState(
      goalType: requested.goalType,
      startingWeightKg: sameGoalType
          ? previous?.startingWeightKg ?? data.currentWeightKg
          : data.currentWeightKg,
      targetWeightKg: requested.targetWeightKg,
      weeklyWeightChangeKg: requested.weeklyWeightChangeKg,
      intentRank: requested.intentRank,
      startedAt: sameGoalType ? previous?.startedAt ?? now : now,
    );
  }

  @override
  Future<BodyState> getBodyState() async {
    BodyWeightEntry? latestWeight;
    for (final entry in _weightEntries) {
      final current = latestWeight;
      if (current == null || entry.measuredAt.isAfter(current.measuredAt)) {
        latestWeight = entry;
      }
    }
    return BodyState(
      latestWeight: latestWeight,
      activeGoal: _activeGoal,
    );
  }

  @override
  Future<void> recordCurrentWeight(BodyWeightRecord record) async {
    _validateWeightRecord(record);
    _weightEntries.add(
      BodyWeightEntry(
        weightKg: record.weightKg,
        measuredAt: record.measuredAt.toUtc(),
        source: record.source.trim(),
      ),
    );
  }

  void _validateSetup(BodySetupData data) {
    final currentWeight = data.currentWeightKg;
    if (currentWeight != null && currentWeight <= 0) {
      throw ArgumentError.value(
        currentWeight,
        'currentWeightKg',
        'Current weight must be greater than zero.',
      );
    }
    final goal = data.activeGoal;
    if (goal == null) return;

    final rank = goal.intentRank;
    if (rank != null && rank != 1 && rank != 2) {
      throw ArgumentError.value(rank, 'intentRank', 'Expected 1, 2, or null.');
    }
    final target = goal.targetWeightKg;
    if (target != null && target <= 0) {
      throw ArgumentError.value(
        target,
        'targetWeightKg',
        'Target weight must be greater than zero.',
      );
    }
    final pace = goal.weeklyWeightChangeKg;
    if (pace != null && pace < 0) {
      throw ArgumentError.value(
        pace,
        'weeklyWeightChangeKg',
        'Goal pace must be nonnegative.',
      );
    }
    final isDirectional = goal.goalType == BodyGoalType.loseWeight ||
        goal.goalType == BodyGoalType.gainWeight;
    if (!isDirectional && (target != null || pace != null)) {
      throw ArgumentError(
        'Maintain/Recomposition cannot persist Target Weight or Goal Pace.',
      );
    }
  }

  void _validateWeightRecord(BodyWeightRecord record) {
    if (record.weightKg <= 0) {
      throw ArgumentError.value(
        record.weightKg,
        'weightKg',
        'Current weight must be greater than zero.',
      );
    }
    if (record.source.trim().isEmpty) {
      throw ArgumentError.value(
        record.source,
        'source',
        'Weight provenance source is required.',
      );
    }
  }
}
