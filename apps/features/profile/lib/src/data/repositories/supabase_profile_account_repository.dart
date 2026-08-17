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

  String _normalizeMobile(String mobile) {
    final trimmed = mobile.trim();
    if (trimmed.isEmpty) return '';

    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) return '+91 $digits';
    if (digits.startsWith('91') && digits.length == 12) {
      return '+91 ${digits.substring(2)}';
    }
    return trimmed;
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

  UsernameAvailabilityReason? _parseReason(Object? value) {
    return switch (value) {
      'taken' => UsernameAvailabilityReason.taken,
      'invalid' => UsernameAvailabilityReason.invalid,
      'reserved' => UsernameAvailabilityReason.reserved,
      'profile_missing' => UsernameAvailabilityReason.profileMissing,
      null => null,
      _ => UsernameAvailabilityReason.unknown,
    };
  }

  Map<String, dynamic> _requireRpcMap(Object? response, String rpcName) {
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    throw StateError('$rpcName returned an unexpected response.');
  }

  List<String> _parseSuggestions(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<String>()
        .map((suggestion) => suggestion.trim().toLowerCase())
        .where((suggestion) => suggestion.isNotEmpty)
        .toList(growable: false);
  }

  UsernameAvailabilityCheck _parseAvailability(Object? response) {
    final map = _requireRpcMap(response, 'check_username_availability');
    return UsernameAvailabilityCheck(
      normalized: (map['normalized'] as String? ?? '').trim().toLowerCase(),
      isAvailable: map['is_available'] == true,
      reason: _parseReason(map['reason']),
      suggestions: _parseSuggestions(map['suggestions']),
    );
  }

  @override
  Future<String?> currentUsername() async {
    final userId = _requireUserId();
    final row = await _client
        .from('users')
        .select('username')
        .eq('id', userId)
        .maybeSingle();
    final username = (row?['username'] as String?)?.trim().toLowerCase();
    return username == null || username.isEmpty ? null : username;
  }

  @override
  Future<UsernameAvailabilityCheck> checkUsernameAvailability(
    String username,
  ) async {
    _requireUser();
    final normalizedUsername = _normalizeUsername(username);
    if (!_isValidUsername(normalizedUsername)) {
      return UsernameAvailabilityCheck(
        normalized: normalizedUsername,
        isAvailable: false,
        reason: UsernameAvailabilityReason.invalid,
      );
    }

    final response = await _client.rpc<dynamic>(
      'check_username_availability',
      params: {'p_username': normalizedUsername},
    );
    return _parseAvailability(response);
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    return (await checkUsernameAvailability(username)).isAvailable;
  }

  Future<Map<String, dynamic>> _claimUsername(String username) async {
    final response = await _client.rpc<dynamic>(
      'claim_username',
      params: {'p_username': username},
    );
    return _requireRpcMap(response, 'claim_username');
  }

  Never _throwClaimFailure(Map<String, dynamic> claim) {
    throw UsernameUnavailableException(
      reason: _parseReason(claim['reason']),
      suggestions: _parseSuggestions(claim['suggestions']),
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

    var claim = await _claimUsername(normalizedUsername);
    if (claim['claimed'] == true) return;

    if (_parseReason(claim['reason']) !=
        UsernameAvailabilityReason.profileMissing) {
      _throwClaimFailure(claim);
    }

    final nowIso = DateTime.now().toUtc().toIso8601String();
    try {
      await _client.from('users').insert({
        'id': user.id,
        'name': _resolveProfileName(user),
        if (user.email != null && user.email!.trim().isNotEmpty)
          'email': user.email!.trim().toLowerCase(),
        'last_active_at': nowIso,
        'updated_at': nowIso,
      });
    } on PostgrestException catch (error) {
      if (error.code != '23505') rethrow;
    }

    claim = await _claimUsername(normalizedUsername);
    if (claim['claimed'] == true) return;
    _throwClaimFailure(claim);
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
    final normalizedMobile = _normalizeMobile(mobile);
    final previousMobile = _normalizeMobile(
      (current['mobile'] as String?)?.trim() ?? '',
    );
    final mobileChanged = previousMobile != normalizedMobile;

    if (normalizedUsername.isNotEmpty) {
      if (!_isValidUsername(normalizedUsername)) {
        throw ArgumentError.value(
          username,
          'username',
          'must be 3-30 characters using only lowercase letters, numbers, dots, and underscores',
        );
      }

      final availability = await checkUsernameAvailability(normalizedUsername);
      if (!availability.isAvailable) {
        throw UsernameUnavailableException(
          reason: availability.reason,
          suggestions: availability.suggestions,
        );
      }
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
        throw const UsernameUnavailableException(
          reason: UsernameAvailabilityReason.taken,
        );
      }
      if (error.code == '23514') {
        throw const UsernameUnavailableException(
          reason: UsernameAvailabilityReason.invalid,
        );
      }
      rethrow;
    }
  }
}
