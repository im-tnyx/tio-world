import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/profile_account_repository.dart';

const _usernameMinLength = 3;
const _usernameMaxLength = 30;
final _usernamePattern = RegExp(r'^[a-z0-9._]+$');

/// Supabase-backed Account Settings persistence.
///
/// Updates only fields owned by Account Settings and never creates or switches
/// authentication identities as a write fallback.
class SupabaseProfileAccountRepository implements ProfileAccountRepository {
  const SupabaseProfileAccountRepository({
    required SupabaseClient client,
  }) : _client = client;

  final SupabaseClient _client;

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null || user.id.isEmpty) {
      throw StateError('Please sign in to update account settings.');
    }
    return user;
  }

  String _requireUserId() => _requireUser().id;

  String _normalizeUsername(String username) {
    return username.trim().toLowerCase();
  }

  bool _isValidUsername(String username) {
    return username.length >= _usernameMinLength &&
        username.length <= _usernameMaxLength &&
        _usernamePattern.hasMatch(username);
  }

  String _resolveProfileName(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    for (final key in const ['full_name', 'display_name', 'name']) {
      final value = metadata[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    final email = user.email?.trim() ?? '';
    if (email.contains('@')) {
      final localPart = email.split('@').first.trim();
      if (localPart.isNotEmpty) return localPart;
    }

    return 'Tio User';
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    _requireUser();
    final normalizedUsername = _normalizeUsername(username);
    if (!_isValidUsername(normalizedUsername)) return false;

    return _client.rpc<bool>(
      'is_username_available',
      params: {'p_username': normalizedUsername},
    );
  }

  @override
  Future<void> updateUsername(String username) async {
    final user = _requireUser();
    final normalizedUsername = _normalizeUsername(username);
    if (!_isValidUsername(normalizedUsername)) {
      throw ArgumentError.value(
        username,
        'username',
        'must be 3-30 characters using only lowercase letters, numbers, dots, and underscores',
      );
    }

    final nowIso = DateTime.now().toUtc().toIso8601String();
    try {
      final updatedRows = await _client
          .from('users')
          .update({
            'username': normalizedUsername,
            'updated_at': nowIso,
          })
          .eq('id', user.id)
          .select('id');

      if (updatedRows.isNotEmpty) return;

      // Google profile sync is intentionally best-effort and can still be
      // running when the mandatory Username checkpoint is reached. If the
      // local row is missing, create the minimum valid profile from auth
      // identity metadata. Username never participates in resolving `name`.
      await _client.from('users').upsert(
        {
          'id': user.id,
          'name': _resolveProfileName(user),
          if (user.email != null && user.email!.trim().isNotEmpty)
            'email': user.email!.trim().toLowerCase(),
          'username': normalizedUsername,
          'last_active_at': nowIso,
          'updated_at': nowIso,
        },
        onConflict: 'id',
      );
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw const UsernameUnavailableException();
      }
      rethrow;
    }
  }

  @override
  Future<void> updateAccountSettings({
    required String username,
    required String mobile,
  }) async {
    final userId = _requireUserId();

    final current = await _client
        .from('users')
        .select('mobile')
        .eq('id', userId)
        .maybeSingle();

    if (current == null) {
      throw StateError('Profile is not initialized for the current account.');
    }

    final normalizedUsername = _normalizeUsername(username);
    final normalizedMobile = mobile.trim();
    final previousMobile = (current['mobile'] as String?)?.trim() ?? '';
    final mobileChanged = previousMobile != normalizedMobile;

    if (normalizedUsername.isNotEmpty &&
        !_isValidUsername(normalizedUsername)) {
      throw ArgumentError.value(
        username,
        'username',
        'must be 3-30 characters using only lowercase letters, numbers, dots, and underscores',
      );
    }

    final payload = <String, dynamic>{
      'username': normalizedUsername.isEmpty ? null : normalizedUsername,
      'mobile': normalizedMobile.isEmpty ? null : normalizedMobile,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      if (mobileChanged) 'mobile_verified_at': null,
    };

    try {
      final updatedRows = await _client
          .from('users')
          .update(payload)
          .eq('id', userId)
          .select('id');

      if (updatedRows.isEmpty) {
        throw StateError(
          'Account settings update did not modify the current profile.',
        );
      }
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw const UsernameUnavailableException();
      }
      rethrow;
    }
  }
}
