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

    final hrsBed = (data.sleepTimeMinutes ~/ 60) % 24;
    final minsBed = data.sleepTimeMinutes % 60;
    final bedTimeStr =
        '${hrsBed.toString().padLeft(2, '0')}:${minsBed.toString().padLeft(2, '0')}:00';

    final hrsWake = (data.wakeTimeMinutes ~/ 60) % 24;
    final minsWake = data.wakeTimeMinutes % 60;
    final wakeTimeStr =
        '${hrsWake.toString().padLeft(2, '0')}:${minsWake.toString().padLeft(2, '0')}:00';

    final canonicalNutritionPayload = {
      'user_id': userId,
      'steps_target': data.dailySteps,
      'water_target_ml': data.waterMl,
      'weekly_weight_change_kg': data.goalPaceKgPerWeek,
      'bed_time': bedTimeStr,
      'wake_up_time': wakeTimeStr,
      'macro_targets': {
        if (data.recommendation?.caloriesKcal != null)
          'calories': data.recommendation!.caloriesKcal,
        if (data.recommendation?.proteinGrams != null)
          'protein': data.recommendation!.proteinGrams,
        if (data.recommendation?.carbsGrams != null)
          'carbs': data.recommendation!.carbsGrams,
        if (data.recommendation?.fatGrams != null)
          'fat': data.recommendation!.fatGrams,
        if (data.recommendation?.fiberGrams != null)
          'fiber': data.recommendation!.fiberGrams,
        if (data.recommendation?.bmr != null) 'bmr': data.recommendation!.bmr,
        if (data.recommendation?.tdee != null)
          'tdee': data.recommendation!.tdee,
      },
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      await _client
          .from('user_nutrition_profiles')
          .upsert(canonicalNutritionPayload);
      return;
    } catch (_) {
      // Compatibility fallback if canonical table is pending migration in legacy environments
      try {
        await _client.from('user_targets').upsert(payload);
      } catch (_) {}
    }
  }

  @override
  Future<TargetsSetupData?> getTargetsSetup() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return null;
    }

    Map<String, dynamic>? canonicalRow;
    try {
      canonicalRow = await _client
          .from('user_nutrition_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
    } catch (_) {}

    if (canonicalRow != null) {
      final steps = (canonicalRow['steps_target'] as num?)?.toInt() ?? 8000;
      final water = (canonicalRow['water_target_ml'] as num?)?.toInt() ?? 2500;
      final weeklyPace =
          (canonicalRow['weekly_weight_change_kg'] as num?)?.toDouble() ?? 0.5;

      final bedStr = canonicalRow['bed_time'] as String? ?? '23:00:00';
      final bedParts = bedStr.split(':');
      final bedHours = int.tryParse(bedParts.first) ?? 23;
      final bedMins = bedParts.length > 1 ? (int.tryParse(bedParts[1]) ?? 0) : 0;
      final sleepTimeMinutes = (bedHours * 60) + bedMins;

      final wakeStr = canonicalRow['wake_up_time'] as String? ?? '07:00:00';
      final wakeParts = wakeStr.split(':');
      final wakeHours = int.tryParse(wakeParts.first) ?? 7;
      final wakeMins = wakeParts.length > 1 ? (int.tryParse(wakeParts[1]) ?? 0) : 0;
      final wakeTimeMinutes = (wakeHours * 60) + wakeMins;

      final diff = (wakeTimeMinutes - sleepTimeMinutes) % 1440;
      final sleepTargetMinutes = diff > 0 ? diff : 480;

      final macros = (canonicalRow['macro_targets'] as Map<String, dynamic>?) ?? {};
      NutritionTargetRecommendation? recommendation;
      if (macros.isNotEmpty && macros.containsKey('calories')) {
        recommendation = NutritionTargetRecommendation(
          caloriesKcal: (macros['calories'] as num?)?.toInt() ?? 2000,
          proteinGrams: (macros['protein'] as num?)?.toInt() ?? 120,
          carbsGrams: (macros['carbs'] as num?)?.toInt() ?? 200,
          fatGrams: (macros['fat'] as num?)?.toInt() ?? 60,
          fiberGrams: (macros['fiber'] as num?)?.toInt() ?? 30,
          bmr: (macros['bmr'] as num?)?.toInt() ?? 1600,
          tdee: (macros['tdee'] as num?)?.toInt() ?? 2200,
        );
      }

      return TargetsSetupData(
        dailySteps: steps,
        sleepTargetMinutes: sleepTargetMinutes,
        sleepTimeMinutes: sleepTimeMinutes,
        wakeTimeMinutes: wakeTimeMinutes,
        waterMl: water,
        goalPaceKgPerWeek: weeklyPace,
        recommendation: recommendation,
      );
    }

    Map<String, dynamic>? row;
    try {
      row = await _client
          .from('user_targets')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
    } catch (_) {}

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
