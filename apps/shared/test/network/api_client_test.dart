import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('ApiConfig', () {
    test('props equality and defaults', () {
      const config1 = ApiConfig(baseUrl: 'https://api.tnyx.app');
      const config2 = ApiConfig(baseUrl: 'https://api.tnyx.app');
      expect(config1, equals(config2));
      expect(config1.connectTimeout, const Duration(seconds: 10));
      expect(config1.receiveTimeout, const Duration(seconds: 15));
    });
  });

  group('AuthInterceptor', () {
    test('redacts Authorization header safely', () {
      final headers = {
        'Authorization': 'Bearer secret-token-123',
        'Content-Type': 'application/json',
      };
      final sanitized = AuthInterceptor.redactHeaders(headers);
      expect(sanitized['Authorization'], 'Bearer [REDACTED]');
      expect(sanitized['Content-Type'], 'application/json');
    });
  });

  group('DioApiClient.public', () {
    test('executes requests without Authorization header', () async {
      final dio = Dio();
      dio.httpClientAdapter = _MockHttpClientAdapter((options) {
        expect(options.headers.containsKey('Authorization'), isFalse);
        return ResponseBody.fromString(
          '{"success": true, "data": "hello"}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final client = DioApiClient.public(
        config: const ApiConfig(baseUrl: 'https://api.tnyx.app'),
        customDio: dio,
      );

      final response = await client.get<Map<String, dynamic>>('/public-route');
      expect(response.statusCode, 200);
      expect(response.data?['data'], 'hello');
    });
  });

  group('DioApiClient.authenticated', () {
    test('attaches Bearer token when token is available', () async {
      final tokenProvider = _FakeTokenProvider(token: 'valid-firebase-token-001');
      final dio = Dio();
      dio.httpClientAdapter = _MockHttpClientAdapter((options) {
        expect(options.headers['Authorization'], 'Bearer valid-firebase-token-001');
        return ResponseBody.fromString(
          '{"success": true, "data": "protected-data"}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final client = DioApiClient.authenticated(
        config: const ApiConfig(baseUrl: 'https://api.tnyx.app'),
        tokenProvider: tokenProvider,
        customDio: dio,
      );

      final response = await client.get<Map<String, dynamic>>('/protected-route');
      expect(response.statusCode, 200);
      expect(response.data?['data'], 'protected-data');
    });

    test('rejects with UnauthenticatedException if token is missing/null', () async {
      final tokenProvider = _FakeTokenProvider(token: null);
      final dio = Dio();
      dio.httpClientAdapter = _MockHttpClientAdapter((options) {
        fail('Should not send HTTP request when token is null');
      });

      final client = DioApiClient.authenticated(
        config: const ApiConfig(baseUrl: 'https://api.tnyx.app'),
        tokenProvider: tokenProvider,
        customDio: dio,
      );

      await expectLater(
        () => client.get<Map<String, dynamic>>('/protected-route'),
        throwsA(isA<UnauthenticatedException>()),
      );
    });

    test('401 triggers single token refresh and retries original request', () async {
      final tokenProvider = _FakeTokenProvider(
        token: 'initial-expired-token',
        refreshedToken: 'new-valid-token',
      );
      int callCount = 0;
      final dio = Dio();
      dio.httpClientAdapter = _MockHttpClientAdapter((options) {
        callCount++;
        if (callCount == 1) {
          expect(options.headers['Authorization'], 'Bearer initial-expired-token');
          return ResponseBody.fromString(
            '{"success": false, "message": "Invalid or expired token"}',
            401,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        } else {
          expect(options.headers['Authorization'], 'Bearer new-valid-token');
          return ResponseBody.fromString(
            '{"success": true, "data": "retried-success"}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
      });

      final client = DioApiClient.authenticated(
        config: const ApiConfig(baseUrl: 'https://api.tnyx.app'),
        tokenProvider: tokenProvider,
        customDio: dio,
      );

      final response = await client.get<Map<String, dynamic>>('/protected-route');
      expect(response.statusCode, 200);
      expect(response.data?['data'], 'retried-success');
      expect(callCount, 2);
      expect(tokenProvider.forceRefreshCalls, 1);
    });

    test('401 on retry fails with UnauthenticatedException without infinite loop', () async {
      final tokenProvider = _FakeTokenProvider(
        token: 'initial-expired-token',
        refreshedToken: 'still-invalid-token',
      );
      int callCount = 0;
      final dio = Dio();
      dio.httpClientAdapter = _MockHttpClientAdapter((options) {
        callCount++;
        return ResponseBody.fromString(
          '{"success": false, "message": "Unauthorized"}',
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final client = DioApiClient.authenticated(
        config: const ApiConfig(baseUrl: 'https://api.tnyx.app'),
        tokenProvider: tokenProvider,
        customDio: dio,
      );

      await expectLater(
        () => client.get<Map<String, dynamic>>('/protected-route'),
        throwsA(isA<UnauthenticatedException>()),
      );
      expect(tokenProvider.forceRefreshCalls, 1);
      expect(callCount, 2);
    });

    test('403 forbidden does not trigger refresh loop and maps to ForbiddenException', () async {
      final tokenProvider = _FakeTokenProvider(token: 'valid-token');
      int callCount = 0;
      final dio = Dio();
      dio.httpClientAdapter = _MockHttpClientAdapter((options) {
        callCount++;
        return ResponseBody.fromString(
          '{"success": false, "message": "Account disabled"}',
          403,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final client = DioApiClient.authenticated(
        config: const ApiConfig(baseUrl: 'https://api.tnyx.app'),
        tokenProvider: tokenProvider,
        customDio: dio,
      );

      await expectLater(
        () => client.get<Map<String, dynamic>>('/protected-route'),
        throwsA(isA<ForbiddenException>()),
      );
      expect(tokenProvider.forceRefreshCalls, 0);
      expect(callCount, 1);
    });

    test('400 / 422 maps to ValidationException', () async {
      final tokenProvider = _FakeTokenProvider(token: 'valid-token');
      final dio = Dio();
      dio.httpClientAdapter = _MockHttpClientAdapter((options) {
        return ResponseBody.fromString(
          '{"success": false, "message": "Invalid input"}',
          400,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final client = DioApiClient.authenticated(
        config: const ApiConfig(baseUrl: 'https://api.tnyx.app'),
        tokenProvider: tokenProvider,
        customDio: dio,
      );

      await expectLater(
        () => client.post<Map<String, dynamic>>('/submit', data: {}),
        throwsA(isA<ValidationException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });

    test('429 maps to RateLimitedException', () async {
      final tokenProvider = _FakeTokenProvider(token: 'valid-token');
      final dio = Dio();
      dio.httpClientAdapter = _MockHttpClientAdapter((options) {
        return ResponseBody.fromString(
          '{"success": false, "message": "Too many requests"}',
          429,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final client = DioApiClient.authenticated(
        config: const ApiConfig(baseUrl: 'https://api.tnyx.app'),
        tokenProvider: tokenProvider,
        customDio: dio,
      );

      await expectLater(
        () => client.get<Map<String, dynamic>>('/route'),
        throwsA(isA<RateLimitedException>()),
      );
    });

    test('500 maps to ServerException', () async {
      final tokenProvider = _FakeTokenProvider(token: 'valid-token');
      final dio = Dio();
      dio.httpClientAdapter = _MockHttpClientAdapter((options) {
        return ResponseBody.fromString(
          '{"success": false, "message": "Internal Server Error"}',
          500,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final client = DioApiClient.authenticated(
        config: const ApiConfig(baseUrl: 'https://api.tnyx.app'),
        tokenProvider: tokenProvider,
        customDio: dio,
      );

      await expectLater(
        () => client.get<Map<String, dynamic>>('/route'),
        throwsA(isA<ServerException>()),
      );
    });
  });
}

class _FakeTokenProvider implements AuthTokenProvider {
  _FakeTokenProvider({
    this.token,
    this.refreshedToken,
  });

  final String? token;
  final String? refreshedToken;
  int forceRefreshCalls = 0;

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    if (forceRefresh) {
      forceRefreshCalls++;
      return refreshedToken;
    }
    return token;
  }
}

class _MockHttpClientAdapter implements HttpClientAdapter {
  _MockHttpClientAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}
