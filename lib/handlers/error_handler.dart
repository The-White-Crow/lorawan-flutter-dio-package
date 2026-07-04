import 'package:flutter_core_package/flutter_core_package.dart';
import 'package:dio/dio.dart';

import '../models/response_code.dart';

/// Error handler for Dio exceptions
///
/// Converts DioException to appropriate Failure from flutter_core_package
class DioErrorHandler {
  /// Handle DioException and convert to Failure
  static Failure handle(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    }
    return UnexpectedFailure(tag: FailureTag.unexpected, error: 'An unexpected error occurred', message: error.toString());
  }

  /// Handle DioException based on error type
  static Failure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.badResponse:
        // When response code exists
        return _handleResponseError(error);

      case DioExceptionType.connectionTimeout:
      case DioExceptionType.connectionError:
        return NetworkFailure(
          error: 'Connection timeout',
          message: 'Unable to connect to the server. Please check your internet connection.',
          errorCode: ResponseCode.connectTimeout.toString(),
        );

      case DioExceptionType.sendTimeout:
        return NetworkFailure(
          error: 'Send timeout',
          message: 'Request took too long to send. Please try again.',
          errorCode: ResponseCode.sendTimeout.toString(),
        );

      case DioExceptionType.receiveTimeout:
        return NetworkFailure(
          error: 'Receive timeout',
          message: 'Response took too long to receive. Please try again.',
          errorCode: ResponseCode.receiveTimeout.toString(),
        );

      case DioExceptionType.cancel:
        return CustomFailure(
          error: 'Request cancelled',
          message: 'The request was cancelled.',
          errorCode: ResponseCode.cancel.toString(),
        );

      case DioExceptionType.badCertificate:
        return NetworkFailure(
          error: 'Bad certificate',
          message: 'SSL certificate error. Please check your connection.',
          errorCode: ResponseCode.badCertificate.toString(),
        );

      case DioExceptionType.unknown:
        return UnexpectedFailure(
          tag: FailureTag.network,
          error: 'Unknown error',
          message: error.message ?? 'An unknown error occurred',
        );
      case DioExceptionType.transformTimeout:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  /// Handle response errors based on status code
  static Failure _handleResponseError(DioException error) {
    final statusCode = error.response?.statusCode;

    switch (statusCode) {
      case ResponseCode.badRequest:
        return CustomFailure(
          error: 'Bad request',
          message: 'The request was invalid. Please check your input.',
          errorCode: statusCode.toString(),
        );

      case ResponseCode.unauthorized:
        return CustomFailure(
          error: 'Unauthorized',
          message: 'You are not authorized to access this resource.',
          errorCode: statusCode.toString(),
          tag: FailureTag.authentication,
        );

      case ResponseCode.forbidden:
        return CustomFailure(
          error: 'Forbidden',
          message: 'You do not have permission to access this resource.',
          errorCode: statusCode.toString(),
          tag: FailureTag.authorization,
        );

      case ResponseCode.notFound:
        return CustomFailure(
          error: 'Not found',
          message: 'The requested resource was not found.',
          errorCode: statusCode.toString(),
        );

      case ResponseCode.internalServerError:
        return ServerFailure(
          error: 'Internal server error',
          message: 'The server encountered an error. Please try again later.',
          errorCode: statusCode.toString(),
        );

      case ResponseCode.networkAuthenticationRequired:
        return CustomFailure(
          error: 'Network authentication required',
          message: 'Network authentication is required.',
          errorCode: statusCode.toString(),
          tag: FailureTag.authentication,
        );

      default:
        return ServerFailure(
          error: 'Server error',
          message: error.response?.data?.toString() ?? 'An error occurred on the server.',
          errorCode: statusCode?.toString(),
        );
    }
  }
}
