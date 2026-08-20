import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/profile_settings_update.dart';
import '../../domain/repositories/profile_settings_repository.dart';
import '../mappers/profile_settings_write_mapper.dart';

/// Supabase-backed narrow persistence boundary for Profile Settings.
class SupabaseProfileSettingsRepository implements ProfileSettingsRepository {
  const SupabaseProfileSettingsRepository({
    required SupabaseClient client,
    ProfileSettingsWriteMapper mapper = const ProfileSettingsWriteMapper(),
  })  : _client = client,
        _mapper = mapper;

  final SupabaseClient _client;
  final ProfileSettingsWriteMapper _mapper;

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
    final payload = _mapper.toPayload(
      update,
      updatedAt: DateTime.now(),
    );

    final updatedRow = await _client
        .from('users')
        .update(payload)
        .eq('id', userId)
        .select('id')
        .maybeSingle();

    if (updatedRow == null) {
      throw StateError('Profile is not initialized for the current account.');
    }
  }
}
