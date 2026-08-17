import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

void main() {
  group('SupabaseOnboardingDraftRepository', () {
    test('instantiates with client', () {
      expect(
        () => SupabaseOnboardingDraftRepository(
          client: FakeSupabaseClient(),
        ),
        returnsNormally,
      );
    });

    test('loadDraft returns null when unauthenticated', () async {
      final repo = SupabaseOnboardingDraftRepository(
        client: FakeSupabaseClient(currentUser: null),
      );

      final result = await repo.loadDraft();
      expect(result, isNull);
    });

    test('saveDraft throws StateError when unauthenticated', () async {
      final repo = SupabaseOnboardingDraftRepository(
        client: FakeSupabaseClient(currentUser: null),
      );

      final snapshot = OnboardingDraftSnapshot(
        draft: OnboardingDraft(),
      );

      expect(
        () => repo.saveDraft(snapshot),
        throwsStateError,
      );
    });

    test('clearDraft completes safely when unauthenticated', () async {
      final repo = SupabaseOnboardingDraftRepository(
        client: FakeSupabaseClient(currentUser: null),
      );

      expect(
        () => repo.clearDraft(),
        returnsNormally,
      );
    });
  });
}

class FakeSupabaseClient extends Fake implements SupabaseClient {
  FakeSupabaseClient({this.currentUser});

  final User? currentUser;

  @override
  GoTrueClient get auth => FakeGoTrueClient(currentUser: currentUser);
}

class FakeGoTrueClient extends Fake implements GoTrueClient {
  FakeGoTrueClient({this.currentUser});

  @override
  final User? currentUser;
}
