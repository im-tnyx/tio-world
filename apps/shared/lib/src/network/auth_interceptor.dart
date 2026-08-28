import 'package:dio/dio.dart';

import 'auth_token_provider.dart';
import 'transport_exception.dart';

/// Interceptor that attaches the Bearer token to protected API calls,
/// redacts Authorization headers in logs/errors, and handles single-retry 401 token refresh.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.tokenProvider,
    required this.dio,
  });

  final AuthTokenProvider tokenProvider;
  final Dio dio;

  static const _retryKey = '_tio_auth_retried';

  Future<String?>? _inFlightRefresh;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[_retryKey] == true &&
        options.headers.containsKey('Authorization')) {
      return handler.next(options);
    }

    try {
      final token = await tokenProvider.getIdToken();
      if (token == null || token.trim().isEmpty) {
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            error: const UnauthenticatedException(
              message: 'No authenticated token available for protected request.',
            ),
            response: Response(
              requestOptions: options,
              statusCode: 401,
              statusMessage: 'Unauthorized',
            ),
          ),
        );
      }

      options.headers['Authorization'] = 'Bearer ${token.trim()}';
      return handler.next(options);
    } catch (e) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: UnauthenticatedException(
            message: 'Failed to retrieve auth token: $e',
            cause: e,
          ),
        ),
      );
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;

    // 401 Unauthorized -> Attempt single token refresh and request retry.
    if (statusCode == 401) {
      final isAlreadyRetried =
          err.requestOptions.extra[_retryKey] as bool? ?? false;

      if (!isAlreadyRetried) {
        try {
          final refreshedToken = await _refreshTokenOnce();
          if (refreshedToken != null && refreshedToken.trim().isNotEmpty) {
            final retryOptions = err.requestOptions;
            retryOptions.extra[_retryKey] = true;
            retryOptions.headers['Authorization'] =
                'Bearer ${refreshedToken.trim()}';

            try {
              final response = await dio.fetch(retryOptions);
              return handler.resolve(response);
            } on DioException catch (retryErr) {
              return handler.next(retryErr);
            }
          }
        } catch (_) {
          // Fall through to reject the original 401 for all waiting requests.
        }
      }
    }

    return handler.next(err);
  }

  Future<String?> _refreshTokenOnce() {
    final activeRefresh = _inFlightRefresh;
    if (activeRefresh != null) {
      return activeRefresh;
    }

    final refresh = _performRefresh();
    _inFlightRefresh = refresh;
    return refresh;
  }

  Future<String?> _performRefresh() async {
    try {
      return await tokenProvider.getIdToken(forceRefresh: true);
    } finally {
      _inFlightRefresh = null;
    }
  }

  /// Utility to redact Authorization headers from map copies for safe logging.
  static Map<String, dynamic> redactHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);
    if (sanitized.containsKey('Authorization')) {
      sanitized['Authorization'] = 'Bearer [REDACTED]';
    }
    if (sanitized.containsKey('authorization')) {
      sanitized['authorization'] = 'Bearer [REDACTED]';
    }
    return sanitized;
  }
}
