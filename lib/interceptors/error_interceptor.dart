import 'package:dio/dio.dart';
import 'package:flutter_core_package/flutter_core_package.dart';
import 'package:flutter_dio_package/handlers/error_handler.dart';

/// Normalizes transport errors and backend failure envelopes into [Failure].
class ErrorInterceptor extends Interceptor {
  ErrorInterceptor({
    this.onErrorCallback,
    this.messageResolver,
    this.failureTypeResolver,
  });

  /// Optional application-level observer for normalized failures.
  final void Function(Failure failure)? onErrorCallback;

  /// Optional application-specific localization/message resolver.
  final ApiErrorMessageResolver? messageResolver;

  /// Optional application-specific presentation-size resolver.
  final ApiFailureTypeResolver? failureTypeResolver;

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (!DioErrorHandler.isFailureResponse(response)) {
      handler.next(response);
      return;
    }

    final failure = DioErrorHandler.handleResponse(
      response,
      messageResolver: messageResolver,
      failureTypeResolver: failureTypeResolver,
    );
    _notifyOnce(response.requestOptions, failure);

    handler.reject(
      DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: failure,
        message: failure.message ?? failure.error,
      ),
      true,
    );
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final failure = DioErrorHandler.handle(
      err,
      stackTrace: err.stackTrace,
      messageResolver: messageResolver,
      failureTypeResolver: failureTypeResolver,
    );
    _notifyOnce(err.requestOptions, failure);

    handler.next(
      err.copyWith(error: failure, message: failure.message ?? failure.error),
    );
  }

  void _notifyOnce(RequestOptions request, Failure failure) {
    if (request.extra[DioErrorHandler.failureNotifiedExtraKey] == true) {
      return;
    }
    request.extra[DioErrorHandler.failureNotifiedExtraKey] = true;
    onErrorCallback?.call(failure);
  }
}
