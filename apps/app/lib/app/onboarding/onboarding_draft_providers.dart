import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

import '../network_providers.dart';
import 'auth_aware_onboarding_draft_repository.dart';

final localOnboardingDraftStoreProvider =
    Provider<LocalOnboardingDraftStore>((ref) {
  return SecureLocalOnboardingDraftStore();
});

/// Production onboarding draft repository.
///
/// Signed-out onboarding remains device-local only. Once Supabase authentication
/// establishes ownership, an eligible local draft is migrated to the matching
/// user-scoped remote draft and the local copy is cleared.
final hybridOnboardingDraftRepositoryProvider =
    Provider<OnboardingDraftRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final remote = client == null
      ? null
      : SupabaseOnboardingDraftRepository(client: client);
  final userIdChanges = client == null
      ? null
      : client.auth.onAuthStateChange.map((state) {
          return state.session?.user.id ?? client.auth.currentUser?.id;
        }).distinct();

  final repository = AuthAwareOnboardingDraftRepository(
    localStore: ref.watch(localOnboardingDraftStoreProvider),
    currentUserId: () => client?.auth.currentUser?.id,
    remoteRepository: remote,
    userIdChanges: userIdChanges,
  );
  ref.onDispose(repository.dispose);
  return repository;
});
