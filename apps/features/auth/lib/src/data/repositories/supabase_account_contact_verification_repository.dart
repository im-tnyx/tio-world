import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/repositories/account_contact_verification_repository.dart';

/// Supabase Auth-backed Account contact verification owner.
///
/// The database projects trusted `auth.users` confirmation timestamps into
/// `public.users`; this adapter never writes verification timestamps itself.
/// A successful OTP API call is not enough to claim verification: the returned
/// Supabase Auth user must expose the exact target contact as confirmed.
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
    final normalized = normalizePhoneNumberE164(phoneNumber);
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        phoneNumber,
        'phoneNumber',
        'must be a valid international mobile number',
      );
    }
    return normalized;
  }

  bool _hasConfirmedEmail(User? user, String normalizedEmail) {
    return user?.email?.trim().toLowerCase() == normalizedEmail &&
        user?.emailConfirmedAt != null;
  }

  bool _hasConfirmedPhone(User? user, String normalizedPhone) {
    return user?.phone?.trim() == normalizedPhone &&
        user?.phoneConfirmedAt != null;
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

    final response = await _client.auth.verifyOTP(
      email: normalizedEmail,
      token: normalizedToken,
      type: isEmailChange ? OtpType.emailChange : OtpType.signup,
    );

    // Secure Email Change can require more than one confirmation. Never turn an
    // intermediate successful Auth response into a local Verified badge.
    final authoritativeUser = response.user ?? _client.auth.currentUser;
    if (!_hasConfirmedEmail(authoritativeUser, normalizedEmail)) {
      throw StateError(
        'Supabase Auth has not finished confirming this email yet.',
      );
    }

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

    final response = await _client.auth.verifyOTP(
      phone: normalizedPhone,
      token: normalizedToken,
      type: OtpType.phoneChange,
    );

    final authoritativeUser = response.user ?? _client.auth.currentUser;
    if (!_hasConfirmedPhone(authoritativeUser, normalizedPhone)) {
      throw StateError(
        'Supabase Auth has not finished confirming this phone number yet.',
      );
    }
  }
}
