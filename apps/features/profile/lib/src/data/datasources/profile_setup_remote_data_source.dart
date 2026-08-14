import 'package:tio_shared/shared.dart';

/// Contract for remote profile setup data source.
abstract interface class ProfileSetupRemoteDataSource {
  /// Sends profile onboarding draft payload to backend.
  Future<void> saveProfileSetup(Map<String, dynamic> data);
}

/// HTTP implementation of [ProfileSetupRemoteDataSource] using [ApiClient].
class HttpProfileSetupRemoteDataSource implements ProfileSetupRemoteDataSource {
  const HttpProfileSetupRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<void> saveProfileSetup(Map<String, dynamic> data) async {
    await _apiClient.patch<Map<String, dynamic>>(
      '/api/v1/onboarding/profile',
      data: {
        'data': data,
        'isCompleted': true,
      },
    );
  }
}
