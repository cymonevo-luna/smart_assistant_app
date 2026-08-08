import 'package:dio/dio.dart';

/// Normalized error categories so the UI can react without knowing about Dio.
enum ApiErrorType {
  network, // no connection / dns failure
  timeout, // connect/send/receive timeout
  badRequest, // 400
  unauthorized, // 401
  forbidden, // 403
  notFound, // 404
  conflict, // 409
  server, // 5xx
  cancelled, // request cancelled
  unknown,
}

/// A single, friendly exception type for all network failures. Map a raw
/// [DioException] into this via [ApiException.fromDio].
class ApiException implements Exception {
  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.data,
  });

  final ApiErrorType type;
  final String message;
  final int? statusCode;
  final dynamic data;

  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          type: ApiErrorType.timeout,
          message: 'The connection timed out. Please try again.',
        );
      case DioExceptionType.cancel:
        return const ApiException(
          type: ApiErrorType.cancelled,
          message: 'Request was cancelled.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          type: ApiErrorType.network,
          message: 'No internet connection.',
        );
      case DioExceptionType.badCertificate:
        return const ApiException(
          type: ApiErrorType.network,
          message: 'Invalid server certificate.',
        );
      case DioExceptionType.badResponse:
        return _fromStatus(e);
      case DioExceptionType.unknown:
        return ApiException(
          type: ApiErrorType.unknown,
          message: e.message ?? 'Something went wrong.',
        );
    }
  }

  static ApiException _fromStatus(DioException e) {
    final code = e.response?.statusCode;
    final data = e.response?.data;
    final (type, message) = switch (code) {
      400 => (ApiErrorType.badRequest, 'Invalid request.'),
      401 => (ApiErrorType.unauthorized, 'Your session has expired.'),
      403 => (ApiErrorType.forbidden, 'You don\'t have access to this.'),
      404 => (ApiErrorType.notFound, 'Not found.'),
      409 => (ApiErrorType.conflict, 'Conflict with the current state.'),
      _ when (code ?? 0) >= 500 => (ApiErrorType.server, 'Server error.'),
      _ => (ApiErrorType.unknown, 'Something went wrong.'),
    };
    return ApiException(
      type: type,
      message: message,
      statusCode: code,
      data: data,
    );
  }

  @override
  String toString() => 'ApiException($type, $statusCode): $message';
}
