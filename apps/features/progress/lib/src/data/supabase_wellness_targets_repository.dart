import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/wellness_targets.dart';

typedef CurrentWellnessUserId = String? Function();

abstract interface class WellnessTargetsTableGateway {
  Future<Map<String, dynamic>?> readRow(String userId);

  Future<void> upsertRow(Map<String, dynamic> payload);
}

final class SupabaseWellnessTargetsTableGateway
    implements WellnessTargetsTableGateway {
  const SupabaseWellnessTargetsTableGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> readRow(String userId) async {
    return _client
        .from('user_wellness_targets')
        .select(
          'steps_target, water_target_ml, sleep_target_minutes, '
          'bed_time, wake_up_time',
        )
        .eq('user_id', userId)
        .maybeSingle();
  }

  @override
  Future<void> upsertRow(Map<String, dynamic> payload) async {
    await _client
        .from('user_wellness_targets')
        .upsert(payload, onConflict: 'user_id');
  }
}

/// Supabase adapter for the canonical Wellness target owner.
///
/// This repository targets only `public.user_wellness_targets`. Nutrition may
/// consume Wellness values as calculation inputs, but it is not the durable
/// owner of these concepts.
final class SupabaseWellnessTargetsRepository
    implements WellnessTargetsRepository {
  SupabaseWellnessTargetsRepository({
    required SupabaseClient client,
    WellnessTargetsTableGateway? gateway,
    CurrentWellnessUserId? currentUserId,
  })  : _gateway = gateway ?? SupabaseWellnessTargetsTableGateway(client),
        _currentUserId = currentUserId ?? (() => client.auth.currentUser?.id);

  final WellnessTargetsTableGateway _gateway;
  final CurrentWellnessUserId _currentUserId;

  @override
  Future<WellnessTargetsData?> read() async {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) return null;

    final row = await _gateway.readRow(userId);
    if (row == null) return null;

    try {
      final targets = WellnessTargetsData(
        dailySteps: _parseOptionalInt(row['steps_target'], 'steps_target'),
        waterMl: _parseOptionalInt(row['water_target_ml'], 'water_target_ml'),
        sleepTargetMinutes: _parseOptionalInt(
          row['sleep_target_minutes'],
          'sleep_target_minutes',
        ),
        bedTimeMinutes: _parseOptionalTime(row['bed_time'], 'bed_time'),
        wakeTimeMinutes: _parseOptionalTime(row['wake_up_time'], 'wake_up_time'),
      );
      targets.validate();
      return targets;
    } on ArgumentError catch (error) {
      throw FormatException(
        'Invalid canonical user_wellness_targets row: ${error.message}',
      );
    }
  }

  @override
  Future<void> upsert(WellnessTargetsData targets) async {
    final userId = _requireUserId();
    targets.validate();

    await _gateway.upsertRow({
      'user_id': userId,
      'steps_target': targets.dailySteps,
      'water_target_ml': targets.waterMl,
      'sleep_target_minutes': targets.sleepTargetMinutes,
      'bed_time': _formatOptionalTime(targets.bedTimeMinutes),
      'wake_up_time': _formatOptionalTime(targets.wakeTimeMinutes),
    });
  }

  String _requireUserId() {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) {
      throw StateError('Please sign in to save Wellness targets.');
    }
    return userId;
  }
}

int? _parseOptionalInt(Object? raw, String key) {
  if (raw == null) return null;
  if (raw is! num) {
    throw FormatException('Invalid canonical $key: expected integer or null.');
  }

  final numeric = raw.toDouble();
  if (!numeric.isFinite || numeric != numeric.truncateToDouble()) {
    throw FormatException('Invalid canonical $key: expected whole number.');
  }
  return numeric.toInt();
}

int? _parseOptionalTime(Object? raw, String key) {
  if (raw == null) return null;
  if (raw is! String) {
    throw FormatException('Invalid canonical $key: expected SQL TIME string.');
  }

  final parts = raw.trim().split(':');
  if (parts.length < 2 || parts.length > 3) {
    throw FormatException('Invalid canonical $key: $raw.');
  }

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  final second = parts.length == 3 ? int.tryParse(parts[2]) : 0;
  if (hour == null ||
      minute == null ||
      second == null ||
      hour < 0 ||
      hour > 23 ||
      minute < 0 ||
      minute > 59 ||
      second != 0) {
    throw FormatException('Invalid canonical $key: $raw.');
  }

  return (hour * 60) + minute;
}

String? _formatOptionalTime(int? minutes) {
  if (minutes == null) return null;
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  return '${hours.toString().padLeft(2, '0')}:'
      '${mins.toString().padLeft(2, '0')}:00';
}
