import 'package:supabase_flutter/supabase_flutter.dart';

enum GoogleLoginAdmissionDecision {
  linkedAccount,
  noAccount,
  linkRequired,
  identityConflict,
}

typedef GoogleLoginAdmissionChecker =
    Future<GoogleLoginAdmissionDecision> Function(String idToken);

/// Resolves a verified Google identity against Tio's canonical verified Email
/// owner and the stable Google provider subject before Supabase Auth exchange.
///
/// The Edge Function receives only the Google ID token. It verifies and derives
/// the Email + provider subject server-side, so the client cannot probe arbitrary
/// Emails or choose an account UUID.
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

    return switch (data['decision']) {
      'linked_account' => GoogleLoginAdmissionDecision.linkedAccount,
      'no_account' => GoogleLoginAdmissionDecision.noAccount,
      'link_required' => GoogleLoginAdmissionDecision.linkRequired,
      'identity_conflict' => GoogleLoginAdmissionDecision.identityConflict,
      _ => throw const FormatException(
          'Google login admission response is missing a valid decision.',
        ),
    };
  }
}
