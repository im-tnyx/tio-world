import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/nutrition_target_recommendation.dart';
import '../../domain/models/targets_setup_data.dart';
import '../../domain/repositories/targets_setup_repository.dart';

/// Supabase-backed implementation of [TargetsSetupRepository].
///
/// Directly manages RLS-protected user daily targets and nutritional setup records in Postgres.
class SupabaseTargetsSetupRepository implements TargetsSetupRepository {
  const SupabaseTargetsSetupRepository({
    required SupabaseClient client,
  }) : _client = client;

  final SupabaseClient _client;

  @override
  Future<void> saveTargetsSetup(TargetsSetupData data) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError(
          'Cannot persist targets setup: user is not authenticated.');
    }

    final payload = {
      'user_id': userId,
      'daily_steps': data.dailySteps,
      'sleep_target_minutes': data.sleepTargetMinutes,
      'sleep_time_minutes': data.sleepTimeMinutes,
      'wake_time_minutes': data.wakeTimeMinutes,
      'water_ml': data.waterMl,
      'goal_pace_kg_per_week': data.goalPaceKgPerWeek,
      'target_calories': data.recommendation?.caloriesKcal,
      'target_protein_grams': data.recommendation?.proteinGrams,
      'target_carbs_grams': data.recommendation?.carbsGrams,
      'target_fat_grams': data.recommendation?.fatGrams,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    await _client.from('user_targets').upsert(payload);
  }

  @override
  Future<TargetsSetupData?> getTargetsSetup() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return null;
    }

    final row = await _client
        .from('user_targets')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (row == null) return null;

    final dailySteps = (row['daily_steps'] as num?)?.toInt() ?? 8000;
    final sleepTargetMinutes =
        (row['sleep_target_minutes'] as num?)?.toInt() ?? 480;
    final sleepTimeMinutes =
        (row['sleep_time_minutes'] as num?)?.toInt() ?? 1380;
    final wakeTimeMinutes =
        (row['wake_time_minutes'] as num?)?.toInt() ?? 420;
    final waterMl = (row['water_ml'] as num?)?.toInt() ?? 2500;
    final goalPace =
        (row['goal_pace_kg_per_week'] as num?)?.toDouble() ?? 0.5;

    final calories = (row['target_calories'] as num?)?.toInt();
    final protein = (row['target_protein_grams'] as num?)?.toInt();
    final carbs = (row['target_carbs_grams'] as num?)?.toInt();
    final fat = (row['target_fat_grams'] as num?)?.toInt();

    NutritionTargetRecommendation? recommendation;
    if (calories != null && protein != null && carbs != null && fat != null) {
      recommendation = NutritionTargetRecommendation(
        caloriesKcal: calories,
        proteinGrams: protein,
        carbsGrams: carbs,
        fatGrams: fat,
        fiberGrams: 30,
        bmr: 1600,
        tdee: 2200,
      );
    }

    return TargetsSetupData(
      dailySteps: dailySteps,
      sleepTargetMinutes: sleepTargetMinutes,
      sleepTimeMinutes: sleepTimeMinutes,
      wakeTimeMinutes: wakeTimeMinutes,
      waterMl: waterMl,
      goalPaceKgPerWeek: goalPace,
      recommendation: recommendation,
    );
  }
}
