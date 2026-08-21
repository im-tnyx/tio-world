import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/body_setup.dart';

/// Supabase implementation of the canonical Body owner.
///
/// `body_weight_logs` owns current-weight history and `user_body_goals` owns
/// active/historical Body Goal plans. Legacy Profile/Nutrition mirrors are not
/// touched here.
class SupabaseBodySetupRepository implements BodySetupRepository {
  const SupabaseBodySetupRepository({required SupabaseClient client})
      : _client = client;

  static const _onboardingWeightSource = 'onboarding_setup';

  final SupabaseClient _client;

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError('Please sign in to save Body setup data.');
    }
    return userId;
  }

  @override
  Future<void> saveBodySetup(BodySetupData data) async {
    final userId = _requireUserId();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    final currentWeight = data.currentWeightKg;
    if (currentWeight != null) {
      if (currentWeight <= 0) {
        throw ArgumentError.value(
          currentWeight,
          'currentWeightKg',
          'Current weight must be greater than zero.',
        );
      }
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

  Future<void> _saveOnboardingWeightSnapshot({
    required String userId,
    required double weightKg,
    required String nowIso,
  }) async {
    final existing = await _client
        .from('body_weight_logs')
        .select('id')
        .eq('user_id', userId)
        .eq('source', _onboardingWeightSource)
        .order('measured_at', ascending: false)
        .limit(1)
        .maybeSingle();

    final payload = <String, dynamic>{
      'user_id': userId,
      'weight_kg': weightKg,
      'measured_at': nowIso,
      'source': _onboardingWeightSource,
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
    if (requested != null) {
      _validateGoal(requested);
    }

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
}
