import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/nutrition_targets_data.dart';
import '../../domain/repositories/nutrition_targets_repository.dart';

typedef CurrentNutritionTargetsUserId = String? Function();

abstract interface class NutritionTargetsTableGateway {
  Future<Map<String, dynamic>?> readRow(String userId);

  Future<void> upsertRow(Map<String, dynamic> payload);
}

final class SupabaseNutritionTargetsTableGateway
    implements NutritionTargetsTableGateway {
  const SupabaseNutritionTargetsTableGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> readRow(String userId) async {
    // Deliberately does not select additional_nutrient_goals. Additional
    // Nutrition is a calculated read-only surface in V1, so nothing in the app
    // reads that column; selecting a column no consumer needs would only
    // couple every Nutrition Targets read to a schema detail this build has no
    // use for.
    return _client
        .from('user_nutrition_targets')
        .select(
          'calories_kcal, protein_grams, carbohydrate_grams, fat_grams, '
          'fiber_grams, customization_state, customized_fields, '
          'recommendation_metadata',
        )
        .eq('user_id', userId)
        .maybeSingle();
  }

  @override
  Future<void> upsertRow(Map<String, dynamic> payload) async {
    await _client
        .from('user_nutrition_targets')
        .upsert(payload, onConflict: 'user_id');
  }
}

/// Supabase adapter for the canonical Nutrition Targets owner.
///
/// It never writes `user_nutrition_profiles.macro_targets` or the legacy
/// `user_targets` table and never mutates authentication state.
///
/// It also never writes `additional_nutrient_goals`. That column is applied
/// and reserved for a future editing slice; V1 Additional Nutrition is
/// derived at display time and has no persistence at all.
final class SupabaseNutritionTargetsRepository
    implements NutritionTargetsRepository {
  SupabaseNutritionTargetsRepository({
    required SupabaseClient client,
    NutritionTargetsTableGateway? gateway,
    CurrentNutritionTargetsUserId? currentUserId,
  })  : _gateway = gateway ?? SupabaseNutritionTargetsTableGateway(client),
        _currentUserId = currentUserId ?? (() => client.auth.currentUser?.id);

  final NutritionTargetsTableGateway _gateway;
  final CurrentNutritionTargetsUserId _currentUserId;

  @override
  Future<NutritionTargetsData?> read() async {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) return null;

    final row = await _gateway.readRow(userId);
    if (row == null) return null;

    final targets = NutritionTargetsData(
      caloriesKcal: _parseOptionalPositiveInt(
        row['calories_kcal'],
        'calories_kcal',
      ),
      proteinGrams: _parseOptionalNonnegativeDouble(
        row['protein_grams'],
        'protein_grams',
      ),
      carbohydrateGrams: _parseOptionalNonnegativeDouble(
        row['carbohydrate_grams'],
        'carbohydrate_grams',
      ),
      fatGrams: _parseOptionalNonnegativeDouble(row['fat_grams'], 'fat_grams'),
      fiberGrams:
          _parseOptionalNonnegativeDouble(row['fiber_grams'], 'fiber_grams'),
      customizationState: parseNutritionTargetCustomizationState(
        row['customization_state'],
      ),
      customizedFields: _parseRequiredStringSet(
        row['customized_fields'],
        'customized_fields',
      ),
      recommendationMetadata: _parseRequiredObjectMap(
        row['recommendation_metadata'],
        'recommendation_metadata',
      ),
    );

    try {
      targets.validate();
      return targets;
    } on ArgumentError catch (error) {
      throw FormatException(
        'Invalid canonical user_nutrition_targets row: ${error.message}',
      );
    }
  }

  @override
  Future<void> upsert(NutritionTargetsData targets) async {
    final userId = _requireUserId();
    targets.validate();

    final customizedFields = targets.customizedFields.toList(growable: false)
      ..sort();

    await _gateway.upsertRow({
      'user_id': userId,
      'calories_kcal': targets.caloriesKcal,
      'protein_grams': targets.proteinGrams,
      'carbohydrate_grams': targets.carbohydrateGrams,
      'fat_grams': targets.fatGrams,
      'fiber_grams': targets.fiberGrams,
      'customization_state': targets.customizationState.storageValue,
      'customized_fields': customizedFields,
      'recommendation_metadata':
          Map<String, Object?>.from(targets.recommendationMetadata),
      // Deliberately omitted: an omitted column is never written by
      // ON CONFLICT DO UPDATE, so a core-five write cannot disturb the
      // reserved additional_nutrient_goals value.
    });
  }

  String _requireUserId() {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) {
      throw StateError('Please sign in to save your Nutrition targets.');
    }
    return userId;
  }
}

int? _parseOptionalPositiveInt(Object? raw, String key) {
  if (raw == null) return null;
  if (raw is! num) {
    throw FormatException('Invalid canonical $key: expected integer or null.');
  }

  final numeric = raw.toDouble();
  if (!numeric.isFinite ||
      numeric != numeric.truncateToDouble() ||
      numeric <= 0) {
    throw FormatException('Invalid canonical $key: expected positive integer.');
  }
  return numeric.toInt();
}

double? _parseOptionalNonnegativeDouble(Object? raw, String key) {
  if (raw == null) return null;
  if (raw is! num) {
    throw FormatException('Invalid canonical $key: expected number or null.');
  }

  final numeric = raw.toDouble();
  if (!numeric.isFinite || numeric < 0) {
    throw FormatException(
      'Invalid canonical $key: expected finite nonnegative number.',
    );
  }
  return numeric;
}

Set<String> _parseRequiredStringSet(Object? raw, String key) {
  if (raw is! List) {
    throw FormatException('Invalid canonical $key: expected string array.');
  }

  final values = <String>{};
  for (final value in raw) {
    if (value is! String) {
      throw FormatException('Invalid canonical $key: expected string array.');
    }
    values.add(value);
  }
  return Set.unmodifiable(values);
}

Map<String, Object?> _parseRequiredObjectMap(Object? raw, String key) {
  if (raw is! Map) {
    throw FormatException('Invalid canonical $key: expected JSON object.');
  }

  final values = <String, Object?>{};
  for (final entry in raw.entries) {
    final mapKey = entry.key;
    if (mapKey is! String) {
      throw FormatException('Invalid canonical $key: expected string keys.');
    }
    values[mapKey] = entry.value;
  }
  return Map.unmodifiable(values);
}
