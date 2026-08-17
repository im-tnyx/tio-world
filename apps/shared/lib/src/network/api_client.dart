import 'package:dio/dio.dart';

import 'api_config.dart';
import 'auth_interceptor.dart';
import 'auth_token_provider.dart';
import 'transport_exception.dart';

/// Primary interface for making HTTP requests in Tio applications.
abstract interface class ApiClient {
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });
}

/// Concrete Dio-based implementation of [ApiClient].
class DioApiClient implements ApiClient {
  DioApiClient._(this.dio);

  /// Creates a public API client (does not attach auth headers).
  factory DioApiClient.public({
    required ApiConfig config,
    Dio? customDio,
  }) {
    final dio = customDio ??
        Dio(
          BaseOptions(
            baseUrl: config.baseUrl,
            connectTimeout: config.connectTimeout,
            receiveTimeout: config.receiveTimeout,
            sendTimeout: config.sendTimeout,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );
    return DioApiClient._(dio);
  }

  /// Creates an authenticated API client with [AuthInterceptor].
  factory DioApiClient.authenticated({
    required ApiConfig config,
    required AuthTokenProvider tokenProvider,
    Dio? customDio,
  }) {
    final dio = customDio ??
        Dio(
          BaseOptions(
            baseUrl: config.baseUrl,
            connectTimeout: config.connectTimeout,
            receiveTimeout: config.receiveTimeout,
            sendTimeout: config.sendTimeout,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

    dio.interceptors.add(
      AuthInterceptor(
        tokenProvider: tokenProvider,
        dio: dio,
      ),
    );

    return DioApiClient._(dio);
  }

  final Dio dio;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _execute(() => dio.get<T>(
          path,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
        ));
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _execute(() => dio.post<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
        ));
  }

  @override
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _execute(() => dio.patch<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
        ));
  }

  @override
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _execute(() => dio.put<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
        ));
  }

  @override
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _execute(() => dio.delete<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
        ));
  }

  Future<Response<T>> _execute<T>(Future<Response<T>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      if (e is TransportException) rethrow;
      throw UnknownTransportException(
        message: 'Unexpected network error: $e',
        cause: e,
      );
    }
  }

  TransportException _mapDioException(DioException e) {
    if (e.error is TransportException) {
      return e.error as TransportException;
    }

    final statusCode = e.response?.statusCode;
    final message = _extractErrorMessage(e.response?.data) ??
        e.message ??
        'Network transport error';

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.badCertificate:
        return TimeoutTransportException(message: 'Request timed out: $message', cause: e);

      case DioExceptionType.connectionError:
        return NetworkUnavailableException(
          message: 'Unable to connect to server: $message',
          cause: e,
        );

      case DioExceptionType.badResponse:
        if (statusCode == 401) {
          return UnauthenticatedException(message: message, statusCode: 401, cause: e);
        }
        if (statusCode == 403) {
          return ForbiddenException(message: message, statusCode: 403, cause: e);
        }
        if (statusCode == 404) {
          return NotFoundException(message: message, statusCode: 404, cause: e);
        }
        if (statusCode == 409) {
          return ConflictException(message: message, statusCode: 409, cause: e);
        }
        if (statusCode == 429) {
          return RateLimitedException(message: message, statusCode: 429, cause: e);
        }
        if (statusCode == 400 || statusCode == 422) {
          return ValidationException(
            message: message,
            statusCode: statusCode,
            errors: e.response?.data is Map<String, dynamic>
                ? e.response?.data as Map<String, dynamic>
                : null,
            cause: e,
          );
        }
        if (statusCode != null && statusCode >= 500 && statusCode < 600) {
          return ServerException(
            message: 'Server error ($statusCode): $message',
            statusCode: statusCode,
            cause: e,
          );
        }
        return UnknownTransportException(
          message: message,
          statusCode: statusCode,
          cause: e,
        );

      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
      default:
        return UnknownTransportException(
          message: message,
          statusCode: statusCode,
          cause: e,
        );
    }
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['message'] is String) return data['message'] as String;
      if (data['error'] is String) return data['error'] as String;
    }
    return null;
  }
}
