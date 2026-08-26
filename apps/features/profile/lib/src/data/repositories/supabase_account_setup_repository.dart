import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_shared/shared.dart';

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
      // Completion is the durable Account Setup acknowledgement. Trusted Auth
      // contact evidence is planned separately by the Account Setup flow.
      isCompleted: row['account_setup_completed_at'] != null,
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

      final normalized = normalizePhoneNumberE164(mobile);
      final previous = normalizePhoneNumberE164(
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
