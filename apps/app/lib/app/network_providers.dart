import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_feature_profile/profile.dart';
import 'package:tio_feature_progress/progress.dart';

import 'composition/auth_providers.dart';
import 'composition/runtime_providers.dart';
import 'profile/canonical_profile_data_reader.dart';

export 'composition/auth_providers.dart';
export 'composition/body_wellness_providers.dart';
export 'composition/hydration_preferences_providers.dart';
export 'composition/onboarding_providers.dart';
export 'composition/nutrition_providers.dart';
export 'composition/runtime_providers.dart';
export 'composition/workout_providers.dart';

/// Canonical common Profile owner used by Supabase production composition.
final userProfileRepositoryProvider = Provider<UserProfileRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseUserProfileRepository(client: client);
});

/// Narrow avatar-only Supabase boundary. It writes only `users.avatar_url` and
/// carries no legacy Profile/Body schema dependency.
final profileAvatarRepositoryProvider =
    Provider<ProfileAvatarRepository?>((ref) {
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

final profileAccountRepositoryProvider =
    Provider<ProfileAccountRepository?>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return SupabaseProfileAccountRepository(client: supabaseClient);
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
