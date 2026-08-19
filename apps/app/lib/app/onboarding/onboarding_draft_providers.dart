import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

import '../app_mode/app_mode.dart';
import '../network_providers.dart';
import 'auth_aware_onboarding_draft_repository.dart';
import 'google_identity_onboarding_draft_repository.dart';
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

  final authAwareRepository = AuthAwareOnboardingDraftRepository(
    localStore: ref.watch(localOnboardingDraftStoreProvider),
    currentUserId: () => client?.auth.currentUser?.id,
    remoteRepository: remote,
    completionRepository: ref.watch(onboardingCompletionRepositoryProvider),
    userIdChanges: userIdChanges,
  );
  ref.onDispose(authAwareRepository.dispose);

  final identityRepository = GoogleIdentityOnboardingDraftRepository(
    delegate: authAwareRepository,
    selectedMode: () => ref.read(appModeControllerProvider).selectedMode,
    trustedGoogleDisplayName: () =>
        _trustedGoogleDisplayName(client?.auth.currentUser),
  );

  return ResumePreservingOnboardingDraftRepository(
    delegate: identityRepository,
  );
});

String? _trustedGoogleDisplayName(User? user) {
  if (user == null) return null;

  final appMetadata = user.appMetadata;
  final provider = appMetadata['provider'];
  final providers = appMetadata['providers'];
  final isGoogle = provider == 'google' ||
      (providers is Iterable && providers.any((value) => value == 'google'));
  if (!isGoogle) return null;

  final metadata = user.userMetadata ?? const <String, dynamic>{};
  for (final key in const ['full_name', 'name', 'display_name']) {
    final value = metadata[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}
