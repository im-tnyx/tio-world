import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_profile/profile.dart';
import 'package:tio_feature_progress/progress.dart';
import 'package:tio_feature_settings/settings.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

import 'hydration_preferences_session_boundary.dart';
import 'profile/canonical_profile_data_reader.dart';
import 'supabase_runtime_config.dart';

final supabaseConfigProvider = Provider<SupabaseRuntimeConfig>((ref) {
  return SupabaseRuntimeConfig.fromEnvironment();
});

/// Provider for injected or initialized [SupabaseClient].
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  final config = ref.watch(supabaseConfigProvider);
  if (!config.isConfigured) return null;

  try {
    return Supabase.instance.client;
  } catch (_) {
    if (config.isRelease) rethrow;
    return null;
  }
});

/// Provider for global API configuration (base URL and timeouts).
final apiConfigProvider = Provider<ApiConfig>((ref) {
  const baseUrl = String.fromEnvironment(
    'TIO_API_BASE_URL',
    defaultValue: 'https://api.tnyx.app',
  );
  return const ApiConfig(baseUrl: baseUrl);
});

/// Provider for explicit authentication capability status.
final authCapabilityProvider = Provider<AuthCapability>((ref) {
  return const AuthCapabilityUnavailable(
    'Firebase client options are not configured in this environment.',
  );
});

/// Provider for user authentication session management.
final authSessionRepositoryProvider = Provider<AuthSessionRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return SupabaseAuthSessionRepository(client: supabaseClient);
  }
  final capability = ref.watch(authCapabilityProvider);
  if (capability.isAvailable) {
    return FirebaseAuthSessionRepository();
  }
  return InMemoryAuthSessionRepository();
});

/// Provider for retrieving bearer ID tokens for protected HTTP requests.
///
/// The token authority must follow the same runtime provider selection as the
/// session repository: Supabase is the production owner when configured,
/// Firebase remains a compatibility fallback, and otherwise protected calls
/// fail closed through [UnavailableAuthTokenProvider].
final authTokenProvider = Provider<AuthTokenProvider>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return SupabaseAuthTokenProvider(client: supabaseClient);
  }

  final capability = ref.watch(authCapabilityProvider);
  if (capability.isAvailable) {
    return FirebaseAuthTokenProvider();
  }
  return const UnavailableAuthTokenProvider();
});

final authenticatedApiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(apiConfigProvider);
  final tokenProvider = ref.watch(authTokenProvider);
  return DioApiClient.authenticated(
    config: config,
    tokenProvider: tokenProvider,
  );
});

final publicApiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(apiConfigProvider);
  return DioApiClient.public(config: config);
});

/// Canonical common Profile owner used by Supabase production composition.
final userProfileRepositoryProvider = Provider<UserProfileRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseUserProfileRepository(client: client);
});

/// Narrow avatar-only Supabase boundary. It writes only `users.avatar_url` and
/// carries no legacy Profile/Body schema dependency.
final profileAvatarRepositoryProvider = Provider<ProfileAvatarRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseProfileAvatarRepository(client: client);
});

/// Broad ProfileSetup is retained only for the future protected HTTP adapter.
/// Supabase production must use canonical Profile/Body owners and the narrow
/// avatar owner directly; requesting this broad provider in a Supabase session
/// fails closed so legacy schema dependencies cannot be reintroduced.
final profileSetupRepositoryProvider = Provider<ProfileSetupRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client != null) {
    throw StateError(
      'Broad Supabase ProfileSetup access is retired; use canonical Profile/Body and avatar owners.',
    );
  }
  final apiClient = ref.watch(authenticatedApiClientProvider);
  return RemoteProfileSetupRepository(
    remoteDataSource: HttpProfileSetupRemoteDataSource(apiClient),
  );
});

/// Canonical Wellness owner. Production writes only `user_wellness_targets`;
/// an in-memory fallback keeps non-Supabase test/local harnesses constructible.
final wellnessTargetsRepositoryProvider =
    Provider<WellnessTargetsRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return SupabaseWellnessTargetsRepository(client: supabaseClient);
  }
  return InMemoryWellnessTargetsRepository();
});

/// Canonical Wellness read state provider for UI routes.
final wellnessTargetsDataProvider =
    FutureProvider<WellnessTargetsData?>((ref) async {
  final repository = ref.watch(wellnessTargetsRepositoryProvider);
  return repository.read();
});

/// Settings-owned, device-local Default Glass Size preference.
final hydrationPreferencesRepositoryProvider =
    Provider<HydrationPreferencesRepository>(
  (ref) => SharedPreferencesHydrationPreferencesRepository(),
);

final hydrationPreferencesSessionBoundaryProvider =
    Provider<HydrationPreferencesSessionBoundary>(
  (ref) => HydrationPreferencesSessionBoundary(
    ref.watch(hydrationPreferencesRepositoryProvider),
  ),
);

final hydrationPreferencesDataProvider =
    FutureProvider.autoDispose<HydrationPreferences>((ref) async {
  final repository = ref.watch(hydrationPreferencesRepositoryProvider);
  return repository.read();
});

/// Canonical Body owner. The returned object also exposes the canonical
/// Wellness owner boundary so existing onboarding composition can advance O4C
/// without widening router glue. The two owners still delegate to independent
/// repositories/tables.
final bodySetupRepositoryProvider = Provider<BodySetupRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  final BodySetupRepository bodyRepository = supabaseClient != null
      ? SupabaseBodySetupRepository(client: supabaseClient)
      : InMemoryBodySetupRepository();

  return _BodyAndWellnessSetupRepository(
    bodyRepository: bodyRepository,
    wellnessRepository: ref.watch(wellnessTargetsRepositoryProvider),
  );
});

/// Canonical Body owner used by post-onboarding Settings surfaces (Body &
/// Weight, Profile Current Weight). Falls back to an in-memory instance
/// without a Supabase client so non-Supabase test/local harnesses stay
/// constructible.
final bodyRepositoryProvider = Provider<BodyRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return SupabaseBodySetupRepository(client: supabaseClient);
  }
  return InMemoryBodySetupRepository();
});

/// Canonical Body read state provider for UI routes.
final bodyStateDataProvider = FutureProvider<BodyState>((ref) async {
  final repository = ref.watch(bodyRepositoryProvider);
  return repository.getBodyState();
});

final class _BodyAndWellnessSetupRepository
    implements BodySetupRepository, WellnessTargetsRepository {
  const _BodyAndWellnessSetupRepository({
    required BodySetupRepository bodyRepository,
    required WellnessTargetsRepository wellnessRepository,
  })  : _bodyRepository = bodyRepository,
        _wellnessRepository = wellnessRepository;

  final BodySetupRepository _bodyRepository;
  final WellnessTargetsRepository _wellnessRepository;

  @override
  Future<void> saveBodySetup(BodySetupData data) {
    return _bodyRepository.saveBodySetup(data);
  }

  @override
  Future<WellnessTargetsData?> read() {
    return _wellnessRepository.read();
  }

  @override
  Future<void> upsert(WellnessTargetsData targets) {
    return _wellnessRepository.upsert(targets);
  }
}

final profileAccountRepositoryProvider =
    Provider<ProfileAccountRepository?>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return SupabaseProfileAccountRepository(client: supabaseClient);
  }
  return null;
});

/// Canonical Workout Profile owner used by Product Onboarding completion.
final workoutProfileRepositoryProvider =
    Provider<WorkoutProfileRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return SupabaseWorkoutProfileRepository(client: supabaseClient);
  }
  return InMemoryWorkoutProfileRepository();
});

/// Canonical Workout Targets owner used by Product Onboarding completion.
final workoutTargetsRepositoryProvider =
    Provider<WorkoutTargetsRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return SupabaseWorkoutTargetsRepository(client: supabaseClient);
  }
  return InMemoryWorkoutTargetsRepository();
});

/// Canonical Nutrition Profile owner used by Product Onboarding completion.
final nutritionProfileRepositoryProvider =
    Provider<NutritionProfileRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return SupabaseNutritionProfileRepository(client: supabaseClient);
  }
  return InMemoryNutritionProfileRepository();
});

/// Canonical Nutrition Profile read model for post-onboarding Settings.
///
/// A missing canonical row resolves to an all-null profile so first-time
/// editing works without a separate setup workflow.
final nutritionProfileDataProvider =
    FutureProvider<NutritionProfileData>((ref) async {
  final repository = ref.watch(nutritionProfileRepositoryProvider);
  return await repository.read() ?? const NutritionProfileData();
});

/// Canonical Nutrition Targets owner used by Product Onboarding completion.
final nutritionTargetsRepositoryProvider =
    Provider<NutritionTargetsRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return SupabaseNutritionTargetsRepository(client: supabaseClient);
  }
  return InMemoryNutritionTargetsRepository();
});

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
    backendUserReady:
        hasSupabaseClient && hasAuthenticatedSupabaseUser,
  );
}

final appOnboardingCompletionValidatorProvider =
    Provider<OnboardingCompletionValidator>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return buildAppOnboardingCompletionValidator(
    hasSupabaseClient: supabaseClient != null,
    hasAuthenticatedSupabaseUser:
        supabaseClient?.auth.currentUser != null,
  );
});

final deviceIdentityProviderProvider = Provider<DeviceIdentityProvider>((ref) {
  return FlutterDeviceIdentityProvider();
});

final backendUserSyncRepositoryProvider = Provider<BackendUserSyncRepository>((ref) {
  final apiClient = ref.watch(publicApiClientProvider);
  return RemoteBackendUserSyncRepository(
    remoteDataSource: BackendUserSyncRemoteDataSource(apiClient),
  );
});

final googleSignInProviderProvider = Provider<GoogleSignInProvider>((ref) {
  return GoogleSignInProvider();
});

final backendUserStateProvider = StateProvider<BackendUserState>((ref) {
  return const BackendUserUnknown();
});

final authSessionStateProvider = StreamProvider<AuthSessionState>((ref) {
  final repo = ref.watch(authSessionRepositoryProvider);
  return repo.sessionState;
});

final authProductStateProvider = Provider<AuthProductState>((ref) {
  final capability = ref.watch(authCapabilityProvider);
  final sessionAsync = ref.watch(authSessionStateProvider);
  final session = sessionAsync.valueOrNull ?? const AuthSessionUnknown();
  final backendUser = ref.watch(backendUserStateProvider);
  return AuthProductState(
    capability: capability,
    sessionState: session,
    backendUserState: backendUser,
  );
});

final userDeviceRepositoryProvider = Provider<UserDeviceRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return SupabaseUserDeviceRepository(
      client: supabaseClient,
      deviceIdentityProvider: ref.watch(deviceIdentityProviderProvider),
    );
  }
  return const NoOpUserDeviceRepository();
});

final authSignInRepositoryProvider = Provider<AuthSignInRepository?>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return SupabaseAuthSignInRepository(
      client: supabaseClient,
      googleSignIn: ref.watch(googleSignInProviderProvider).signInClient,
      userDeviceRepository: ref.watch(userDeviceRepositoryProvider),
    );
  }
  return null;
});

final signInWithGoogleUseCaseProvider = Provider<SignInWithGoogleUseCase?>((ref) {
  final repo = ref.watch(authSignInRepositoryProvider);
  if (repo != null) {
    return SignInWithGoogleUseCase(signInRepository: repo);
  }
  return null;
});

final signInWithEmailUseCaseProvider = Provider<SignInWithEmailUseCase?>((ref) {
  final repo = ref.watch(authSignInRepositoryProvider);
  if (repo != null) {
    return SignInWithEmailUseCase(signInRepository: repo);
  }
  return null;
});

final signUpWithEmailUseCaseProvider = Provider<SignUpWithEmailUseCase?>((ref) {
  final repo = ref.watch(authSignInRepositoryProvider);
  if (repo != null) {
    return SignUpWithEmailUseCase(signInRepository: repo);
  }
  return null;
});

final sendPasswordResetEmailUseCaseProvider =
    Provider<SendPasswordResetEmailUseCase?>((ref) {
  final repo = ref.watch(authSignInRepositoryProvider);
  if (repo != null) {
    return SendPasswordResetEmailUseCase(signInRepository: repo);
  }
  return null;
});

/// Live Profile display data.
///
/// Supabase-backed production sessions compose this DTO strictly from the
/// canonical Profile and Body owners plus account-only fields in `users`.
/// Legacy `users` Profile/Body mirrors are not read on this path.
final profileDataProvider = StreamProvider<ProfileSetupData?>((ref) {
  ref.watch(authSessionStateProvider);
  final client = ref.watch(supabaseClientProvider);
  if (client != null) {
    final profileRepository = ref.watch(userProfileRepositoryProvider);
    if (profileRepository == null) {
      return Stream<ProfileSetupData?>.error(
        StateError('Canonical Profile repository is unavailable.'),
      );
    }
    final reader = CanonicalProfileDataReader(
      profileRepository: profileRepository,
      bodyRepository: SupabaseBodySetupRepository(client: client),
      accountReader: SupabaseProfileAccountSnapshotReader(client: client),
    );
    return CanonicalSupabaseProfileDataStream(
      client: client,
      reader: reader,
    ).watch();
  }

  final repository = ref.watch(profileSetupRepositoryProvider);
  return repository.watchProfileSetup();
});

final googleAuthUseCaseProvider = Provider<GoogleAuthUseCase>((ref) {
  return GoogleAuthUseCase(
    googleSignInProvider: ref.watch(googleSignInProviderProvider),
    backendUserSyncRepository: ref.watch(backendUserSyncRepositoryProvider),
    deviceIdentityProvider: ref.watch(deviceIdentityProviderProvider),
  );
});
