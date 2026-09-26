import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

import 'auth_providers.dart';
import 'runtime_providers.dart';

final onboardingRemoteFinalizerProvider =
    Provider<OnboardingRemoteFinalizer>((ref) {
  final apiClient = ref.watch(authenticatedApiClientProvider);
  return RemoteOnboardingFinalizer(apiClient);
});

final appOnboardingDraftRepositoryProvider =
    Provider<OnboardingDraftRepository?>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return SupabaseOnboardingDraftRepository(client: supabaseClient);
  }
  return null;
});

/// Builds the Product Onboarding completion gate from the infrastructure that
/// actually owns canonical completion writes.
///
/// Canonical Body, Wellness, Nutrition and Workout owner providers are
/// Supabase-backed only when a Supabase client exists. Their no-Supabase
/// fallbacks are intentionally in-memory and must never qualify as durable
/// finalization. An authenticated Supabase user is separately required before
/// completion can be published.
OnboardingCompletionValidator buildAppOnboardingCompletionValidator({
  required bool hasSupabaseClient,
  required bool hasAuthenticatedSupabaseUser,
}) {
  return OnboardingCompletionValidator(
    hasDurableOwnerPersistence: hasSupabaseClient,
    backendUserReady: hasSupabaseClient && hasAuthenticatedSupabaseUser,
  );
}

final appOnboardingCompletionValidatorProvider =
    Provider<OnboardingCompletionValidator>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return buildAppOnboardingCompletionValidator(
    hasSupabaseClient: supabaseClient != null,
    hasAuthenticatedSupabaseUser: supabaseClient?.auth.currentUser != null,
  );
});
