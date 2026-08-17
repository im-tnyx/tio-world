import 'package:supabase_flutter/supabase_flutter.dart';

enum GoogleLoginAdmissionDecision {
  existingAccount,
  noAccount,
}

typedef GoogleLoginAdmissionChecker =
    Future<GoogleLoginAdmissionDecision> Function(String idToken);

/// Checks whether the verified Google identity is already attached to a real
/// Tio account before returning-user Login is allowed to create a Supabase
/// session.
///
/// The Edge Function receives only the Google ID token. It derives the identity
/// server-side after verification, so the client cannot probe arbitrary emails.
class SupabaseGoogleLoginAdmissionChecker {
  const SupabaseGoogleLoginAdmissionChecker({
    required SupabaseClient client,
  }) : _client = client;

  final SupabaseClient _client;

  Future<GoogleLoginAdmissionDecision> call(String idToken) async {
    final response = await _client.functions.invoke(
      'google-login-admission',
      body: {'id_token': idToken},
    );

    final data = response.data;
    if (data is! Map) {
      throw const FormatException('Invalid Google login admission response.');
    }

    final allowed = data['allowed'];
    if (allowed is! bool) {
      throw const FormatException(
        'Google login admission response is missing an allowed decision.',
      );
    }

    return allowed
        ? GoogleLoginAdmissionDecision.existingAccount
        : GoogleLoginAdmissionDecision.noAccount;
  }
}
