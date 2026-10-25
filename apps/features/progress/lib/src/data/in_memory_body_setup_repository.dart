import '../domain/body_setup.dart';

/// Non-durable fallback for tests/local harnesses without an initialized
/// Supabase client. Production persistence uses [SupabaseBodySetupRepository].
class InMemoryBodySetupRepository implements BodyRepository {
  InMemoryBodySetupRepository({DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final List<BodyWeightEntry> _weightEntries = <BodyWeightEntry>[];
  int _nextWeightLogId = 0;

  String _newWeightLogId() {
    _nextWeightLogId++;
    return '00000000-0000-4000-8000-${_nextWeightLogId.toString().padLeft(12, '0')}';
  }

  BodySetupData? _data;
  BodyGoalState? _activeGoal;
  final List<BodyGoalState> _supersededGoals = <BodyGoalState>[];

  BodySetupData? get data => _data;
  List<BodyWeightEntry> get weightEntries => List.unmodifiable(_weightEntries);

  /// Test-introspection: goals superseded by [setActiveBodyGoal] transitions,
  /// oldest first. Not part of the [BodyRepository] contract.
  List<BodyGoalState> get supersededGoals =>
      List.unmodifiable(_supersededGoals);

  @override
  Future<void> saveBodySetup(BodySetupData data) async {
    _validateSetup(data);
    _data = data;
    final now = _now().toUtc();

    final currentWeight = data.currentWeightKg;
    if (currentWeight != null) {
      final onboardingIndex = _weightEntries.lastIndexWhere(
        (entry) => entry.source == BodyWeightSources.onboardingSetup,
      );
      final entry = BodyWeightEntry(
        id: onboardingIndex == -1
            ? _newWeightLogId()
            : _weightEntries[onboardingIndex].id,
        weightKg: currentWeight,
        measuredAt: now,
        source: BodyWeightSources.onboardingSetup,
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
        id: _newWeightLogId(),
        weightKg: record.weightKg,
        measuredAt: record.measuredAt.toUtc(),
        source: record.source.trim(),
      ),
    );
  }


  @override
  Future<BodyWeightHistoryPage> getWeightHistory(
    BodyWeightHistoryQuery query,
  ) async {
    query.validate();
    final cursor = query.before;
    final entries = _weightEntries.where((entry) {
      final id = entry.id!;
      final time = entry.measuredAt;
      if (time.isBefore(query.fromInclusive) ||
          !time.isBefore(query.toExclusive)) {
        return false;
      }
      if (cursor == null) return true;
      return time.isBefore(cursor.measuredAt) ||
          (time.isAtSameMomentAs(cursor.measuredAt) &&
              id.compareTo(cursor.id) < 0);
    }).toList()
      ..sort((left, right) {
        final order = right.measuredAt.compareTo(left.measuredAt);
        return order != 0 ? order : right.id!.compareTo(left.id!);
      });

    final hasMore = entries.length > query.limit;
    final page = List<BodyWeightEntry>.unmodifiable(
      entries.take(query.limit),
    );
    final last = page.isEmpty ? null : page.last;
    return BodyWeightHistoryPage(
      entries: page,
      nextCursor: hasMore && last != null
          ? BodyWeightHistoryCursor(measuredAt: last.measuredAt, id: last.id!)
          : null,
    );
  }

  @override
  Future<bool> updateWeightLog(BodyWeightLogEdit edit) async {
    edit.validate();
    final index = _weightEntries.indexWhere((entry) => entry.id == edit.id);
    if (index == -1) return false;
    final previous = _weightEntries[index];
    _weightEntries[index] = BodyWeightEntry(
      id: previous.id,
      weightKg: edit.weightKg,
      measuredAt: edit.measuredAt.toUtc(),
      source: previous.source,
    );
    return true;
  }

  @override
  Future<bool> deleteWeightLog(String id) async {
    BodyWeightLogIds.requireValid(id);
    final before = _weightEntries.length;
    _weightEntries.removeWhere((entry) => entry.id == id);
    return _weightEntries.length != before;
  }

  @override
  Future<void> setActiveBodyGoal(BodyGoalUpdate update) async {
    _validateGoalUpdate(update);
    final now = _now().toUtc();
    final previous = _activeGoal;

    if (previous != null && previous.goalType == update.goalType) {
      _activeGoal = BodyGoalState(
        goalType: update.goalType,
        startingWeightKg: previous.startingWeightKg,
        targetWeightKg: update.targetWeightKg,
        weeklyWeightChangeKg: update.weeklyWeightChangeKg,
        intentRank: previous.intentRank,
        startedAt: previous.startedAt,
      );
      return;
    }

    final isDirectional = update.goalType == BodyGoalType.loseWeight ||
        update.goalType == BodyGoalType.gainWeight;
    BodyWeightEntry? latestWeight;
    for (final entry in _weightEntries) {
      final current = latestWeight;
      if (current == null || entry.measuredAt.isAfter(current.measuredAt)) {
        latestWeight = entry;
      }
    }
    final startingWeight = latestWeight?.weightKg;

    if (isDirectional && startingWeight == null) {
      throw StateError(
        'A directional Body Goal requires a real canonical Current Weight.',
      );
    }

    if (previous != null) {
      _supersededGoals.add(previous);
    }

    _activeGoal = BodyGoalState(
      goalType: update.goalType,
      startingWeightKg: startingWeight,
      targetWeightKg: update.targetWeightKg,
      weeklyWeightChangeKg: update.weeklyWeightChangeKg,
      intentRank: previous?.intentRank,
      startedAt: now,
    );
  }

  void _validateGoalUpdate(BodyGoalUpdate update) {
    if (update.goalType == BodyGoalType.recomposition) {
      throw ArgumentError.value(
        update.goalType,
        'goalType',
        'Explicit Body Goal editing offers Lose/Gain/Maintain only.',
      );
    }
    final target = update.targetWeightKg;
    if (target != null && target <= 0) {
      throw ArgumentError.value(
        target,
        'targetWeightKg',
        'Target weight must be greater than zero.',
      );
    }
    final pace = update.weeklyWeightChangeKg;
    if (pace != null && pace < 0) {
      throw ArgumentError.value(
        pace,
        'weeklyWeightChangeKg',
        'Goal pace must be nonnegative.',
      );
    }
    final isDirectional = update.goalType == BodyGoalType.loseWeight ||
        update.goalType == BodyGoalType.gainWeight;
    if (!isDirectional && (target != null || pace != null)) {
      throw ArgumentError(
        'Maintain cannot persist Target Weight or Goal Pace.',
      );
    }
    if (isDirectional && (target == null || pace == null)) {
      throw ArgumentError(
        'Lose/Gain requires both Target Weight and Goal Pace.',
      );
    }
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
    final source = record.source.trim();
    if (source.isEmpty) {
      throw ArgumentError.value(
        record.source,
        'source',
        'Weight provenance source is required.',
      );
    }
    if (source == BodyWeightSources.onboardingSetup) {
      throw ArgumentError.value(
        record.source,
        'source',
        'onboarding_setup is reserved for saveBodySetup reconciliation.',
      );
    }
  }
}
