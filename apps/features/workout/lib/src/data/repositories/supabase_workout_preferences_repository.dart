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
/// Directly manages canonical RLS-protected user workout profiles (`public.user_workout_profiles`) in Postgres.
class SupabaseWorkoutPreferencesRepository
    implements WorkoutPreferencesRepository {
  const SupabaseWorkoutPreferencesRepository({
    required SupabaseClient client,
  }) : _client = client;

  final SupabaseClient _client;

  @override
  Future<void> saveWorkoutPreferences(WorkoutPreferencesData data) async {
    var userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      try {
        final res = await _client.auth.signInAnonymously();
        userId = res.user?.id ?? _client.auth.currentUser?.id;
      } catch (_) {}
    }
    if (userId == null || userId.isEmpty) {
      throw StateError(
          'Please sign in or create an account to save your workout preferences.');
    }

    final canonicalPayload = {
      'user_id': userId,
      'experience_level': data.experienceLevel.name,
      'special_event_goal':
          data.specialEvent?.trim().isEmpty == true ? null : data.specialEvent?.trim(),
      'workout_location': data.gymAccess.name,
      'available_equipment': data.equipment.map((e) => e.name).toList(),
      'workout_duration_mins': data.workoutDuration.minutes,
      'training_days': data.trainingDays.map((d) => d.name).toList(),
      'split_program': data.workoutSplit.name,
      'focus_areas': data.focusAreas.map((f) => f.name).toList(),
      'health_concerns':
          data.healthConcerns != null && data.healthConcerns!.trim().isNotEmpty
              ? [data.healthConcerns!.trim()]
              : <String>[],
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      await _client.from('user_workout_profiles').upsert(canonicalPayload);
    } on PostgrestException catch (e) {
      if (e.code == '42P01' || e.code == 'PGRST204' || e.code == '42703') {
        final legacyPayload = {
          'user_id': userId,
          'gym_access': data.gymAccess.name,
          'equipment': data.equipment.map((eq) => eq.name).toList(),
          'experience_level': data.experienceLevel.name,
          'focus_areas': data.focusAreas.map((f) => f.name).toList(),
          'training_days': data.trainingDays.map((d) => d.name).toList(),
          'workout_duration': data.workoutDuration.name,
          'workout_split': data.workoutSplit.name,
          'health_concerns': data.healthConcerns,
          'special_event': data.specialEvent,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };
        await _client.from('user_workout_preferences').upsert(legacyPayload);
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<WorkoutPreferencesData?> getWorkoutPreferences() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return null;
    }

    final row = await _client
        .from('user_workout_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (row == null) return null;

    final locationStr = row['workout_location'] as String?;
    if (locationStr == null) {
      throw const FormatException('Missing required field: workout_location');
    }
    final gymAccess = WorkoutGymAccess.values
        .where((g) => g.name == locationStr)
        .firstOrNull;
    if (gymAccess == null) {
      throw FormatException('Invalid workout_location: $locationStr');
    }

    final rawEquipment = row['available_equipment'];
    final Set<WorkoutEquipment> equipment;
    if (rawEquipment is List) {
      equipment = rawEquipment
          .map((e) {
            final eq = WorkoutEquipment.values
                .where((we) => we.name == e.toString())
                .firstOrNull;
            if (eq == null) {
              throw FormatException('Invalid equipment item: $e');
            }
            return eq;
          })
          .toSet();
    } else if (rawEquipment == null) {
      equipment = const {};
    } else {
      throw FormatException(
          'Invalid available_equipment format: $rawEquipment');
    }

    final experienceStr = row['experience_level'] as String?;
    if (experienceStr == null) {
      throw const FormatException('Missing required field: experience_level');
    }
    final experienceLevel = WorkoutExperienceLevel.values
        .where((e) => e.name == experienceStr)
        .firstOrNull;
    if (experienceLevel == null) {
      throw FormatException('Invalid experience_level: $experienceStr');
    }

    final rawFocus = row['focus_areas'];
    if (rawFocus is! List || rawFocus.isEmpty) {
      throw const FormatException(
          'Missing or empty required field: focus_areas');
    }
    final focusAreas = rawFocus
        .map((f) {
          final fa = WorkoutFocusArea.values
              .where((wfa) => wfa.name == f.toString())
              .firstOrNull;
          if (fa == null) {
            throw FormatException('Invalid focus_area item: $f');
          }
          return fa;
        })
        .toSet();

    final rawDays = row['training_days'];
    if (rawDays is! List || rawDays.isEmpty) {
      throw const FormatException(
          'Missing or empty required field: training_days');
    }
    final trainingDays = rawDays
        .map((d) {
          final td = WorkoutTrainingDay.values
              .where((wtd) => wtd.name == d.toString())
              .firstOrNull;
          if (td == null) {
            throw FormatException('Invalid training_day item: $d');
          }
          return td;
        })
        .toSet();

    final rawDurationMins = row['workout_duration_mins'];
    final int? durationMins;
    if (rawDurationMins == null) {
      durationMins = null;
    } else if (rawDurationMins is int) {
      durationMins = rawDurationMins;
    } else if (rawDurationMins is num) {
      durationMins = rawDurationMins.toInt();
    } else {
      throw FormatException(
          'Invalid workout_duration_mins: $rawDurationMins');
    }
    final duration = WorkoutDuration.fromMinutes(durationMins);

    final splitStr = row['split_program'] as String?;
    if (splitStr == null) {
      throw const FormatException('Missing required field: split_program');
    }
    final split =
        WorkoutSplit.values.where((s) => s.name == splitStr).firstOrNull;
    if (split == null) {
      throw FormatException('Invalid split_program: $splitStr');
    }

    final specialEvent = (row['special_event_goal'] as String?)?.trim();
    final specialEventGoal =
        (specialEvent != null && specialEvent.isNotEmpty) ? specialEvent : null;

    final rawHealth = row['health_concerns'];
    final String? healthConcerns;
    if (rawHealth is List) {
      final items = rawHealth
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
      healthConcerns = items.isEmpty ? null : items.join(', ');
    } else if (rawHealth is String && rawHealth.trim().isNotEmpty) {
      healthConcerns = rawHealth.trim();
    } else {
      healthConcerns = null;
    }

    return WorkoutPreferencesData(
      gymAccess: gymAccess,
      equipment: equipment,
      experienceLevel: experienceLevel,
      focusAreas: focusAreas,
      trainingDays: trainingDays,
      workoutDuration: duration,
      workoutSplit: split,
      healthConcerns: healthConcerns,
      specialEvent: specialEventGoal,
    );
  }
}
