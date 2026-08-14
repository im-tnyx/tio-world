import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_auth/src/data/datasources/backend_user_sync_remote_data_source.dart';
import 'package:tio_feature_auth/src/data/dto/google_sync_request_dto.dart';
import 'package:tio_shared/shared.dart';

class _FakeApiClient implements ApiClient {
  Map<String, dynamic>? responseData;
  Exception? errorToThrow;

  @override
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) {
    throw UnimplementedError();
  }

  @override
  Future<Response<T>> post<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    if (errorToThrow != null) throw errorToThrow!;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: responseData as T,
    );
  }

  @override
  Future<Response<T>> patch<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) {
    throw UnimplementedError();
  }

  @override
  Future<Response<T>> put<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) {
    throw UnimplementedError();
  }

  @override
  Future<Response<T>> delete<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) {
    throw UnimplementedError();
  }
}

void main() {
  late _FakeApiClient fakeClient;
  late BackendUserSyncRemoteDataSource dataSource;

  setUp(() {
    fakeClient = _FakeApiClient();
    dataSource = BackendUserSyncRemoteDataSource(fakeClient);
  });

  test('syncGoogleUser success', () async {
    fakeClient.responseData = {
      'success': true,
      'isNewUser': true,
      'is_onboarded': false,
      'user': {
        'id': 'user-123',
        'referralCode': 'REF123',
      },
    };

    final result = await dataSource.syncGoogleUser(
      const GoogleSyncRequestDto(
        firebaseIdToken: 'tok',
        deviceId: 'dev',
        deviceFingerprint: 'fin',
      ),
    );

    expect(result.userId, 'user-123');
    expect(result.referralCode, 'REF123');
    expect(result.isNewUser, true);
    expect(result.isOnboarded, false);
  });
}
