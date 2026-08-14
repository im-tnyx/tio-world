import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('RemoteOnboardingFinalizer', () {
    test('calls POST /api/v1/onboarding/finalize on finalize()', () async {
      final mockClient = _MockApiClient();
      final finalizer = RemoteOnboardingFinalizer(mockClient);

      await finalizer.finalize();

      expect(mockClient.lastMethod, 'POST');
      expect(mockClient.lastPath, '/api/v1/onboarding/finalize');
    });

    test('propagates transport exceptions to caller', () async {
      final mockClient = _MockApiClient(
        errorToThrow: const ServerException(message: 'Finalize failed', statusCode: 500),
      );
      final finalizer = RemoteOnboardingFinalizer(mockClient);

      await expectLater(
        () => finalizer.finalize(),
        throwsA(isA<ServerException>()),
      );
    });
  });
}

class _MockApiClient implements ApiClient {
  _MockApiClient({this.errorToThrow});

  final Object? errorToThrow;
  String? lastMethod;
  String? lastPath;

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastMethod = 'POST';
    lastPath = path;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
    );
  }

  @override
  Future<Response<T>> delete<T>(String path, {data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async =>
      throw UnimplementedError();

  @override
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async =>
      throw UnimplementedError();

  @override
  Future<Response<T>> patch<T>(String path, {data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async =>
      throw UnimplementedError();

  @override
  Future<Response<T>> put<T>(String path, {data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async =>
      throw UnimplementedError();
}
