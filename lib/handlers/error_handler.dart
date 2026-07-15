import 'package:dio/dio.dart';
import 'package:flutter_core_package/flutter_core_package.dart';
import 'package:flutter_dio_package/models/api_error.dart';
import 'package:flutter_dio_package/models/api_result_code.dart';
import 'package:flutter_dio_package/models/response_code.dart';

/// Resolves an application-specific, user-safe message for an API error.
typedef ApiErrorMessageResolver = String Function(ApiError error);

/// Overrides the default presentation size for an API error.
typedef ApiFailureTypeResolver =
    FailureType Function(ApiError error, RequestOptions request);

/// Converts transport and backend errors into the application's [Failure]
/// hierarchy.
///
/// Backend error codes mirror `pkg/error/status_code_mapping.go`. The backend
/// message is explicitly client-safe, while technical exception details are
/// logged and never exposed through [Failure.message].
abstract final class DioErrorHandler {
  /// Per-request override for the resulting [FailureType].
  static const failureTypeExtraKey = 'dio_failure_type';

  /// Internal marker used by the error interceptor to avoid duplicate callbacks.
  static const failureNotifiedExtraKey = 'dio_failure_notified';

  static const _readMethods = {'GET', 'HEAD', 'OPTIONS'};

  static const _inlineCodes = {
    ApiResultCode.badRequest,
    ApiResultCode.validationError,
    ApiResultCode.invalidPhoneNumber,
    ApiResultCode.otpExpired,
    ApiResultCode.otpInvalid,
    ApiResultCode.verifyTokenInvalid,
  };

  static const _authenticationCodes = {
    ApiResultCode.authError,
    ApiResultCode.unauthorizedError,
    ApiResultCode.tokenExpired,
  };

  static const _authorizationCodes = {
    ApiResultCode.forbiddenError,
    ApiResultCode.accountSuspended,
    ApiResultCode.unauthorizedTopic,
    ApiResultCode.widgetDeviceNotOwned,
  };

  static const _notFoundCodes = {
    ApiResultCode.notFoundError,
    ApiResultCode.gatewayNotFound,
    ApiResultCode.deviceNotFound,
    ApiResultCode.deviceProfileNotFound,
    ApiResultCode.dashboardNotFound,
    ApiResultCode.widgetNotFound,
  };

  static const _conflictCodes = {
    ApiResultCode.conflictError,
    ApiResultCode.gatewayAlreadyClaimed,
    ApiResultCode.gatewayAlreadyOwned,
    ApiResultCode.deviceAlreadyClaimed,
    ApiResultCode.deviceAlreadyOwned,
    ApiResultCode.profileNotSynced,
    ApiResultCode.profileSyncFailed,
    ApiResultCode.profileInUse,
    ApiResultCode.dashboardNameTaken,
  };

  static const _rateLimitCodes = {
    ApiResultCode.limiterError,
    ApiResultCode.otpRateLimited,
  };

  static const _serverCodes = {
    ApiResultCode.customRecovery,
    ApiResultCode.internalError,
    ApiResultCode.networkError,
    ApiResultCode.gatewayClaimFailed,
    ApiResultCode.gatewayUpdateFailed,
    ApiResultCode.gatewayRemoveFailed,
    ApiResultCode.deviceClaimFailed,
    ApiResultCode.deviceUpdateFailed,
    ApiResultCode.deviceRemoveFailed,
  };

  /// Convert any caught error to a user-presentable [Failure].
  static Failure handle(
    Object error, {
    StackTrace? stackTrace,
    ApiErrorMessageResolver? messageResolver,
    ApiFailureTypeResolver? failureTypeResolver,
  }) {
    if (error is Failure) return error;

    if (error is DioException) {
      if (error.error case final Failure failure) return failure;
      return _handleDioError(
        error,
        messageResolver: messageResolver,
        failureTypeResolver: failureTypeResolver,
      );
    }

    'Unexpected request error: $error'.log(
      tag: 'DioErrorHandler',
      level: LogLevel.error,
      stackTrace: stackTrace,
    );
    return const UnexpectedFailure(
      tag: FailureTag.unexpected,
      error: 'Unexpected error',
      message: 'Something went wrong. Please try again.',
      type: FailureType.popUp,
    );
  }

  /// Convert an HTTP [response] directly to a [Failure].
  static Failure handleResponse(
    Response<dynamic> response, {
    ApiErrorMessageResolver? messageResolver,
    ApiFailureTypeResolver? failureTypeResolver,
  }) {
    return _fromApiError(
      extractApiError(response) ??
          ApiError(
            message: _fallbackMessageForStatus(response.statusCode),
            code: 'HTTP_${response.statusCode ?? ResponseCode.defaultError}',
            statusCode: response.statusCode,
          ),
      response.requestOptions,
      messageResolver: messageResolver,
      failureTypeResolver: failureTypeResolver,
    );
  }

  /// Whether a response contains the backend's failure envelope.
  ///
  /// This also catches errors returned with a 2xx status, such as
  /// `CHIRPSTACK_SYNC_PENDING` (HTTP 202).
  static bool isFailureResponse(Response<dynamic> response) {
    final payload = _asStringMap(response.data);
    if (payload == null) return false;
    return payload['success'] == false || payload['error'] is Map;
  }

  /// Parse the backend's `{success, error, metadata}` response contract.
  static ApiError? extractApiError(Response<dynamic> response) {
    final payload = _asStringMap(response.data);
    if (payload == null) return null;

    final metadata = _asStringMap(payload['metadata']);
    final requestId = _nonEmptyString(metadata?['request_id']);
    final errorPayload = _asStringMap(payload['error']);

    if (errorPayload != null) {
      return ApiError.fromJson(
        errorPayload,
        statusCode: response.statusCode,
        requestId: requestId,
      );
    }

    if (payload['success'] == false) {
      return ApiError(
        code: _nonEmptyString(payload['code']) ?? 'UNKNOWN_ERROR',
        message:
            _nonEmptyString(payload['message']) ??
            _fallbackMessageForStatus(response.statusCode),
        details: payload['details'],
        statusCode: response.statusCode,
        requestId: requestId,
      );
    }

    return null;
  }

  static Failure _handleDioError(
    DioException error, {
    ApiErrorMessageResolver? messageResolver,
    ApiFailureTypeResolver? failureTypeResolver,
  }) {
    switch (error.type) {
      case DioExceptionType.badResponse:
        final response = error.response;
        if (response != null) {
          return handleResponse(
            response,
            messageResolver: messageResolver,
            failureTypeResolver: failureTypeResolver,
          );
        }
        return _serverFailure(
          request: error.requestOptions,
          errorCode: ResponseCode.defaultError.toString(),
        );

      case DioExceptionType.connectionTimeout:
      case DioExceptionType.connectionError:
        return _networkFailure(
          request: error.requestOptions,
          error: 'Connection error',
          message:
              'Unable to connect. Check your internet connection and try again.',
          errorCode: ResponseCode.connectTimeout.toString(),
        );

      case DioExceptionType.sendTimeout:
        return _networkFailure(
          request: error.requestOptions,
          error: 'Send timeout',
          message: 'The request took too long to send. Please try again.',
          errorCode: ResponseCode.sendTimeout.toString(),
        );

      case DioExceptionType.receiveTimeout:
        return _networkFailure(
          request: error.requestOptions,
          error: 'Receive timeout',
          message: 'The server took too long to respond. Please try again.',
          errorCode: ResponseCode.receiveTimeout.toString(),
        );

      case DioExceptionType.transformTimeout:
        return UnexpectedFailure(
          tag: FailureTag.unexpected,
          error: 'Response processing timeout',
          message:
              'The response could not be processed in time. Please try again.',
          errorCode: ResponseCode.defaultError.toString(),
          type: _typeForRequest(error.requestOptions),
        );

      case DioExceptionType.cancel:
        return CustomFailure(
          error: 'Request cancelled',
          message: 'The request was cancelled.',
          errorCode: ResponseCode.cancel.toString(),
          type: FailureType.silent,
        );

      case DioExceptionType.badCertificate:
        return _networkFailure(
          request: error.requestOptions,
          error: 'Secure connection failed',
          message: 'A secure connection could not be established.',
          errorCode: ResponseCode.badCertificate.toString(),
        );

      case DioExceptionType.unknown:
        'Unknown Dio error: ${error.error ?? error.message}'.log(
          tag: 'DioErrorHandler',
          level: LogLevel.error,
          stackTrace: error.stackTrace,
        );
        return UnexpectedFailure(
          tag: FailureTag.unexpected,
          error: 'Unexpected error',
          message: 'Something went wrong. Please try again.',
          errorCode: ResponseCode.defaultError.toString(),
          type: _typeForRequest(error.requestOptions),
        );
    }
  }

  static Failure _fromApiError(
    ApiError apiError,
    RequestOptions request, {
    ApiErrorMessageResolver? messageResolver,
    ApiFailureTypeResolver? failureTypeResolver,
  }) {
    final code = apiError.code;
    final statusCode = apiError.statusCode;
    final message = _resolveMessage(apiError, messageResolver);
    final type = _resolveFailureType(apiError, request, failureTypeResolver);

    if (_serverCodes.contains(code) ||
        (statusCode != null && statusCode >= 500)) {
      return ServerFailure(
        error: _titleForCode(code, statusCode),
        message: message,
        errorCode: code,
        type: type,
      );
    }

    return CustomFailure(
      error: _titleForCode(code, statusCode),
      message: message,
      errorCode: code,
      tag: _tagForCode(code, statusCode),
      type: type,
    );
  }

  static FailureType _resolveFailureType(
    ApiError error,
    RequestOptions request,
    ApiFailureTypeResolver? resolver,
  ) {
    final requestOverride = request.extra[failureTypeExtraKey];
    if (requestOverride is FailureType) {
      return requestOverride;
    }
    if (resolver != null) {
      return resolver(error, request);
    }

    final code = error.code;
    if (_inlineCodes.contains(code)) {
      return FailureType.inline;
    }
    if (_authenticationCodes.contains(code)) {
      return FailureType.silent;
    }
    if (code == ApiResultCode.accountSuspended) {
      return FailureType.fullPage;
    }
    if (_conflictCodes.contains(code) ||
        _rateLimitCodes.contains(code) ||
        code == ApiResultCode.methodNotAllowedError ||
        code == ApiResultCode.otpAlreadySent ||
        code == ApiResultCode.otpMaxAttempts ||
        code == ApiResultCode.chirpstackSyncPending) {
      return FailureType.popUp;
    }
    if (_authorizationCodes.contains(code) ||
        _notFoundCodes.contains(code) ||
        _serverCodes.contains(code)) {
      return _typeForRequest(request);
    }

    return switch (error.statusCode) {
      ResponseCode.badRequest => FailureType.inline,
      ResponseCode.unauthorized => FailureType.silent,
      ResponseCode.forbidden ||
      ResponseCode.notFound => _typeForRequest(request),
      ResponseCode.methodNotAllowed ||
      ResponseCode.conflict ||
      ResponseCode.tooManyRequests => FailureType.popUp,
      final status when status != null && status >= 500 => _typeForRequest(
        request,
      ),
      _ => FailureType.popUp,
    };
  }

  static FailureType _typeForRequest(RequestOptions request) {
    return _readMethods.contains(request.method.toUpperCase())
        ? FailureType.fullPage
        : FailureType.popUp;
  }

  static FailureTag _tagForCode(String code, int? statusCode) {
    if (_inlineCodes.contains(code) || statusCode == ResponseCode.badRequest) {
      return FailureTag.validation;
    }
    if (_authenticationCodes.contains(code) ||
        statusCode == ResponseCode.unauthorized) {
      return FailureTag.authentication;
    }
    if (_authorizationCodes.contains(code) ||
        statusCode == ResponseCode.forbidden) {
      return FailureTag.authorization;
    }
    if (_serverCodes.contains(code) ||
        (statusCode != null && statusCode >= 500)) {
      return FailureTag.server;
    }
    return FailureTag.custom;
  }

  static String _titleForCode(String code, int? statusCode) {
    if (_inlineCodes.contains(code) || statusCode == ResponseCode.badRequest) {
      return 'Validation error';
    }
    if (_authenticationCodes.contains(code) ||
        statusCode == ResponseCode.unauthorized) {
      return 'Authentication required';
    }
    if (_authorizationCodes.contains(code) ||
        statusCode == ResponseCode.forbidden) {
      return 'Access denied';
    }
    if (_notFoundCodes.contains(code) || statusCode == ResponseCode.notFound) {
      return 'Not found';
    }
    if (_conflictCodes.contains(code) || statusCode == ResponseCode.conflict) {
      return 'Conflict';
    }
    if (_rateLimitCodes.contains(code) ||
        statusCode == ResponseCode.tooManyRequests) {
      return 'Too many requests';
    }
    if (code == ApiResultCode.chirpstackSyncPending) {
      return 'Synchronization pending';
    }
    if (_serverCodes.contains(code) ||
        (statusCode != null && statusCode >= 500)) {
      return 'Server error';
    }
    return 'Request failed';
  }

  static String _resolveMessage(
    ApiError error,
    ApiErrorMessageResolver? resolver,
  ) {
    if (resolver != null) {
      final resolved = resolver(error).trim();
      if (resolved.isNotEmpty) return resolved;
    }

    final validationDetails = _validationDetailsMessage(error.details);
    if (_inlineCodes.contains(error.code) && validationDetails != null) {
      return validationDetails;
    }

    final backendMessage = error.message.trim();
    return backendMessage.isEmpty
        ? _fallbackMessageForStatus(error.statusCode)
        : backendMessage;
  }

  static String? _validationDetailsMessage(Object? details) {
    if (details is! Iterable) return null;

    final messages = details
        .map((detail) => detail.toString().trim())
        .where((detail) => detail.isNotEmpty)
        .toList(growable: false);
    return messages.isEmpty ? null : messages.join('\n');
  }

  static NetworkFailure _networkFailure({
    required RequestOptions request,
    required String error,
    required String message,
    required String errorCode,
  }) {
    return NetworkFailure(
      error: error,
      message: message,
      errorCode: errorCode,
      type: _typeForRequest(request),
    );
  }

  static ServerFailure _serverFailure({
    required RequestOptions request,
    required String errorCode,
  }) {
    return ServerFailure(errorCode: errorCode, type: _typeForRequest(request));
  }

  static String _fallbackMessageForStatus(int? statusCode) {
    return switch (statusCode) {
      ResponseCode.badRequest =>
        'Please check the entered information and try again.',
      ResponseCode.unauthorized =>
        'Your session has expired. Please sign in again.',
      ResponseCode.forbidden =>
        'You do not have permission to perform this action.',
      ResponseCode.notFound => 'The requested resource was not found.',
      ResponseCode.methodNotAllowed => 'This operation is not supported.',
      ResponseCode.conflict =>
        'The request conflicts with the current resource state.',
      ResponseCode.tooManyRequests =>
        'Too many requests. Please wait and try again.',
      final status when status != null && status >= 500 =>
        'The server could not complete the request. Please try again later.',
      _ => 'The request could not be completed. Please try again.',
    };
  }

  static Map<String, Object?>? _asStringMap(Object? value) {
    if (value is! Map) return null;
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  static String? _nonEmptyString(Object? value) {
    final result = value?.toString().trim();
    return result == null || result.isEmpty ? null : result;
  }
}
