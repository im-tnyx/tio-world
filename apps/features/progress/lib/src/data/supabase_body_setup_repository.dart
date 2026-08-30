import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/body_setup.dart';
import 'body_state_row_mapper.dart';

/// Supabase implementation of the canonical Body owner.
///
/// `body_weight_logs` owns current-weight history and `user_body_goals` owns
/// active/historical Body Goal plans. Legacy Profile/Nutrition mirrors are not
/// touched here.
class SupabaseBodySetupRepository implements BodyRepository {
  const SupabaseBodySetupRepository({
    required SupabaseClient client,
    BodyStateRowMapper stateMapper = const BodyStateRowMapper(),
  })  : _client = client,
        _stateMapper = stateMapper;

  final SupabaseClient _client;
  final BodyStateRowMapper _stateMapper;

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError('Please sign in to access Body data.');
    }
    return userId;
  }

  @override
  Future<void> saveBodySetup(BodySetupData data) async {
    final userId = _requireUserId();
    _validate(data);
    final nowIso = DateTime.now().toUtc().toIso8601String();

    final currentWeight = data.currentWeightKg;
    if (currentWeight != null) {
      await _saveOnboardingWeightSnapshot(
        userId: userId,
        weightKg: currentWeight,
        nowIso: nowIso,
      );
    }

    await _reconcileActiveGoal(
      userId: userId,
      data: data,
      nowIso: nowIso,
    );
  }

  @override
  Future<BodyState> getBodyState() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return const BodyState();
    }

    final latestWeightRow = await _client
        .from('body_weight_logs')
        .select('weight_kg, measured_at, source')
        .eq('user_id', userId)
        .order('measured_at', ascending: false)
        .limit(1)
        .maybeSingle();

    final activeGoalRow = await _client
        .from('user_body_goals')
        .select(
          'goal_type, starting_weight_kg, target_weight_kg, '
          'weekly_weight_change_kg, intent_rank, started_at',
        )
        .eq('user_id', userId)
        .eq('status', 'active')
        .maybeSingle();

    return _stateMapper.map(
      latestWeightRow: latestWeightRow,
      activeGoalRow: activeGoalRow,
    );
  }

  @override
  Future<void> recordCurrentWeight(BodyWeightRecord record) async {
    final userId = _requireUserId();
    _validateWeightRecord(record);

    await _client.from('body_weight_logs').insert({
      'user_id': userId,
      'weight_kg': record.weightKg,
      'measured_at': record.measuredAt.toUtc().toIso8601String(),
      'source': record.source.trim(),
    });
  }

  @override
  Future<void> setActiveBodyGoal(BodyGoalUpdate update) async {
    final userId = _requireUserId();
    _validateGoalUpdate(update);
    final nowIso = DateTime.now().toUtc().toIso8601String();

    final activeRow = await _client
        .from('user_body_goals')
        .select('id, goal_type, intent_rank')
        .eq('user_id', userId)
        .eq('status', 'active')
        .maybeSingle();

    final goalStorage = update.goalType.storageValue;
    final activeId = activeRow?['id'] as String?;
    final activeType = activeRow?['goal_type'] as String?;

    if (activeId != null && activeId.isNotEmpty && activeType == goalStorage) {
      // Same active goal type: update target/pace in place. Row identity,
      // starting_weight_kg, started_at, and intent_rank are left untouched.
      await _client.from('user_body_goals').update({
        'target_weight_kg': update.targetWeightKg,
        'weekly_weight_change_kg': update.weeklyWeightChangeKg,
        'updated_at': nowIso,
      }).eq('id', activeId);
      return;
    }

    // Changed goal type (or no prior active goal): snapshot the latest
    // canonical weight as the new goal's starting weight.
    final isDirectional = update.goalType == BodyGoalType.loseWeight ||
        update.goalType == BodyGoalType.gainWeight;
    final latestWeightRow = await _client
        .from('body_weight_logs')
        .select('weight_kg')
        .eq('user_id', userId)
        .order('measured_at', ascending: false)
        .limit(1)
        .maybeSingle();
    final startingWeight = (latestWeightRow?['weight_kg'] as num?)?.toDouble();

    if (isDirectional && startingWeight == null) {
      throw StateError(
        'A directional Body Goal requires a real canonical Current Weight.',
      );
    }

    if (activeId != null && activeId.isNotEmpty) {
      await _client.from('user_body_goals').update({
        'status': 'superseded',
        'ended_at': nowIso,
      }).eq('id', activeId);
    }

    await _client.from('user_body_goals').insert({
      'user_id': userId,
      'goal_type': goalStorage,
      'starting_weight_kg': startingWeight,
      'target_weight_kg': update.targetWeightKg,
      'weekly_weight_change_kg': update.weeklyWeightChangeKg,
      'intent_rank': activeRow?['intent_rank'],
      'status': 'active',
      'started_at': nowIso,
    });
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

  void _validate(BodySetupData data) {
    final currentWeight = data.currentWeightKg;
    if (currentWeight != null && currentWeight <= 0) {
      throw ArgumentError.value(
        currentWeight,
        'currentWeightKg',
        'Current weight must be greater than zero.',
      );
    }
    final goal = data.activeGoal;
    if (goal != null) {
      _validateGoal(goal);
    }
  }

  Future<void> _saveOnboardingWeightSnapshot({
    required String userId,
    required double weightKg,
    required String nowIso,
  }) async {
    final existing = await _client
        .from('body_weight_logs')
        .select('id')
        .eq('user_id', userId)
        .eq('source', BodyWeightSources.onboardingSetup)
        .order('measured_at', ascending: false)
        .limit(1)
        .maybeSingle();

    final payload = <String, dynamic>{
      'user_id': userId,
      'weight_kg': weightKg,
      'measured_at': nowIso,
      'source': BodyWeightSources.onboardingSetup,
      'metadata': const <String, dynamic>{'context': 'product_onboarding'},
    };

    final existingId = existing?['id'] as String?;
    if (existingId == null || existingId.isEmpty) {
      await _client.from('body_weight_logs').insert(payload);
      return;
    }

    await _client
        .from('body_weight_logs')
        .update(payload)
        .eq('id', existingId);
  }

  Future<void> _reconcileActiveGoal({
    required String userId,
    required BodySetupData data,
    required String nowIso,
  }) async {
    final requested = data.activeGoal;
    final activeRow = await _client
        .from('user_body_goals')
        .select('id, goal_type, starting_weight_kg')
        .eq('user_id', userId)
        .eq('status', 'active')
        .maybeSingle();

    if (requested == null) {
      final activeId = activeRow?['id'] as String?;
      if (activeId != null && activeId.isNotEmpty) {
        await _client.from('user_body_goals').update({
          'status': 'superseded',
          'ended_at': nowIso,
        }).eq('id', activeId);
      }
      return;
    }

    final goalStorage = requested.goalType.storageValue;
    final activeId = activeRow?['id'] as String?;
    final activeType = activeRow?['goal_type'] as String?;

    if (activeId != null && activeId.isNotEmpty && activeType == goalStorage) {
      await _client.from('user_body_goals').update({
        if (activeRow?['starting_weight_kg'] == null && data.currentWeightKg != null)
          'starting_weight_kg': data.currentWeightKg,
        'target_weight_kg': requested.targetWeightKg,
        'weekly_weight_change_kg': requested.weeklyWeightChangeKg,
        'intent_rank': requested.intentRank,
        'updated_at': nowIso,
      }).eq('id', activeId);
      return;
    }

    if (activeId != null && activeId.isNotEmpty) {
      await _client.from('user_body_goals').update({
        'status': 'superseded',
        'ended_at': nowIso,
      }).eq('id', activeId);
    }

    await _client.from('user_body_goals').insert({
      'user_id': userId,
      'goal_type': goalStorage,
      'starting_weight_kg': data.currentWeightKg,
      'target_weight_kg': requested.targetWeightKg,
      'weekly_weight_change_kg': requested.weeklyWeightChangeKg,
      'intent_rank': requested.intentRank,
      'status': 'active',
      'started_at': nowIso,
    });
  }

  void _validateGoal(BodyGoalSetupData goal) {
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
