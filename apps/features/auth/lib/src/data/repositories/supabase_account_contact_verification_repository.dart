import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/account_contact_verification_repository.dart';

/// Supabase Auth-backed Account contact verification owner.
///
/// The database projects trusted `auth.users` confirmation timestamps into
/// `public.users`; this adapter never writes verification timestamps itself.
final class SupabaseAccountContactVerificationRepository
    implements AccountContactVerificationRepository {
  SupabaseAccountContactVerificationRepository({
    required SupabaseClient client,
  }) : _client = client;

  final SupabaseClient _client;
  String? _pendingEmailChange;

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null || user.id.isEmpty) {
      throw StateError('Please sign in to verify account contact details.');
    }
    return user;
  }

  String _normalizeEmail(String email) {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) {
      throw ArgumentError.value(email, 'email', 'must be a valid email');
    }
    return normalized;
  }

  String _normalizePhone(String phoneNumber) {
    final trimmed = phoneNumber.trim();
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length == 10) return '+91$digits';
    if (digits.length == 12 && digits.startsWith('91')) return '+$digits';
    if (trimmed.startsWith('+') && digits.length >= 8 && digits.length <= 15) {
      return '+$digits';
    }

    throw ArgumentError.value(
      phoneNumber,
      'phoneNumber',
      'must be a valid international mobile number',
    );
  }

  @override
  Future<void> requestEmailVerification(String email) async {
    final user = _requireUser();
    final normalizedEmail = _normalizeEmail(email);
    final currentEmail = user.email?.trim().toLowerCase();

    if (currentEmail == normalizedEmail) {
      _pendingEmailChange = null;
      if (user.emailConfirmedAt != null) return;
      await _client.auth.resend(
        type: OtpType.signup,
        email: normalizedEmail,
      );
      return;
    }

    await _client.auth.updateUser(
      UserAttributes(email: normalizedEmail),
    );
    _pendingEmailChange = normalizedEmail;
  }

  @override
  Future<void> verifyEmail({
    required String email,
    required String token,
  }) async {
    final user = _requireUser();
    final normalizedEmail = _normalizeEmail(email);
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      throw ArgumentError.value(token, 'token', 'must not be empty');
    }

    final currentEmail = user.email?.trim().toLowerCase();
    final isEmailChange = _pendingEmailChange == normalizedEmail ||
        (currentEmail != null && currentEmail != normalizedEmail) ||
        currentEmail == null;

    await _client.auth.verifyOTP(
      email: normalizedEmail,
      token: normalizedToken,
      type: isEmailChange ? OtpType.emailChange : OtpType.signup,
    );
    if (_pendingEmailChange == normalizedEmail) {
      _pendingEmailChange = null;
    }
  }

  @override
  Future<void> requestCurrentEmailVerification(String email) {
    return requestEmailVerification(email);
  }

  @override
  Future<void> verifyCurrentEmail({
    required String email,
    required String token,
  }) {
    return verifyEmail(email: email, token: token);
  }

  @override
  Future<void> requestPhoneVerification(String phoneNumber) async {
    _requireUser();
    final normalizedPhone = _normalizePhone(phoneNumber);

    await _client.auth.updateUser(
      UserAttributes(phone: normalizedPhone),
    );
  }

  @override
  Future<void> verifyPhoneChange({
    required String phoneNumber,
    required String token,
  }) async {
    _requireUser();
    final normalizedPhone = _normalizePhone(phoneNumber);
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      throw ArgumentError.value(token, 'token', 'must not be empty');
    }

    await _client.auth.verifyOTP(
      phone: normalizedPhone,
      token: normalizedToken,
      type: OtpType.phoneChange,
    );
  }
}
