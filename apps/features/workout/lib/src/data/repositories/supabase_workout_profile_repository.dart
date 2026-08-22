import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/workout_equipment.dart';
import '../../domain/models/workout_experience_level.dart';
import '../../domain/models/workout_focus_area.dart';
import '../../domain/models/workout_gym_access.dart';
import '../../domain/models/workout_profile_data.dart';
import '../../domain/repositories/workout_profile_repository.dart';

typedef CurrentWorkoutProfileUserId = String? Function();

abstract interface class WorkoutProfileTableGateway {
  Future<Map<String, dynamic>?> readRow(String userId);

  Future<void> upsertRow(Map<String, dynamic> payload);
}

final class SupabaseWorkoutProfileTableGateway
    implements WorkoutProfileTableGateway {
  const SupabaseWorkoutProfileTableGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> readRow(String userId) async {
    return _client
        .from('user_workout_profiles')
        .select(
          'workout_location, available_equipment, experience_level, '
          'focus_areas, health_concerns',
        )
        .eq('user_id', userId)
        .maybeSingle();
  }

  @override
  Future<void> upsertRow(Map<String, dynamic> payload) async {
    await _client
        .from('user_workout_profiles')
        .upsert(payload, onConflict: 'user_id');
  }
}

/// Supabase adapter for canonical Workout Profile context/capability only.
///
/// It never writes schedule/goal/plan fields and never mutates auth state.
final class SupabaseWorkoutProfileRepository
    implements WorkoutProfileRepository {
  SupabaseWorkoutProfileRepository({
    required SupabaseClient client,
    WorkoutProfileTableGateway? gateway,
    CurrentWorkoutProfileUserId? currentUserId,
  })  : _gateway = gateway ?? SupabaseWorkoutProfileTableGateway(client),
        _currentUserId = currentUserId ?? (() => client.auth.currentUser?.id);

  final WorkoutProfileTableGateway _gateway;
  final CurrentWorkoutProfileUserId _currentUserId;

  @override
  Future<WorkoutProfileData?> read() async {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) return null;

    final row = await _gateway.readRow(userId);
    if (row == null) return null;

    return WorkoutProfileData(
      workoutLocation: _parseOptionalEnum(
        row['workout_location'],
        'workout_location',
        WorkoutGymAccess.values,
      ),
      availableEquipment: _parseOptionalEnumSet(
        row['available_equipment'],
        'available_equipment',
        WorkoutEquipment.values,
      ),
      experienceLevel: _parseOptionalEnum(
        row['experience_level'],
        'experience_level',
        WorkoutExperienceLevel.values,
      ),
      focusAreas: _parseOptionalEnumSet(
        row['focus_areas'],
        'focus_areas',
        WorkoutFocusArea.values,
      ),
      healthConcerns:
          _parseOptionalStringSet(row['health_concerns'], 'health_concerns'),
    );
  }

  @override
  Future<void> upsert(WorkoutProfileData profile) async {
    final userId = _requireUserId();

    await _gateway.upsertRow({
      'user_id': userId,
      'workout_location': profile.workoutLocation?.name,
      'available_equipment': _sortedEnumNames(profile.availableEquipment),
      'experience_level': profile.experienceLevel?.name,
      'focus_areas': _sortedEnumNames(profile.focusAreas),
      'health_concerns': _sortedStrings(profile.healthConcerns),
    });
  }

  String _requireUserId() {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) {
      throw StateError('Please sign in to save your Workout Profile.');
    }
    return userId;
  }
}

T? _parseOptionalEnum<T extends Enum>(
  Object? raw,
  String key,
  List<T> values,
) {
  if (raw == null) return null;
  if (raw is! String) {
    throw FormatException('Invalid canonical Workout Profile $key: expected string or null.');
  }
  for (final value in values) {
    if (value.name == raw) return value;
  }
  throw FormatException('Invalid canonical Workout Profile $key: $raw');
}

Set<T>? _parseOptionalEnumSet<T extends Enum>(
  Object? raw,
  String key,
  List<T> values,
) {
  if (raw == null) return null;
  if (raw is! List) {
    throw FormatException('Invalid canonical Workout Profile $key: expected string array or null.');
  }
  final result = <T>{};
  for (final item in raw) {
    if (item is! String) {
      throw FormatException('Invalid canonical Workout Profile $key: expected string array.');
    }
    T? parsed;
    for (final value in values) {
      if (value.name == item) {
        parsed = value;
        break;
      }
    }
    if (parsed == null) {
      throw FormatException('Invalid canonical Workout Profile $key item: $item');
    }
    result.add(parsed);
  }
  return Set.unmodifiable(result);
}

Set<String>? _parseOptionalStringSet(Object? raw, String key) {
  if (raw == null) return null;
  if (raw is! List) {
    throw FormatException('Invalid canonical Workout Profile $key: expected string array or null.');
  }
  final result = <String>{};
  for (final item in raw) {
    if (item is! String) {
      throw FormatException('Invalid canonical Workout Profile $key: expected string array.');
    }
    result.add(item);
  }
  return Set.unmodifiable(result);
}

List<String>? _sortedEnumNames<T extends Enum>(Set<T>? values) {
  if (values == null) return null;
  final result = values.map((value) => value.name).toList(growable: false)
    ..sort();
  return result;
}

List<String>? _sortedStrings(Set<String>? values) {
  if (values == null) return null;
  final result = values.toList(growable: false)..sort();
  return result;
}
