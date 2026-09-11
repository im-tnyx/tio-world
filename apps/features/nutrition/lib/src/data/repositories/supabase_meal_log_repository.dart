import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/repositories/meal_log_repository.dart';

typedef CurrentMealLogUserId = String? Function();

/// Injectable table seam for focused mapping/error tests.
abstract interface class MealLogTableGateway {
  Future<Map<String, dynamic>> insertRow(Map<String, dynamic> payload);

  Future<Map<String, dynamic>?> readRow({
    required String userId,
    required String id,
  });
}

final class SupabaseMealLogTableGateway implements MealLogTableGateway {
  const SupabaseMealLogTableGateway(this._client);

  static const _columns =
      'id, user_id, mode, meal_category_id, meal_name, note, consumed_at, '
      'consumed_local_date, consumed_timezone_id, consumed_utc_offset_minutes, '
      'capture_source, manual_nutrition_snapshot, created_at, updated_at';

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> insertRow(Map<String, dynamic> payload) async {
    final row = await _client
        .from('meal_log_entries')
        .insert(payload)
        .select(_columns)
        .single();
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<Map<String, dynamic>?> readRow({
    required String userId,
    required String id,
  }) async {
    final row = await _client
        .from('meal_log_entries')
        .select(_columns)
        .eq('user_id', userId)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }
}

/// Supabase adapter for the manual MealLog persistence foundation.
///
/// Authenticated identity is derived from the current Supabase session and RLS
/// remains the final database ownership authority. This adapter performs no
/// retries or idempotency reconciliation; TNYX-116 owns those semantics.
final class SupabaseMealLogRepository implements MealLogRepository {
  SupabaseMealLogRepository({
    required SupabaseClient client,
    MealLogTableGateway? gateway,
    CurrentMealLogUserId? currentUserId,
  })  : _gateway = gateway ?? SupabaseMealLogTableGateway(client),
        _currentUserId = currentUserId ?? (() => client.auth.currentUser?.id);

  final MealLogTableGateway _gateway;
  final CurrentMealLogUserId _currentUserId;

  @override
  Future<MealLogEntry> createManual(ManualMealLogCreate input) async {
    final userId = _requireUserId();
    final row = await _gateway.insertRow({
      'user_id': userId,
      'mode': MealLogMode.manual.storageValue,
      'meal_category_id': input.mealCategoryId,
      'meal_name': input.mealName,
      'note': input.note,
      'consumed_at': input.consumedAt.toUtc().toIso8601String(),
      'consumed_local_date': input.consumedLocalDate.toIso8601String(),
      'consumed_timezone_id': input.consumedTimezoneId,
      'consumed_utc_offset_minutes': input.consumedUtcOffsetMinutes,
      'capture_source': input.captureSource?.storageValue,
      'manual_nutrition_snapshot': input.manualNutritionSnapshot.toJson(),
    });
    return _decodeManualRow(row, expectedUserId: userId);
  }

  @override
  Future<MealLogEntry?> readById(String id) async {
    final userId = _requireUserId();
    _requireNonBlank(id, 'id');
    final row = await _gateway.readRow(userId: userId, id: id);
    if (row == null) return null;
    return _decodeManualRow(row, expectedUserId: userId);
  }

  String _requireUserId() {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) {
      throw StateError('Please sign in to access MealLog history.');
    }
    return userId;
  }

  static MealLogEntry _decodeManualRow(
    Map<String, dynamic> row, {
    required String expectedUserId,
  }) {
    _requireKeys(row);

    final userId = _requiredString(row, 'user_id');
    if (userId != expectedUserId) {
      throw const FormatException(
        'Invalid MealLog row: user_id does not match the authenticated owner.',
      );
    }

    final rawMode = _requiredString(row, 'mode');
    final mode = MealLogMode.fromStorageValue(rawMode);
    if (mode != MealLogMode.manual) {
      throw FormatException('Unsupported MealLog mode: $rawMode.');
    }

    MealLogCaptureSource? captureSource;
    final rawCaptureSource = _nullableString(row, 'capture_source');
    if (rawCaptureSource != null) {
      captureSource =
          MealLogCaptureSource.fromStorageValue(rawCaptureSource);
      if (captureSource == null) {
        throw FormatException(
          'Unsupported MealLog capture source: $rawCaptureSource.',
        );
      }
    }

    final timezoneId = _normalizeOptionalText(
      _nullableString(row, 'consumed_timezone_id'),
    );
    final utcOffsetMinutes =
        _nullableInt(row, 'consumed_utc_offset_minutes');
    if (timezoneId == null && utcOffsetMinutes == null) {
      throw const FormatException(
        'Invalid MealLog row: consumed timezone context is missing.',
      );
    }

    final snapshotJson = _jsonObject(row['manual_nutrition_snapshot']);
    final snapshot = NutritionSnapshot.fromJson(snapshotJson);

    return MealLogEntry.manual(
      id: _requiredString(row, 'id'),
      userId: userId,
      mealCategoryId: _requiredString(row, 'meal_category_id'),
      mealName: _nullableString(row, 'meal_name'),
      note: _nullableString(row, 'note'),
      consumedAt: _requiredDateTime(row, 'consumed_at'),
      consumedLocalDate: MealLogLocalDate.fromIso8601String(
        _requiredString(row, 'consumed_local_date'),
      ),
      consumedTimezoneId: timezoneId,
      consumedUtcOffsetMinutes: utcOffsetMinutes,
      captureSource: captureSource,
      manualNutritionSnapshot: snapshot,
      createdAt: _requiredDateTime(row, 'created_at'),
      updatedAt: _requiredDateTime(row, 'updated_at'),
    );
  }

  static const _requiredRowKeys = <String>{
    'id',
    'user_id',
    'mode',
    'meal_category_id',
    'meal_name',
    'note',
    'consumed_at',
    'consumed_local_date',
    'consumed_timezone_id',
    'consumed_utc_offset_minutes',
    'capture_source',
    'manual_nutrition_snapshot',
    'created_at',
    'updated_at',
  };

  static void _requireKeys(Map<String, dynamic> row) {
    for (final key in _requiredRowKeys) {
      if (!row.containsKey(key)) {
        throw FormatException('Invalid MealLog row: missing $key.');
      }
    }
  }

  static String _requiredString(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is! String) {
      throw FormatException('Invalid MealLog row: $key must be a string.');
    }
    return value;
  }

  static String? _nullableString(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value == null) return null;
    if (value is! String) {
      throw FormatException(
        'Invalid MealLog row: $key must be a string or null.',
      );
    }
    return value;
  }

  static int? _nullableInt(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value == null) return null;
    if (value is! int) {
      throw FormatException(
        'Invalid MealLog row: $key must be an integer or null.',
      );
    }
    return value;
  }

  static DateTime _requiredDateTime(Map<String, dynamic> row, String key) {
    final raw = _requiredString(row, key);
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      throw FormatException('Invalid MealLog row: $key is not a timestamp.');
    }
    return parsed.toUtc();
  }

  static Map<String, Object?> _jsonObject(Object? value) {
    if (value is! Map<Object?, Object?>) {
      throw const FormatException(
        'Invalid MealLog row: manual_nutrition_snapshot must be an object.',
      );
    }

    final result = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        throw const FormatException(
          'Invalid MealLog row: snapshot keys must be strings.',
        );
      }
      result[key] = entry.value;
    }
    return result;
  }

  static String? _normalizeOptionalText(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }

  static String _requireNonBlank(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'must not be blank');
    }
    return value;
  }
}
