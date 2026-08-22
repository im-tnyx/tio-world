import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/nutrition_profile_data.dart';
import '../../domain/repositories/nutrition_profile_repository.dart';

typedef CurrentNutritionProfileUserId = String? Function();

abstract interface class NutritionProfileTableGateway {
  Future<Map<String, dynamic>?> readRow(String userId);

  Future<void> upsertRow(Map<String, dynamic> payload);
}

final class SupabaseNutritionProfileTableGateway
    implements NutritionProfileTableGateway {
  const SupabaseNutritionProfileTableGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> readRow(String userId) async {
    return _client
        .from('user_nutrition_profiles')
        .select(
          'preferred_diet, allergies, disliked_foods, medical_conditions',
        )
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

/// Supabase adapter for canonical Nutrition Profile context.
///
/// It intentionally ignores the transitional Body/Profile/Wellness/target
/// columns that still physically exist in `user_nutrition_profiles`.
final class SupabaseNutritionProfileRepository
    implements NutritionProfileRepository {
  SupabaseNutritionProfileRepository({
    required SupabaseClient client,
    NutritionProfileTableGateway? gateway,
    CurrentNutritionProfileUserId? currentUserId,
  })  : _gateway = gateway ?? SupabaseNutritionProfileTableGateway(client),
        _currentUserId = currentUserId ?? (() => client.auth.currentUser?.id);

  final NutritionProfileTableGateway _gateway;
  final CurrentNutritionProfileUserId _currentUserId;

  @override
  Future<NutritionProfileData?> read() async {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) return null;

    final row = await _gateway.readRow(userId);
    if (row == null) return null;

    return NutritionProfileData(
      preferredDiet: _parseOptionalString(row['preferred_diet'], 'preferred_diet'),
      allergies: _parseOptionalStringSet(row['allergies'], 'allergies'),
      dislikedFoods:
          _parseOptionalStringSet(row['disliked_foods'], 'disliked_foods'),
      medicalConditions: _parseOptionalStringSet(
        row['medical_conditions'],
        'medical_conditions',
      ),
    );
  }

  @override
  Future<void> upsert(NutritionProfileData profile) async {
    final userId = _requireUserId();

    await _gateway.upsertRow({
      'user_id': userId,
      'preferred_diet': profile.preferredDiet,
      'allergies': _sortedList(profile.allergies),
      'disliked_foods': _sortedList(profile.dislikedFoods),
      'medical_conditions': _sortedList(profile.medicalConditions),
    });
  }

  String _requireUserId() {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) {
      throw StateError('Please sign in to save your Nutrition Profile.');
    }
    return userId;
  }
}

String? _parseOptionalString(Object? raw, String key) {
  if (raw == null) return null;
  if (raw is! String) {
    throw FormatException(
      'Invalid canonical Nutrition Profile $key: expected string or null.',
    );
  }
  return raw;
}

Set<String>? _parseOptionalStringSet(Object? raw, String key) {
  if (raw == null) return null;
  if (raw is! List) {
    throw FormatException(
      'Invalid canonical Nutrition Profile $key: expected string array or null.',
    );
  }

  final values = <String>{};
  for (final value in raw) {
    if (value is! String) {
      throw FormatException(
        'Invalid canonical Nutrition Profile $key: expected string array.',
      );
    }
    values.add(value);
  }
  return Set.unmodifiable(values);
}

List<String>? _sortedList(Set<String>? values) {
  if (values == null) return null;
  final result = values.toList(growable: false)..sort();
  return result;
}
