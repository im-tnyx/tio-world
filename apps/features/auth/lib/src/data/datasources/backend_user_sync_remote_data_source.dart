import 'package:tio_shared/shared.dart';
import '../dto/google_sync_request_dto.dart';
import '../dto/backend_user_sync_response_dto.dart';

/// Remote data source for backend user sync endpoints.
/// Uses [ApiClient] (publicApiClient — Firebase token is the identity proof).
class BackendUserSyncRemoteDataSource {
  const BackendUserSyncRemoteDataSource(this._client);

  final ApiClient _client;

  /// POST /api/v1/auth/google-sync
  /// Firebase ID token is sent both as Authorization header and in body.
  Future<BackendUserSyncResponseDto> syncGoogleUser(
    GoogleSyncRequestDto dto,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/api/v1/auth/google-sync',
      data: dto.toJson(),
      options: Options(
        headers: {'Authorization': 'Bearer ${dto.firebaseIdToken}'},
      ),
    );
    return BackendUserSyncResponseDto.fromJson(response.data!);
  }
}
