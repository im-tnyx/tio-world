import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_feature_auth/auth.dart';

import 'network_providers.dart';

final phoneOtpAuthRepositoryProvider = Provider<PhoneOtpAuthRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;

  return SupabasePhoneOtpAuthRepository(
    client: client,
    userDeviceRepository: ref.watch(userDeviceRepositoryProvider),
  );
});

final requestPhoneOtpUseCaseProvider = Provider<RequestPhoneOtpUseCase?>((ref) {
  final repository = ref.watch(phoneOtpAuthRepositoryProvider);
  return repository == null
      ? null
      : RequestPhoneOtpUseCase(repository: repository);
});

final resendPhoneOtpUseCaseProvider = Provider<ResendPhoneOtpUseCase?>((ref) {
  final repository = ref.watch(phoneOtpAuthRepositoryProvider);
  return repository == null
      ? null
      : ResendPhoneOtpUseCase(repository: repository);
});

final verifyPhoneOtpUseCaseProvider = Provider<VerifyPhoneOtpUseCase?>((ref) {
  final repository = ref.watch(phoneOtpAuthRepositoryProvider);
  return repository == null
      ? null
      : VerifyPhoneOtpUseCase(repository: repository);
});
