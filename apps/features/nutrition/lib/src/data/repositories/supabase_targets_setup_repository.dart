import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/nutrition_target_recommendation.dart';
import '../../domain/models/targets_setup_data.dart';
import '../../domain/repositories/targets_setup_repository.dart';

/// Supabase-backed implementation of [TargetsSetupRepository].
///
/// O4C keeps this repository responsible only for the current Nutrition
/// compatibility payload. Wellness-owned Steps/Water/Sleep/Bed/Wake values may
/// still be present in [TargetsSetupData] as calculation inputs, but new writes
/// do not mirror them into Nutrition storage. Legacy Wellness columns remain
/// readable until later owner-specific cleanup/consumer cutovers.
class SupabaseTargetsSetupRepository implements TargetsSetupRepository {
  const SupabaseTargetsSetupRepository({
    required SupabaseClient client,
  }) : _client = client;

  final SupabaseClient _client;

  @override
  Future<void> saveTargetsSetup(TargetsSetupData data) async {
    var userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      try {
        final res = await _client.auth.signInAnonymously();
        userId = res.user?.id ?? _client.auth.currentUser?.id;
      } catch (_) {}
    }
    if (userId == null || userId.isEmpty) {
      throw StateError(
          'Please sign in or create an account to save your targets.');
    }

    final canonicalNutritionPayload = {
      'user_id': userId,
      if (data.heightCm != null) 'height_cm': data.heightCm,
      if (data.activityLevel != null && data.activityLevel!.isNotEmpty)
        'activity_level': data.activityLevel,
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
        if (data.recommendation?.bmr != null)
          'bmr': data.recommendation!.bmr,
        if (data.recommendation?.tdee != null)
          'tdee': data.recommendation!.tdee,
      },
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      await _client
          .from('user_nutrition_profiles')
          .upsert(canonicalNutritionPayload);
    } on PostgrestException catch (e) {
      if (e.code == '42P01' || e.code == 'PGRST204' || e.code == '42703') {
        // Compatibility fallback remains Nutrition-only. Wellness values are
        // canonically persisted before this repository is called and must never
        // be recreated here as a fallback durable owner.
        final legacyNutritionPayload = {
          'user_id': userId,
          'target_calories': data.recommendation?.caloriesKcal,
          'target_protein_grams': data.recommendation?.proteinGrams,
          'target_carbs_grams': data.recommendation?.carbsGrams,
          'target_fat_grams': data.recommendation?.fatGrams,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };
        await _client.from('user_targets').upsert(legacyNutritionPayload);
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<TargetsSetupData?> getTargetsSetup() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return null;
    }

    final canonicalRow = await _client
        .from('user_nutrition_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (canonicalRow == null) return null;

    // O4C cuts new Wellness mirror writes but intentionally preserves these
    // legacy reads until downstream hydration/owner consumers move to the
    // canonical Wellness repository in the integrated acceptance slice.
    final rawSteps = canonicalRow['steps_target'];
    if (rawSteps is! num) {
      throw const FormatException(
          'Missing or invalid required field: steps_target');
    }
    final steps = rawSteps.toInt();

    final rawSleepTarget = canonicalRow['sleep_target_minutes'];
    if (rawSleepTarget is! num) {
      throw const FormatException(
          'Missing or invalid required field: sleep_target_minutes');
    }
    final sleepTargetMinutes = rawSleepTarget.toInt();

    final rawBed = canonicalRow['bed_time'];
    if (rawBed is! String || rawBed.trim().isEmpty) {
      throw const FormatException(
          'Missing or invalid required field: bed_time');
    }
    final sleepTimeMinutes = parseTimeToMinutes(rawBed);

    final rawWake = canonicalRow['wake_up_time'];
    if (rawWake is! String || rawWake.trim().isEmpty) {
      throw const FormatException(
          'Missing or invalid required field: wake_up_time');
    }
    final wakeTimeMinutes = parseTimeToMinutes(rawWake);

    final rawWater = canonicalRow['water_target_ml'];
    if (rawWater is! num) {
      throw const FormatException(
          'Missing or invalid required field: water_target_ml');
    }
    final waterMl = rawWater.toInt();

    // Legacy rows may still contain the old Body-owned pace mirror. New writes
    // intentionally omit it, so 0.0 is only the Targets compatibility sentinel
    // for "no mirrored pace", never a canonical Body Goal value.
    final rawPace = canonicalRow['weekly_weight_change_kg'];
    final weeklyPace = rawPace is num ? rawPace.toDouble() : 0.0;

    // These legacy mirrors remain readable during the additive migration. New
    // O3+ writes no longer populate the Body-owned current/target weight fields.
    final rawHeight = canonicalRow['height_cm'];
    final rawCurrentWeight = canonicalRow['current_weight_kg'];
    final rawTargetWeight = canonicalRow['target_weight_kg'];
    final rawActivityLevel = canonicalRow['activity_level'];

    final rawMacros = canonicalRow['macro_targets'];
    final NutritionTargetRecommendation? recommendation;
    if (rawMacros is Map<String, dynamic> && rawMacros.isNotEmpty) {
      final calories = rawMacros['calories'];
      final protein = rawMacros['protein'];
      final carbs = rawMacros['carbs'];
      final fat = rawMacros['fat'];
      final fiber = rawMacros['fiber'];
      final bmr = rawMacros['bmr'];
      final tdee = rawMacros['tdee'];

      if (calories is num &&
          protein is num &&
          carbs is num &&
          fat is num &&
          fiber is num &&
          bmr is num &&
          tdee is num) {
        recommendation = NutritionTargetRecommendation(
          caloriesKcal: calories.toInt(),
          proteinGrams: protein.toInt(),
          carbsGrams: carbs.toInt(),
          fatGrams: fat.toInt(),
          fiberGrams: fiber.toInt(),
          bmr: bmr.toInt(),
          tdee: tdee.toInt(),
        );
      } else {
        throw const FormatException(
            'Malformed macro_targets payload in database');
      }
    } else {
      recommendation = null;
    }

    return TargetsSetupData(
      dailySteps: steps,
      sleepTargetMinutes: sleepTargetMinutes,
      sleepTimeMinutes: sleepTimeMinutes,
      wakeTimeMinutes: wakeTimeMinutes,
      waterMl: waterMl,
      goalPaceKgPerWeek: weeklyPace,
      heightCm: rawHeight is num ? rawHeight.toDouble() : null,
      currentWeightKg:
          rawCurrentWeight is num ? rawCurrentWeight.toDouble() : null,
      targetWeightKg: rawTargetWeight is num ? rawTargetWeight.toDouble() : null,
      activityLevel: rawActivityLevel is String && rawActivityLevel.isNotEmpty
          ? rawActivityLevel
          : null,
      recommendation: recommendation,
    );
  }

  /// Converts minutes from midnight into standard SQL TIME format `HH:mm:ss`.
  /// Retained for compatibility tests/read helpers during the additive cutover.
  static String formatMinutesToTime(int minutesFromMidnight) {
    final normalized = minutesFromMidnight % 1440;
    final nonNegative = normalized < 0 ? normalized + 1440 : normalized;
    final hrs = nonNegative ~/ 60;
    final mins = nonNegative % 60;
    return '${hrs.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:00';
  }

  /// Parses a standard SQL TIME string (e.g. `23:00:00`, `07:30`) into minutes from midnight.
  static int parseTimeToMinutes(String timeStr) {
    final trimmed = timeStr.trim();
    final parts = trimmed.split(':');
    if (parts.length < 2) {
      throw FormatException('Invalid SQL TIME format: $timeStr');
    }
    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    if (hours == null ||
        minutes == null ||
        hours < 0 ||
        hours > 23 ||
        minutes < 0 ||
        minutes > 59) {
      throw FormatException('Invalid SQL TIME component values: $timeStr');
    }
    return (hours * 60) + minutes;
  }
}
