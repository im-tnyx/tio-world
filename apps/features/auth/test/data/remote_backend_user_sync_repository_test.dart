import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_auth/src/data/datasources/backend_user_sync_remote_data_source.dart';
import 'package:tio_feature_auth/src/data/dto/backend_user_sync_response_dto.dart';
import 'package:tio_feature_auth/src/data/dto/google_sync_request_dto.dart';
import 'package:tio_feature_auth/src/data/repositories/remote_backend_user_sync_repository.dart';
import 'package:tio_feature_auth/src/domain/models/auth_session.dart';
import 'package:tio_feature_auth/src/domain/models/backend_user_state.dart';
import 'package:tio_shared/shared.dart';

class _FakeDataSource implements BackendUserSyncRemoteDataSource {
  BackendUserSyncResponseDto? response;
  Exception? error;

  @override
  Future<BackendUserSyncResponseDto> syncGoogleUser(GoogleSyncRequestDto dto) async {
    if (error != null) throw error!;
    return response!;
  }
}

void main() {
  late _FakeDataSource fakeDataSource;
  late RemoteBackendUserSyncRepository repository;

  setUp(() {
    fakeDataSource = _FakeDataSource();
    repository = RemoteBackendUserSyncRepository(remoteDataSource: fakeDataSource);
  });

  test('syncGoogleUser success returns BackendUserReady', () async {
    fakeDataSource.response = const BackendUserSyncResponseDto(
      isNewUser: true,
      isOnboarded: false,
      userId: 'u1',
      referralCode: 'r1',
    );

    final result = await repository.syncGoogleUser(
      session: const AuthSession(userId: 'u1'),
      firebaseIdToken: 'tok',
      deviceId: 'dev',
      deviceFingerprint: 'fin',
    );

    expect(result, isA<BackendUserReady>());
    expect((result as BackendUserReady).userId, 'u1');
  });

  test('syncGoogleUser 401 returns BackendSyncUnauthenticated', () async {
    fakeDataSource.error = const UnauthenticatedException();

    final result = await repository.syncGoogleUser(
      session: const AuthSession(userId: 'u1'),
      firebaseIdToken: 'tok',
      deviceId: 'dev',
      deviceFingerprint: 'fin',
    );

    expect(
      result,
      const BackendUserFailed(BackendSyncUnauthenticated()),
    );
  });

  test('syncGoogleUser network error returns BackendSyncNetworkFailure', () async {
    fakeDataSource.error = const NetworkUnavailableException();

    final result = await repository.syncGoogleUser(
      session: const AuthSession(userId: 'u1'),
      firebaseIdToken: 'tok',
      deviceId: 'dev',
      deviceFingerprint: 'fin',
    );

    expect(
      result,
      const BackendUserFailed(BackendSyncNetworkFailure()),
    );
  });
}
