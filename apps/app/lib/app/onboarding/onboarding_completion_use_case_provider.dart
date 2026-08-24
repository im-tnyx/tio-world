import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

import '../app_mode/app_mode.dart';
import '../network_providers.dart';
import 'onboarding_completion_providers.dart';

typedef CompleteOnboardingUseCaseFactory = CompleteOnboardingUseCase? Function();

/// Builds a fresh completion use case at the moment Product Onboarding
/// finalizes so auth/session readiness is evaluated after any signup handoff.
final appCompleteOnboardingUseCaseFactoryProvider =
    Provider<CompleteOnboardingUseCaseFactory>((ref) {
  return () {
    final supabaseClient = ref.read(supabaseClientProvider);
    final canonicalProfileRepository = ref.read(userProfileRepositoryProvider);
    final Object? profileRepository = canonicalProfileRepository ??
        (supabaseClient == null
            ? ref.read(profileSetupRepositoryProvider)
            : null);
    final onboardingDraftRepository =
        ref.read(appOnboardingDraftRepositoryProvider);
    final onboardingCompletionRepository =
        ref.read(onboardingCompletionRepositoryProvider);
    final appPreferencesRepository = ref.read(appPreferencesRepositoryProvider);

    if (profileRepository == null ||
        onboardingDraftRepository == null ||
        onboardingCompletionRepository == null ||
        appPreferencesRepository == null) {
      return null;
    }

    final hasAuthenticatedSupabaseUser =
        supabaseClient?.auth.currentUser != null;

    return CompleteOnboardingUseCase(
      confirmedModePreference: _AppModeControllerPreferenceAdapter(
        ref.read(appModeControllerProvider),
      ),
      appPreferencesRepository: appPreferencesRepository,
      statusRepository: ref.read(onboardingStatusRepositoryProvider),
      completionRepository: onboardingCompletionRepository,
      draftRepository: onboardingDraftRepository,
      persistOwnerDataUseCase: PersistOnboardingOwnerDataUseCase(
        profileRepository: profileRepository,
        bodyRepository: ref.read(bodySetupRepositoryProvider),
        nutritionProfileRepository:
            ref.read(nutritionProfileRepositoryProvider),
        workoutProfileRepository: ref.read(workoutProfileRepositoryProvider),
        workoutTargetsRepository: ref.read(workoutTargetsRepositoryProvider),
        nutritionTargetsRepository: ref.read(nutritionTargetsRepositoryProvider),
      ),
      validator: buildAppOnboardingCompletionValidator(
        hasSupabaseClient: supabaseClient != null,
        hasAuthenticatedSupabaseUser: hasAuthenticatedSupabaseUser,
      ),
    );
  };
});

class _AppModeControllerPreferenceAdapter implements AppModePreference {
  _AppModeControllerPreferenceAdapter(this._controller);

  final AppModeController _controller;

  @override
  Future<void> clear() => _controller.clear();

  @override
  Future<AppMode?> read() async => _controller.selectedMode;

  @override
  Future<void> write(AppMode mode) => _controller.select(mode);
}
