import 'package:tio_shared/shared.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/models/backend_user_state.dart';
import '../../domain/repositories/backend_user_sync_repository.dart';
import '../datasources/backend_user_sync_remote_data_source.dart';
import '../dto/google_sync_request_dto.dart';

/// Concrete [BackendUserSyncRepository] using the public API client.
class RemoteBackendUserSyncRepository implements BackendUserSyncRepository {
  const RemoteBackendUserSyncRepository({
    required BackendUserSyncRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final BackendUserSyncRemoteDataSource _remoteDataSource;

  @override
  Future<BackendUserState> syncGoogleUser({
    required AuthSession session,
    required String firebaseIdToken,
    required String deviceId,
    required String deviceFingerprint,
    String? platform,
    String? osVersion,
  }) async {
    final dto = GoogleSyncRequestDto(
      firebaseIdToken: firebaseIdToken,
      name: session.displayName,
      profileImage: session.photoUrl,
      deviceId: deviceId,
      deviceFingerprint: deviceFingerprint,
      platform: platform,
      osVersion: osVersion,
    );

    try {
      final response = await _remoteDataSource.syncGoogleUser(dto);
      return BackendUserReady(
        userId: response.userId,
        referralCode: response.referralCode,
        isOnboarded: response.isOnboarded,
      );
    } on TransportException catch (e) {
      return switch (e) {
        UnauthenticatedException() =>
          const BackendUserFailed(BackendSyncUnauthenticated()),
        NetworkUnavailableException() || TimeoutTransportException() =>
          const BackendUserFailed(BackendSyncNetworkFailure()),
        ValidationException() =>
          BackendUserFailed(BackendSyncValidationFailure(e.message)),
        ServerException() =>
          BackendUserFailed(BackendSyncServerFailure(e.statusCode)),
        _ => BackendUserFailed(BackendSyncServerFailure(e.statusCode)),
      };
    } catch (_) {
      return const BackendUserFailed(BackendSyncNetworkFailure());
    }
  }
}
