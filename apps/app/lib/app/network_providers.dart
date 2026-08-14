import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_profile/profile.dart';
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
/// Defaults to [AuthCapabilityUnavailable] until live Firebase credentials/options are provided.
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
/// Defaults to [UnavailableAuthTokenProvider] while Firebase client config is pending.
final authTokenProvider = Provider<AuthTokenProvider>((ref) {
  final capability = ref.watch(authCapabilityProvider);
  if (capability.isAvailable) {
    return FirebaseAuthTokenProvider();
  }
  return const UnavailableAuthTokenProvider();
});

/// Provider for the authenticated API client attaching Firebase Bearer ID tokens.
final authenticatedApiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(apiConfigProvider);
  final tokenProvider = ref.watch(authTokenProvider);
  return DioApiClient.authenticated(
    config: config,
    tokenProvider: tokenProvider,
  );
});

/// Provider for public, unauthenticated API calls (signup, login, ping).
final publicApiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(apiConfigProvider);
  return DioApiClient.public(config: config);
});

/// Provider for the [ProfileSetupRepository].
/// Uses Supabase when configured, otherwise falls back to remote HTTP adapter.
final profileSetupRepositoryProvider = Provider<ProfileSetupRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return SupabaseProfileSetupRepository(client: supabaseClient);
  }
  final apiClient = ref.watch(authenticatedApiClientProvider);
  return RemoteProfileSetupRepository(
    remoteDataSource: HttpProfileSetupRemoteDataSource(apiClient),
  );
});

/// Provider for the [WorkoutPreferencesRepository].
/// Uses Supabase when configured, otherwise falls back to remote HTTP adapter.
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

/// Provider for the [TargetsSetupRepository].
/// Uses Supabase when configured, otherwise falls back to remote HTTP adapter.
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

/// Provider for the remote [OnboardingRemoteFinalizer].
final onboardingRemoteFinalizerProvider =
    Provider<OnboardingRemoteFinalizer>((ref) {
  final apiClient = ref.watch(authenticatedApiClientProvider);
  return RemoteOnboardingFinalizer(apiClient);
});

/// Provider for the [OnboardingDraftRepository].
/// Uses Supabase when configured, otherwise returns null.
final appOnboardingDraftRepositoryProvider =
    Provider<OnboardingDraftRepository?>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return SupabaseOnboardingDraftRepository(client: supabaseClient);
  }
  return null;
});

/// Provider for [OnboardingCompletionValidator] with live persistence state.
final appOnboardingCompletionValidatorProvider =
    Provider<OnboardingCompletionValidator>((ref) {
  final authProductState = ref.watch(authProductStateProvider);
  final supabaseClient = ref.watch(supabaseClientProvider);
  final isSupabaseReady =
      supabaseClient != null && supabaseClient.auth.currentUser != null;
  final isDurablePersistenceReady =
      isSupabaseReady || authProductState.isReadyForProtectedBackendCalls;
  final hasDurableStorage =
      supabaseClient != null || authProductState.capability.isAvailable;

  return OnboardingCompletionValidator(
    hasDurableOwnerPersistence: hasDurableStorage,
    backendUserReady: isDurablePersistenceReady,
  );
});

/// Provider for device identity.
final deviceIdentityProviderProvider = Provider<DeviceIdentityProvider>((ref) {
  return FlutterDeviceIdentityProvider();
});

/// Provider for synchronizing user to backend.
final backendUserSyncRepositoryProvider = Provider<BackendUserSyncRepository>((ref) {
  final apiClient = ref.watch(publicApiClientProvider);
  return RemoteBackendUserSyncRepository(
    remoteDataSource: BackendUserSyncRemoteDataSource(apiClient),
  );
});

/// Provider for Google Sign-In SDK.
final googleSignInProviderProvider = Provider<GoogleSignInProvider>((ref) {
  return GoogleSignInProvider();
});

/// State provider for tracking backend user sync state.
final backendUserStateProvider = StateProvider<BackendUserState>((ref) {
  return const BackendUserUnknown();
});

/// Stream provider for auth session state.
final authSessionStateProvider = StreamProvider<AuthSessionState>((ref) {
  final repo = ref.watch(authSessionRepositoryProvider);
  return repo.sessionState;
});

/// Composite auth readiness provider.
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

/// Provider for auth sign-in repository.
/// Uses Supabase in current production path.
final authSignInRepositoryProvider = Provider<AuthSignInRepository?>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return SupabaseAuthSignInRepository(
      client: supabaseClient,
      googleSignIn: ref.watch(googleSignInProviderProvider).signInClient,
    );
  }
  return null;
});


/// Provider for current Supabase Google sign-in use case.
final signInWithGoogleUseCaseProvider = Provider<SignInWithGoogleUseCase?>((ref) {
  final repo = ref.watch(authSignInRepositoryProvider);
  if (repo != null) {
    return SignInWithGoogleUseCase(signInRepository: repo);
  }
  return null;
});

/// Provider for email + password sign-in use case.
final signInWithEmailUseCaseProvider = Provider<SignInWithEmailUseCase?>((ref) {
  final repo = ref.watch(authSignInRepositoryProvider);
  if (repo != null) {
    return SignInWithEmailUseCase(signInRepository: repo);
  }
  return null;
});

/// Provider for email + password sign-up use case.
final signUpWithEmailUseCaseProvider = Provider<SignUpWithEmailUseCase?>((ref) {
  final repo = ref.watch(authSignInRepositoryProvider);
  if (repo != null) {
    return SignUpWithEmailUseCase(signInRepository: repo);
  }
  return null;
});

/// Provider for sending password reset emails.
final sendPasswordResetEmailUseCaseProvider =
    Provider<SendPasswordResetEmailUseCase?>((ref) {
  final repo = ref.watch(authSignInRepositoryProvider);
  if (repo != null) {
    return SendPasswordResetEmailUseCase(signInRepository: repo);
  }
  return null;
});

/// Provider for fetching the current user's profile setup data.
final profileDataProvider = FutureProvider<ProfileSetupData?>((ref) async {
  final repository = ref.watch(profileSetupRepositoryProvider);
  return repository.getProfileSetup();
});


/// Provider for future Firebase+backend Google authentication use case.
final googleAuthUseCaseProvider = Provider<GoogleAuthUseCase>((ref) {
  return GoogleAuthUseCase(
    googleSignInProvider: ref.watch(googleSignInProviderProvider),
    backendUserSyncRepository: ref.watch(backendUserSyncRepositoryProvider),
    deviceIdentityProvider: ref.watch(deviceIdentityProviderProvider),
  );
});
