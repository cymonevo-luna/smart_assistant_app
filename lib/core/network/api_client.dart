import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exception.dart';

/// Decodes a raw JSON body (`Map`/`List`) into a typed model.
typedef JsonDecoder<T> = T Function(dynamic data);

/// A thin, reusable HTTP client built on Dio.
///
/// Registered in the service locator; resolve via `locator<ApiClient>()`:
/// ```dart
/// final user = await locator<ApiClient>().get<User>(
///   '/me',
///   decoder: (json) => User.fromJson(json),
/// );
/// ```
///
/// All failures are normalized to [ApiException], so callers never touch Dio
/// types directly.
class ApiClient {
  ApiClient({
    required String baseUrl,
    Map<String, dynamic>? headers,
    Duration connectTimeout = const Duration(seconds: 20),
    Duration receiveTimeout = const Duration(seconds: 20),
    this.onUnauthorized,
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: connectTimeout,
            receiveTimeout: receiveTimeout,
            contentType: Headers.jsonContentType,
            headers: headers,
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          handler.next(options);
        },
        onError: (e, handler) {
          if (e.response?.statusCode == 401) onUnauthorized?.call();
          handler.next(e);
        },
      ),
    );
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => debugPrint(o.toString()),
      ));
    }
  }

  final Dio _dio;
  String? _authToken;

  /// Called when the server returns 401 (e.g. to trigger logout).
  final VoidCallback? onUnauthorized;

  /// Escape hatch for advanced Dio usage (uploads, custom options, etc.).
  Dio get raw => _dio;

  /// Attach (or clear with `null`) the bearer token sent on every request.
  void setAuthToken(String? token) => _authToken = token;

  // --- Verbs ---------------------------------------------------------------
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    JsonDecoder<T>? decoder,
    CancelToken? cancelToken,
  }) =>
      _request(
        () => _dio.get(path, queryParameters: query, cancelToken: cancelToken),
        decoder,
      );

  Future<T> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    JsonDecoder<T>? decoder,
    CancelToken? cancelToken,
  }) =>
      _request(
        () => _dio.post(path,
            data: body, queryParameters: query, cancelToken: cancelToken),
        decoder,
      );

  Future<T> put<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    JsonDecoder<T>? decoder,
    CancelToken? cancelToken,
  }) =>
      _request(
        () => _dio.put(path,
            data: body, queryParameters: query, cancelToken: cancelToken),
        decoder,
      );

  Future<T> patch<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    JsonDecoder<T>? decoder,
    CancelToken? cancelToken,
  }) =>
      _request(
        () => _dio.patch(path,
            data: body, queryParameters: query, cancelToken: cancelToken),
        decoder,
      );

  Future<T> delete<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    JsonDecoder<T>? decoder,
    CancelToken? cancelToken,
  }) =>
      _request(
        () => _dio.delete(path,
            data: body, queryParameters: query, cancelToken: cancelToken),
        decoder,
      );

  Future<T> _request<T>(
    Future<Response<dynamic>> Function() send,
    JsonDecoder<T>? decoder,
  ) async {
    try {
      final response = await send();
      final data = response.data;
      if (decoder != null) return decoder(data);
      return data as T;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
