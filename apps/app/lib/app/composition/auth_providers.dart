import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_shared/shared.dart';

import 'runtime_providers.dart';

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

final deviceIdentityProviderProvider = Provider<DeviceIdentityProvider>((ref) {
  return FlutterDeviceIdentityProvider();
});

final backendUserSyncRepositoryProvider =
    Provider<BackendUserSyncRepository>((ref) {
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

final signInWithGoogleUseCaseProvider =
    Provider<SignInWithGoogleUseCase?>((ref) {
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

final googleAuthUseCaseProvider = Provider<GoogleAuthUseCase>((ref) {
  return GoogleAuthUseCase(
    googleSignInProvider: ref.watch(googleSignInProviderProvider),
    backendUserSyncRepository: ref.watch(backendUserSyncRepositoryProvider),
    deviceIdentityProvider: ref.watch(deviceIdentityProviderProvider),
  );
});
