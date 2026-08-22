import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_profile/profile.dart';
import 'package:tio_feature_progress/progress.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

/// Configuration for client-safe Supabase credentials.
class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.anonKey});
  final String url;
  final String anonKey;
  bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}

final supabaseConfigProvider = Provider<SupabaseConfig>((ref) {
  const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://oykupyiitspujzpwwvuj.supabase.co',
  );
  const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_pVet6gRi6JRZ-dyxrZtDSg_MAZa9mfq',
  );
  return const SupabaseConfig(url: url, anonKey: anonKey);
});

/// Provider for injected or initialized [SupabaseClient].
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  final config = ref.watch(supabaseConfigProvider);
  if (config.isConfigured) {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
  return null;
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
final authTokenProvider = Provider<AuthTokenProvider>((ref) {
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

final profileSetupRepositoryProvider = Provider<ProfileSetupRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return CanonicalUserProfileBridgeRepository(
      legacyRepository: SupabaseProfileSetupRepository(client: supabaseClient),
      canonicalRepository: SupabaseUserProfileRepository(client: supabaseClient),
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

/// Legacy broad Workout repository retained for compatibility consumers only.
/// Product Onboarding completion uses the canonical providers below.
final workoutPreferencesRepositoryProvider =
    Provider<WorkoutPreferencesRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return SupabaseWorkoutPreferencesRepository(client: supabaseClient);
  }
  final apiClient = ref.watch(authenticatedApiClientProvider);
  return RemoteWorkoutPreferencesRepository(
    remoteDataSource: HttpWorkoutPreferencesRemoteDataSource(apiClient),
  );
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

/// Canonical Nutrition Targets owner used by Product Onboarding completion.
final nutritionTargetsRepositoryProvider =
    Provider<NutritionTargetsRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return SupabaseNutritionTargetsRepository(client: supabaseClient);
  }
  return InMemoryNutritionTargetsRepository();
});

/// Legacy mixed Targets repository retained for compatibility consumers only.
/// Product Onboarding completion must use the two canonical providers above.
final targetsSetupRepositoryProvider = Provider<TargetsSetupRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return SupabaseTargetsSetupRepository(client: supabaseClient);
  }
  final apiClient = ref.watch(authenticatedApiClientProvider);
  return RemoteTargetsSetupRepository(
    remoteDataSource: HttpTargetsSetupRemoteDataSource(apiClient),
  );
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

final appOnboardingCompletionValidatorProvider =
    Provider<OnboardingCompletionValidator>((ref) {
  final authProductState = ref.watch(authProductStateProvider);
  final supabaseClient = ref.watch(supabaseClientProvider);
  final isSupabaseReady =
      supabaseClient != null && supabaseClient.auth.currentUser != null;
  final isDurablePersistenceReady = isSupabaseReady ||
      authProductState.isReadyForProtectedBackendCalls ||
      authProductState.isAuthUnavailable ||
      supabaseClient == null;

  return OnboardingCompletionValidator(
    hasDurableOwnerPersistence: true,
    backendUserReady: isDurablePersistenceReady,
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

final profileDataProvider = StreamProvider<ProfileSetupData?>((ref) {
  ref.watch(authSessionStateProvider);
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
