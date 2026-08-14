import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/workout_duration.dart';
import '../../domain/models/workout_equipment.dart';
import '../../domain/models/workout_experience_level.dart';
import '../../domain/models/workout_focus_area.dart';
import '../../domain/models/workout_gym_access.dart';
import '../../domain/models/workout_preferences_data.dart';
import '../../domain/models/workout_split.dart';
import '../../domain/models/workout_training_day.dart';
import '../../domain/repositories/workout_preferences_repository.dart';

/// Supabase-backed implementation of [WorkoutPreferencesRepository].
///
/// Directly manages RLS-protected user workout preference records in Postgres.
class SupabaseWorkoutPreferencesRepository
    implements WorkoutPreferencesRepository {
  const SupabaseWorkoutPreferencesRepository({
    required SupabaseClient client,
  }) : _client = client;

  final SupabaseClient _client;

  @override
  Future<void> saveWorkoutPreferences(WorkoutPreferencesData data) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError(
          'Cannot persist workout preferences: user is not authenticated.');
    }

    final payload = {
      'user_id': userId,
      'gym_access': data.gymAccess.name,
      'equipment': data.equipment.map((e) => e.name).toList(),
      'experience_level': data.experienceLevel.name,
      'focus_areas': data.focusAreas.map((f) => f.name).toList(),
      'training_days': data.trainingDays.map((d) => d.name).toList(),
      'workout_duration': data.workoutDuration.name,
      'workout_split': data.workoutSplit.name,
      'health_concerns': data.healthConcerns,
      'special_event': data.specialEvent,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    await _client.from('user_workout_preferences').upsert(payload);
  }

  @override
  Future<WorkoutPreferencesData?> getWorkoutPreferences() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return null;
    }

    final row = await _client
        .from('user_workout_preferences')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (row == null) return null;

    final gymAccessStr = row['gym_access'] as String?;
    final gymAccess = WorkoutGymAccess.values.firstWhere(
      (g) => g.name == gymAccessStr,
      orElse: () => WorkoutGymAccess.gym,
    );

    final equipmentList = (row['equipment'] as List<dynamic>?) ?? [];
    final equipment = equipmentList
        .map((e) =>
            WorkoutEquipment.values.where((we) => we.name == e).firstOrNull)
        .whereType<WorkoutEquipment>()
        .toSet();

    final experienceStr = row['experience_level'] as String?;
    final experienceLevel = WorkoutExperienceLevel.values.firstWhere(
      (e) => e.name == experienceStr,
      orElse: () => WorkoutExperienceLevel.beginner,
    );

    final focusList = (row['focus_areas'] as List<dynamic>?) ?? [];
    final focusAreas = focusList
        .map((f) =>
            WorkoutFocusArea.values.where((fa) => fa.name == f).firstOrNull)
        .whereType<WorkoutFocusArea>()
        .toSet();

    final daysList = (row['training_days'] as List<dynamic>?) ?? [];
    final trainingDays = daysList
        .map((d) =>
            WorkoutTrainingDay.values.where((td) => td.name == d).firstOrNull)
        .whereType<WorkoutTrainingDay>()
        .toSet();

    final durationStr = row['workout_duration'] as String?;
    final duration = WorkoutDuration.values.firstWhere(
      (d) => d.name == durationStr,
      orElse: () => WorkoutDuration.auto,
    );

    final splitStr = row['workout_split'] as String?;
    final split = WorkoutSplit.values.firstWhere(
      (s) => s.name == splitStr,
      orElse: () => WorkoutSplit.auto,
    );

    return WorkoutPreferencesData(
      gymAccess: gymAccess,
      equipment: equipment,
      experienceLevel: experienceLevel,
      focusAreas:
          focusAreas.isEmpty ? {WorkoutFocusArea.fullBody} : focusAreas,
      trainingDays: trainingDays.isEmpty
          ? {WorkoutTrainingDay.monday, WorkoutTrainingDay.wednesday, WorkoutTrainingDay.friday}
          : trainingDays,
      workoutDuration: duration,
      workoutSplit: split,
      healthConcerns: row['health_concerns'] as String?,
      specialEvent: row['special_event'] as String?,
    );
  }
}
