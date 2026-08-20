import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/profile_settings_update.dart';
import '../../domain/repositories/profile_settings_repository.dart';

/// Supabase-backed narrow persistence boundary for Profile Settings.
class SupabaseProfileSettingsRepository implements ProfileSettingsRepository {
  const SupabaseProfileSettingsRepository({required SupabaseClient client})
      : _client = client;

  final SupabaseClient _client;

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError('Please sign in to update profile settings.');
    }
    return userId;
  }

  @override
  Future<void> updateProfileSettings(ProfileSettingsUpdate update) async {
    final userId = _requireUserId();
    final name = update.name.trim();
    if (name.isEmpty) {
      throw ArgumentError.value(update.name, 'name', 'Name is required.');
    }

    final dobIso = update.dateOfBirth.toIso8601String().split('T').first;
    final updatedRow = await _client
        .from('users')
        .update({
          'name': name,
          'gender': update.gender.name,
          'date_of_birth': dobIso,
          'dob': dobIso,
          'height_cm': update.heightCm,
          'current_weight_kg': update.currentWeightKg,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', userId)
        .select('id')
        .maybeSingle();

    if (updatedRow == null) {
      throw StateError('Profile is not initialized for the current account.');
    }
  }
}
