import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

import '../network_providers.dart';

/// Durable backend onboarding completion repository for the current auth user.
final onboardingCompletionRepositoryProvider =
    Provider<OnboardingCompletionRepository?>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient == null) {
    return null;
  }
  return SupabaseOnboardingCompletionRepository(client: supabaseClient);
});
