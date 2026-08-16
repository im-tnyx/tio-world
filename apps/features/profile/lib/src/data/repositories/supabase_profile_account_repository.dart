import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/profile_account_repository.dart';

/// Supabase-backed Account Settings persistence.
///
/// Updates only fields owned by Account Settings and never creates or switches
/// authentication identities as a write fallback.
class SupabaseProfileAccountRepository implements ProfileAccountRepository {
  const SupabaseProfileAccountRepository({
    required SupabaseClient client,
  }) : _client = client;

  final SupabaseClient _client;

  @override
  Future<void> updateAccountSettings({
    required String username,
    required String mobile,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError('Please sign in to update account settings.');
    }

    final current = await _client
        .from('users')
        .select('mobile')
        .eq('id', userId)
        .maybeSingle();

    if (current == null) {
      throw StateError('Profile is not initialized for the current account.');
    }

    final normalizedUsername = username.trim();
    final normalizedMobile = mobile.trim();
    final previousMobile = (current['mobile'] as String?)?.trim() ?? '';
    final mobileChanged = previousMobile != normalizedMobile;

    final payload = <String, dynamic>{
      'username': normalizedUsername.isEmpty ? null : normalizedUsername,
      'mobile': normalizedMobile.isEmpty ? null : normalizedMobile,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      if (mobileChanged) 'mobile_verified_at': null,
    };

    final updatedRows = await _client
        .from('users')
        .update(payload)
        .eq('id', userId)
        .select('id');

    if (updatedRows.isEmpty) {
      throw StateError('Account settings update did not modify the current profile.');
    }
  }
}
