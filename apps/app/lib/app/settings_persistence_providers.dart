import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_profile/profile.dart';

import 'network_providers.dart';

final measurementUnitPreferencesRepositoryProvider =
    Provider<MeasurementUnitPreferencesRepository?>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return SupabaseMeasurementUnitPreferencesRepository(client: supabaseClient);
  }

  final fallbackProfileRepository = ref.watch(profileSetupRepositoryProvider);
  if (fallbackProfileRepository is MeasurementUnitPreferencesRepository) {
    return fallbackProfileRepository as MeasurementUnitPreferencesRepository;
  }
  return null;
});

final accountContactVerificationRepositoryProvider =
    Provider<AccountContactVerificationRepository?>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient == null) return null;
  return SupabaseAccountContactVerificationRepository(client: supabaseClient);
});

final accountDeletionRepositoryProvider =
    Provider<AccountDeletionRepository?>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient == null) return null;
  return SupabaseAccountDeletionRepository(client: supabaseClient);
});

final deleteCurrentAccountUseCaseProvider =
    Provider<DeleteCurrentAccountUseCase?>((ref) {
  final repository = ref.watch(accountDeletionRepositoryProvider);
  if (repository == null) return null;
  return DeleteCurrentAccountUseCase(repository: repository);
});
