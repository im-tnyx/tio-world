import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/hydration_preferences.dart';

typedef CurrentHydrationUserId = String? Function();

abstract interface class HydrationPreferencesTableGateway {
  Future<Map<String, dynamic>?> readRow(String userId);
  Future<void> upsertRow(Map<String, dynamic> payload);
}

final class SupabaseHydrationPreferencesTableGateway
    implements HydrationPreferencesTableGateway {
  const SupabaseHydrationPreferencesTableGateway(this._client);
  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> readRow(String userId) => _client
      .from('user_hydration_preferences')
      .select('default_glass_size_ml')
      .eq('user_id', userId)
      .maybeSingle();

  @override
  Future<void> upsertRow(Map<String, dynamic> payload) async {
    await _client
        .from('user_hydration_preferences')
        .upsert(payload, onConflict: 'user_id');
  }
}

final class SupabaseHydrationPreferencesRepository
    implements HydrationPreferencesRepository {
  SupabaseHydrationPreferencesRepository({
    required SupabaseClient client,
    HydrationPreferencesTableGateway? gateway,
    CurrentHydrationUserId? currentUserId,
  })  : _gateway = gateway ?? SupabaseHydrationPreferencesTableGateway(client),
        _currentUserId = currentUserId ?? (() => client.auth.currentUser?.id);

  final HydrationPreferencesTableGateway _gateway;
  final CurrentHydrationUserId _currentUserId;
  String? get _userId => _currentUserId()?.trim();

  @override
  Future<HydrationPreferences?> read() async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return null;
    final row = await _gateway.readRow(userId);
    _checkSameUser(userId);
    if (row == null) return null;
    if (!row.containsKey('default_glass_size_ml')) {
      throw const FormatException('Missing canonical default_glass_size_ml.');
    }
    final raw = row['default_glass_size_ml'];
    if (raw != null && raw is! int) {
      throw const FormatException('Expected integer ml or null.');
    }
    final preferences = HydrationPreferences(defaultGlassSizeMl: raw as int?);
    if (!HydrationPreferences.isValidGlassSize(
        preferences.defaultGlassSizeMl)) {
      throw const FormatException('Invalid canonical default_glass_size_ml.');
    }
    return preferences;
  }

  @override
  Future<void> upsert(HydrationPreferences preferences) async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      throw StateError('Please sign in to save Glass Size.');
    }
    preferences.validate();
    await _gateway.upsertRow({
      'user_id': userId,
      'default_glass_size_ml': preferences.defaultGlassSizeMl,
    });
    _checkSameUser(userId);
  }

  void _checkSameUser(String userId) {
    if (_userId != userId) {
      throw StateError('Account changed during the Glass Size request.');
    }
  }
}
