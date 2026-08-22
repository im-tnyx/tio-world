import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

import '../app_mode/app_mode.dart';
import '../network_providers.dart';

/// Durable backend onboarding completion repository for the current auth user.
///
/// During O1C the app composition returns one object implementing both the
/// onboarding-completion and canonical App Preferences contracts. This keeps
/// the onboarding domain backend-neutral while preserving the existing router
/// call-site until bootstrap/Settings cutovers are handled in O1D/O1E.
final onboardingCompletionRepositoryProvider =
    Provider<OnboardingCompletionRepository?>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient == null) {
    return null;
  }

  final appPreferencesRepository =
      ref.watch(appPreferencesRepositoryProvider);
  if (appPreferencesRepository == null) {
    return null;
  }

  return _OnboardingCompletionWithAppPreferences(
    completionRepository:
        SupabaseOnboardingCompletionRepository(client: supabaseClient),
    appPreferencesRepository: appPreferencesRepository,
  );
});

final class _OnboardingCompletionWithAppPreferences
    implements OnboardingCompletionRepository, AppPreferencesRepository {
  const _OnboardingCompletionWithAppPreferences({
    required OnboardingCompletionRepository completionRepository,
    required AppPreferencesRepository appPreferencesRepository,
  })  : _completionRepository = completionRepository,
        _appPreferencesRepository = appPreferencesRepository;

  final OnboardingCompletionRepository _completionRepository;
  final AppPreferencesRepository _appPreferencesRepository;

  @override
  Future<RemoteOnboardingCompletionState> readCurrent() {
    return _completionRepository.readCurrent();
  }

  @override
  Future<void> markCurrentCompleted() {
    return _completionRepository.markCurrentCompleted();
  }

  @override
  Future<AppPreferencesState> read() {
    return _appPreferencesRepository.read();
  }

  @override
  Future<void> upsert(AppPreferencesUpdate preferences) {
    return _appPreferencesRepository.upsert(preferences);
  }
}
