import 'package:tio_shared/shared.dart';

/// Contract for remote targets setup data source.
abstract interface class TargetsSetupRemoteDataSource {
  /// Sends targets onboarding draft payload to backend.
  Future<void> saveTargetsSetup(Map<String, dynamic> data);
}

/// HTTP implementation of [TargetsSetupRemoteDataSource] using [ApiClient].
class HttpTargetsSetupRemoteDataSource implements TargetsSetupRemoteDataSource {
  const HttpTargetsSetupRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<void> saveTargetsSetup(Map<String, dynamic> data) async {
    await _apiClient.patch<Map<String, dynamic>>(
      '/api/v1/onboarding/target',
      data: {
        'data': data,
        'isCompleted': true,
      },
    );
  }
}
