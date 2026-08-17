import 'package:tio_shared/shared.dart';

/// Contract for remote workout preferences setup data source.
abstract interface class WorkoutPreferencesRemoteDataSource {
  /// Sends workout onboarding draft payload to backend.
  Future<void> saveWorkoutPreferences(Map<String, dynamic> data);
}

/// HTTP implementation of [WorkoutPreferencesRemoteDataSource] using [ApiClient].
class HttpWorkoutPreferencesRemoteDataSource
    implements WorkoutPreferencesRemoteDataSource {
  const HttpWorkoutPreferencesRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<void> saveWorkoutPreferences(Map<String, dynamic> data) async {
    await _apiClient.patch<Map<String, dynamic>>(
      '/api/v1/onboarding/workout',
      data: {
        'data': data,
        'isCompleted': true,
      },
    );
  }
}
