import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/workout_split.dart';
import '../../domain/models/workout_target_goal.dart';
import '../../domain/models/workout_targets_data.dart';
import '../../domain/models/workout_training_day.dart';
import '../../domain/repositories/workout_targets_repository.dart';

typedef CurrentWorkoutTargetsUserId = String? Function();

abstract interface class WorkoutTargetsTableGateway {
  Future<Map<String, dynamic>?> readRow(String userId);

  Future<void> upsertRow(Map<String, dynamic> payload);
}

final class SupabaseWorkoutTargetsTableGateway
    implements WorkoutTargetsTableGateway {
  const SupabaseWorkoutTargetsTableGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> readRow(String userId) async {
    return _client
        .from('user_workout_targets')
        .select(
          'primary_workout_goal, primary_goal_rank, supporting_workout_goal, '
          'supporting_goal_rank, training_days, preferred_duration_mins, '
          'split_program, special_event, special_event_date',
        )
        .eq('user_id', userId)
        .maybeSingle();
  }

  @override
  Future<void> upsertRow(Map<String, dynamic> payload) async {
    await _client
        .from('user_workout_targets')
        .upsert(payload, onConflict: 'user_id');
  }
}

/// Supabase adapter for canonical Workout goals/schedule/plan constraints.
///
/// It never writes `user_workout_profiles` planning mirrors, never falls back
/// to `user_workout_preferences`, and never mutates authentication state.
final class SupabaseWorkoutTargetsRepository
    implements WorkoutTargetsRepository {
  SupabaseWorkoutTargetsRepository({
    required SupabaseClient client,
    WorkoutTargetsTableGateway? gateway,
    CurrentWorkoutTargetsUserId? currentUserId,
  })  : _gateway = gateway ?? SupabaseWorkoutTargetsTableGateway(client),
        _currentUserId = currentUserId ?? (() => client.auth.currentUser?.id);

  final WorkoutTargetsTableGateway _gateway;
  final CurrentWorkoutTargetsUserId _currentUserId;

  @override
  Future<WorkoutTargetsData?> read() async {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) return null;

    final row = await _gateway.readRow(userId);
    if (row == null) return null;

    final targets = WorkoutTargetsData(
      primaryWorkoutGoal:
          _parseOptionalGoal(row['primary_workout_goal'], 'primary_workout_goal'),
      primaryGoalRank:
          _parseOptionalInteger(row['primary_goal_rank'], 'primary_goal_rank'),
      supportingWorkoutGoal: _parseOptionalGoal(
        row['supporting_workout_goal'],
        'supporting_workout_goal',
      ),
      supportingGoalRank: _parseOptionalInteger(
        row['supporting_goal_rank'],
        'supporting_goal_rank',
      ),
      trainingDays: _parseRequiredTrainingDays(row['training_days']),
      preferredDurationMins: _parseOptionalInteger(
        row['preferred_duration_mins'],
        'preferred_duration_mins',
      ),
      splitProgram: _parseOptionalSplit(row['split_program']),
      specialEvent: _parseOptionalString(row['special_event'], 'special_event'),
      specialEventDate: _parseOptionalDate(row['special_event_date']),
    );

    try {
      targets.validate();
      return targets;
    } on ArgumentError catch (error) {
      throw FormatException(
        'Invalid canonical user_workout_targets row: ${error.message}',
      );
    }
  }

  @override
  Future<void> upsert(WorkoutTargetsData targets) async {
    final userId = _requireUserId();
    targets.validate();

    final trainingDays =
        targets.trainingDays.map((day) => day.name).toList(growable: false)
          ..sort();

    await _gateway.upsertRow({
      'user_id': userId,
      'primary_workout_goal': targets.primaryWorkoutGoal?.storageValue,
      'primary_goal_rank': targets.primaryGoalRank,
      'supporting_workout_goal': targets.supportingWorkoutGoal?.storageValue,
      'supporting_goal_rank': targets.supportingGoalRank,
      'training_days': trainingDays,
      'preferred_duration_mins': targets.preferredDurationMins,
      'split_program': targets.splitProgram?.name,
      'special_event': targets.specialEvent,
      'special_event_date': _dateStorage(targets.specialEventDate),
    });
  }

  String _requireUserId() {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) {
      throw StateError('Please sign in to save your Workout targets.');
    }
    return userId;
  }
}

WorkoutTargetGoal? _parseOptionalGoal(Object? raw, String key) {
  if (raw == null) return null;
  if (raw is! String) {
    throw FormatException('Invalid canonical $key: expected string or null.');
  }
  try {
    return parseWorkoutTargetGoal(raw);
  } on FormatException {
    throw FormatException('Invalid canonical $key: $raw');
  }
}

int? _parseOptionalInteger(Object? raw, String key) {
  if (raw == null) return null;
  if (raw is! num) {
    throw FormatException('Invalid canonical $key: expected integer or null.');
  }
  final numeric = raw.toDouble();
  if (!numeric.isFinite || numeric != numeric.truncateToDouble()) {
    throw FormatException('Invalid canonical $key: expected integer or null.');
  }
  return numeric.toInt();
}

Set<WorkoutTrainingDay> _parseRequiredTrainingDays(Object? raw) {
  if (raw is! List) {
    throw const FormatException(
      'Invalid canonical training_days: expected string array.',
    );
  }

  final result = <WorkoutTrainingDay>{};
  for (final item in raw) {
    if (item is! String) {
      throw const FormatException(
        'Invalid canonical training_days: expected string array.',
      );
    }
    WorkoutTrainingDay? parsed;
    for (final day in WorkoutTrainingDay.values) {
      if (day.name == item) {
        parsed = day;
        break;
      }
    }
    if (parsed == null) {
      throw FormatException('Invalid canonical training_days item: $item');
    }
    result.add(parsed);
  }
  return Set.unmodifiable(result);
}

WorkoutSplit? _parseOptionalSplit(Object? raw) {
  if (raw == null) return null;
  if (raw is! String) {
    throw const FormatException(
      'Invalid canonical split_program: expected string or null.',
    );
  }
  for (final split in WorkoutSplit.values) {
    if (split.name == raw) return split;
  }
  throw FormatException('Invalid canonical split_program: $raw');
}

String? _parseOptionalString(Object? raw, String key) {
  if (raw == null) return null;
  if (raw is! String) {
    throw FormatException('Invalid canonical $key: expected string or null.');
  }
  return raw;
}

DateTime? _parseOptionalDate(Object? raw) {
  if (raw == null) return null;
  if (raw is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
    throw const FormatException(
      'Invalid canonical special_event_date: expected YYYY-MM-DD or null.',
    );
  }

  final parts = raw.split('-').map(int.parse).toList(growable: false);
  final date = DateTime.utc(parts[0], parts[1], parts[2]);
  if (date.year != parts[0] || date.month != parts[1] || date.day != parts[2]) {
    throw FormatException('Invalid canonical special_event_date: $raw');
  }
  return date;
}

String? _dateStorage(DateTime? value) {
  if (value == null) return null;
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
