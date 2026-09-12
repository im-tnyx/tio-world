import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/meal_categories_config.dart';
import '../../domain/models/meal_categories_config_codec.dart';
import '../../domain/repositories/meal_categories_repository.dart';

typedef CurrentMealCategoriesUserId = String? Function();

abstract interface class MealCategoriesTableGateway {
  Future<Map<String, dynamic>?> readRow(String userId);

  Future<void> upsertRow(Map<String, dynamic> payload);
}

final class SupabaseMealCategoriesTableGateway
    implements MealCategoriesTableGateway {
  const SupabaseMealCategoriesTableGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> readRow(String userId) async {
    return _client
        .from('user_nutrition_profiles')
        .select('meal_categories_config')
        .eq('user_id', userId)
        .maybeSingle();
  }

  @override
  Future<void> upsertRow(Map<String, dynamic> payload) async {
    await _client
        .from('user_nutrition_profiles')
        .upsert(payload, onConflict: 'user_id');
  }
}

/// Supabase adapter for the authenticated user's Meal Categories config.
///
/// This repository owns only `user_nutrition_profiles.meal_categories_config`.
/// The database CHECK and retained-ID trigger remain the authoritative atomic
/// persistence boundary for direct and concurrent writes.
final class SupabaseMealCategoriesRepository
    implements MealCategoriesRepository, MealCategoriesChangeSource {
  SupabaseMealCategoriesRepository({
    required SupabaseClient client,
    MealCategoriesTableGateway? gateway,
    CurrentMealCategoriesUserId? currentUserId,
  })  : _gateway = gateway ?? SupabaseMealCategoriesTableGateway(client),
        _currentUserId = currentUserId ?? (() => client.auth.currentUser?.id);

  final MealCategoriesTableGateway _gateway;
  final CurrentMealCategoriesUserId _currentUserId;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<MealCategoriesConfig> read() async {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) {
      return MealCategoriesConfig.resolve(null);
    }

    final row = await _gateway.readRow(userId);
    if (row == null) return MealCategoriesConfig.resolve(null);
    if (!row.containsKey('meal_categories_config')) {
      throw const FormatException(
        'Invalid Meal Categories row: missing meal_categories_config.',
      );
    }

    final customized =
        MealCategoriesConfigCodec.decode(row['meal_categories_config']);
    return MealCategoriesConfig.resolve(customized);
  }

  @override
  Future<void> upsert(MealCategoriesConfig config) async {
    final userId = _requireUserId();
    config.validate();

    try {
      await _gateway.upsertRow({
        'user_id': userId,
        'meal_categories_config': MealCategoriesConfigCodec.encode(config),
      });
    } on PostgrestException catch (error) {
      // The database refusing this payload is not a transport hiccup. The
      // CHECK constraint and retained-ID trigger both reject through SQLSTATE
      // class 23, and both mean the same thing here: what was sent is not a
      // legal successor to what is stored. Sending it again cannot help, and
      // would overwrite another device's work if it ever did.
      if (_isIntegrityViolation(error)) {
        throw MealCategoriesWriteConflict(
          message: 'Your meal categories were changed somewhere else.',
          cause: error,
        );
      }
      rethrow;
    }

    // Publish only after persistence confirms the write. A rejected or failed
    // mutation must never make readers refresh as though new truth existed.
    _changes.add(null);
  }

  /// SQLSTATE class 23 — integrity constraint violation.
  ///
  /// Matched on the class rather than on individual codes so a guard added
  /// later, raising a different code in the same family, is classified
  /// correctly without this adapter needing to learn about it.
  static bool _isIntegrityViolation(PostgrestException error) {
    final code = error.code;
    return code != null && code.length >= 2 && code.startsWith('23');
  }

  String _requireUserId() {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) {
      throw StateError('Please sign in to save your Meal Categories.');
    }
    return userId;
  }
}
