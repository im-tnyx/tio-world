import 'package:tio_shared/shared.dart';

import '../domain/repositories/onboarding_remote_finalizer.dart';

/// HTTP implementation of [OnboardingRemoteFinalizer] using [ApiClient].
class RemoteOnboardingFinalizer implements OnboardingRemoteFinalizer {
  const RemoteOnboardingFinalizer(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<void> finalize() async {
    await _apiClient.post<Map<String, dynamic>>(
      '/api/v1/onboarding/finalize',
    );
  }
}
