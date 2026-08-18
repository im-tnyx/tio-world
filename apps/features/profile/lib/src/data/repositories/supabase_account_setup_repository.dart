import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/account_setup_repository.dart';

/// Supabase-backed owner for the narrow Account Setup persistence boundary.
class SupabaseAccountSetupRepository implements AccountSetupRepository {
  const SupabaseAccountSetupRepository({required SupabaseClient client})
      : _client = client;

  final SupabaseClient _client;

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError('User is not authenticated');
    }
    return userId;
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

  @override
  Future<AccountSetupAccountState> readAccountSetupState() async {
    final userId = _requireUserId();
    final row = await _client
        .from('users')
        .select(
          'username,mobile,mobile_verified_at,account_setup_completed_at',
        )
        .eq('id', userId)
        .maybeSingle();

    if (row == null) return const AccountSetupAccountState();

    final username = (row['username'] as String?)?.trim().toLowerCase();
    final mobile = (row['mobile'] as String?)?.trim() ?? '';
    final isMobileVerified = row['mobile_verified_at'] != null;
    return AccountSetupAccountState(
      username: username == null || username.isEmpty ? null : username,
      mobile: mobile,
      isMobileVerified: isMobileVerified,
      // A trusted backend-verified mobile already satisfies the optional
      // Mobile step even if this row predates the explicit completion marker.
      isCompleted:
          row['account_setup_completed_at'] != null || isMobileVerified,
    );
  }

  @override
  Future<void> completeAccountSetup({String? mobile}) async {
    final userId = _requireUserId();
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final payload = <String, dynamic>{
      'account_setup_completed_at': nowIso,
      'updated_at': nowIso,
    };

    if (mobile != null) {
      final current = await _client
          .from('users')
          .select('mobile')
          .eq('id', userId)
          .maybeSingle();
      if (current == null) {
        throw StateError('Profile is not initialized for the current account.');
      }

      final normalized = _normalizeMobile(mobile);
      final previous = _normalizeMobile(
        (current['mobile'] as String?)?.trim() ?? '',
      );
      final changed = previous != normalized;
      payload['mobile'] = normalized.isEmpty ? null : normalized;
      if (changed) payload['mobile_verified_at'] = null;
    }

    final updatedRows = await _client
        .from('users')
        .update(payload)
        .eq('id', userId)
        .select('id');

    if (updatedRows.isEmpty) {
      throw StateError('Account Setup completion did not update the profile.');
    }
  }
}
