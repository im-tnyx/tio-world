import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  group('SupabaseProfileAccountRepository', () {
    test('updateAccountSettings requires an authenticated user', () async {
      final auth = _FakeGoTrueClient();
      final repository = SupabaseProfileAccountRepository(
        client: _FakeSupabaseClient(auth: auth),
      );

      expect(
        () => repository.updateAccountSettings(
          username: 'santosh',
          mobile: '+910000000000',
        ),
        throwsStateError,
      );
      expect(auth.anonymousSignInCalls, 0);
    });
  });
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {
  _FakeSupabaseClient({required this.auth});

  @override
  final GoTrueClient auth;
}

class _FakeGoTrueClient extends Fake implements GoTrueClient {
  int anonymousSignInCalls = 0;

  @override
  User? get currentUser => null;

  @override
  Future<AuthResponse> signInAnonymously({
    Map<String, dynamic>? data,
    String? captchaToken,
  }) async {
    anonymousSignInCalls++;
    throw StateError('anonymous sign-in must not be used');
  }
}
