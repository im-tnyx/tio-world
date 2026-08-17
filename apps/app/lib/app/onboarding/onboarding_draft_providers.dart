import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

import '../network_providers.dart';
import 'auth_aware_onboarding_draft_repository.dart';
import 'onboarding_completion_providers.dart';

final localOnboardingDraftStoreProvider =
    Provider<LocalOnboardingDraftStore>((ref) {
  return SecureLocalOnboardingDraftStore();
});

/// Production onboarding draft repository.
///
/// Signed-out onboarding remains device-local only. Once Supabase authentication
/// establishes ownership, durable completion is checked before any local handoff
/// is migrated. Completed accounts reject and clean transient onboarding drafts;
/// incomplete accounts may migrate the matching local resume state.
final hybridOnboardingDraftRepositoryProvider =
    Provider<OnboardingDraftRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final remote = switch (client) {
    null => null,
    final value => SupabaseOnboardingDraftRepository(client: value),
  };
  final userIdChanges = switch (client) {
    null => null,
    final value => value.auth.onAuthStateChange.map((state) {
        return state.session?.user.id ?? value.auth.currentUser?.id;
      }).distinct(),
  };

  final repository = AuthAwareOnboardingDraftRepository(
    localStore: ref.watch(localOnboardingDraftStoreProvider),
    currentUserId: () => client?.auth.currentUser?.id,
    remoteRepository: remote,
    completionRepository: ref.watch(onboardingCompletionRepositoryProvider),
    userIdChanges: userIdChanges,
  );
  ref.onDispose(repository.dispose);
  return repository;
});
