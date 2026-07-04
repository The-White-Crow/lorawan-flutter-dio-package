import 'package:flutter_core_package/flutter_core_package.dart';
import 'package:dio/dio.dart';

import '../handlers/error_handler.dart';

/// Error interceptor for Dio
///
/// Handles common HTTP errors and provides standardized error responses
/// Converts DioException to Failure from core_package
class ErrorInterceptor extends Interceptor {
  /// Creates an ErrorInterceptor
  ///
  /// [onError] - Optional callback when an error occurs
  ErrorInterceptor({this.onErrorCallback});

  /// Optional callback function called when an error occurs
  final void Function(Failure failure)? onErrorCallback;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Convert DioException to Failure
    final failure = DioErrorHandler.handle(err);

    // Call optional callback
    onErrorCallback?.call(failure);

    // Handle different error types
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        // Network-related errors are already handled in DioErrorHandler
        break;

      case DioExceptionType.badResponse:
        // Bad response errors are already handled in DioErrorHandler
        break;

      case DioExceptionType.cancel:
        // Cancelled requests
        break;

      case DioExceptionType.badCertificate:
        // Certificate errors
        break;

      case DioExceptionType.unknown:
        // Unknown errors
        break;
      case DioExceptionType.transformTimeout:
        // TODO: Handle this case.
        throw UnimplementedError();
    }

    super.onError(err, handler);
  }
}
