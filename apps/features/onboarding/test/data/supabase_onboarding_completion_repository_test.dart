import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

void main() {
  group('SupabaseOnboardingCompletionRepository', () {
    test('instantiates with client', () {
      expect(
        () => SupabaseOnboardingCompletionRepository(
          client: _FakeSupabaseClient(),
        ),
        returnsNormally,
      );
    });

    test('readCurrent throws when unauthenticated', () async {
      final repository = SupabaseOnboardingCompletionRepository(
        client: _FakeSupabaseClient(),
      );

      await expectLater(
        repository.readCurrent,
        throwsStateError,
      );
    });

    test('markCurrentCompleted throws when unauthenticated', () async {
      final repository = SupabaseOnboardingCompletionRepository(
        client: _FakeSupabaseClient(),
      );

      await expectLater(
        repository.markCurrentCompleted,
        throwsStateError,
      );
    });
  });
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {
  @override
  GoTrueClient get auth => _FakeGoTrueClient();
}

class _FakeGoTrueClient extends Fake implements GoTrueClient {
  @override
  User? get currentUser => null;
}
