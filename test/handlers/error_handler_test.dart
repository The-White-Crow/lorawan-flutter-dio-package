import 'package:dio/dio.dart';
import 'package:flutter_core_package/flutter_core_package.dart';
import 'package:flutter_dio_package/flutter_dio_package.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DioErrorHandler backend mapping', () {
    test('maps validation errors to inline validation failures', () {
      final failure = DioErrorHandler.handleResponse(
        _errorResponse(
          statusCode: ResponseCode.badRequest,
          code: ApiResultCode.validationError,
          message: 'Validation error',
          details: const [
            'Phone number is required',
            'Phone number format is invalid',
          ],
        ),
      );

      expect(failure, isA<CustomFailure>());
      expect(failure.tag, FailureTag.validation);
      expect(failure.type, FailureType.inline);
      expect(failure.errorCode, ApiResultCode.validationError);
      expect(
        failure.message,
        'Phone number is required\nPhone number format is invalid',
      );
    });

    test('maps token expiration to a silent authentication failure', () {
      final failure = DioErrorHandler.handleResponse(
        _errorResponse(
          statusCode: ResponseCode.unauthorized,
          code: ApiResultCode.tokenExpired,
          message: 'Your session has expired.',
        ),
      );

      expect(failure.tag, FailureTag.authentication);
      expect(failure.type, FailureType.silent);
    });

    test('maps account suspension to a full-page authorization failure', () {
      final failure = DioErrorHandler.handleResponse(
        _errorResponse(
          statusCode: ResponseCode.forbidden,
          code: ApiResultCode.accountSuspended,
          message: 'Your account has been suspended.',
        ),
      );

      expect(failure.tag, FailureTag.authorization);
      expect(failure.type, FailureType.fullPage);
    });

    test('uses request method to size not-found failures', () {
      final getFailure = DioErrorHandler.handleResponse(
        _errorResponse(
          statusCode: ResponseCode.notFound,
          code: ApiResultCode.gatewayNotFound,
          method: 'GET',
        ),
      );
      final deleteFailure = DioErrorHandler.handleResponse(
        _errorResponse(
          statusCode: ResponseCode.notFound,
          code: ApiResultCode.gatewayNotFound,
          method: 'DELETE',
        ),
      );

      expect(getFailure.type, FailureType.fullPage);
      expect(deleteFailure.type, FailureType.popUp);
    });

    test('maps conflicts and rate limits to popup failures', () {
      final conflict = DioErrorHandler.handleResponse(
        _errorResponse(
          statusCode: ResponseCode.conflict,
          code: ApiResultCode.profileInUse,
        ),
      );
      final rateLimit = DioErrorHandler.handleResponse(
        _errorResponse(
          statusCode: ResponseCode.tooManyRequests,
          code: ApiResultCode.otpRateLimited,
        ),
      );

      expect(conflict.type, FailureType.popUp);
      expect(rateLimit.type, FailureType.popUp);
    });

    test('maps server errors to ServerFailure sized by request method', () {
      final getFailure = DioErrorHandler.handleResponse(
        _errorResponse(
          statusCode: ResponseCode.internalServerError,
          code: ApiResultCode.gatewayUpdateFailed,
          method: 'GET',
        ),
      );
      final postFailure = DioErrorHandler.handleResponse(
        _errorResponse(
          statusCode: ResponseCode.internalServerError,
          code: ApiResultCode.gatewayUpdateFailed,
        ),
      );

      expect(getFailure, isA<ServerFailure>());
      expect(getFailure.type, FailureType.fullPage);
      expect(postFailure, isA<ServerFailure>());
      expect(postFailure.type, FailureType.popUp);
    });

    test('allows per-request FailureType overrides', () {
      final failure = DioErrorHandler.handleResponse(
        _errorResponse(
          statusCode: ResponseCode.notFound,
          code: ApiResultCode.deviceNotFound,
          extra: const {
            DioErrorHandler.failureTypeExtraKey: FailureType.inline,
          },
        ),
      );

      expect(failure.type, FailureType.inline);
    });

    test('allows application-specific message localization', () {
      final failure = DioErrorHandler.handleResponse(
        _errorResponse(
          statusCode: ResponseCode.conflict,
          code: ApiResultCode.dashboardNameTaken,
        ),
        messageResolver: (error) => 'localized:${error.code}',
      );

      expect(failure.message, 'localized:DASHBOARD_NAME_TAKEN');
    });
  });

  group('DioErrorHandler transport mapping', () {
    test('maps read timeouts to full-page NetworkFailure', () {
      final request = RequestOptions(path: '/gateways', method: 'GET');
      final failure = DioErrorHandler.handle(
        DioException.receiveTimeout(
          timeout: const Duration(seconds: 10),
          requestOptions: request,
        ),
      );

      expect(failure, isA<NetworkFailure>());
      expect(failure.type, FailureType.fullPage);
    });

    test('maps mutation timeouts to popup NetworkFailure', () {
      final request = RequestOptions(path: '/gateways', method: 'POST');
      final failure = DioErrorHandler.handle(
        DioException.sendTimeout(
          timeout: const Duration(seconds: 10),
          requestOptions: request,
        ),
      );

      expect(failure, isA<NetworkFailure>());
      expect(failure.type, FailureType.popUp);
    });

    test('maps cancelled requests to silent failures', () {
      final failure = DioErrorHandler.handle(
        DioException.requestCancelled(
          requestOptions: RequestOptions(path: '/devices'),
          reason: 'test',
        ),
      );

      expect(failure.type, FailureType.silent);
    });

    test('handles transform timeout without throwing UnimplementedError', () {
      final failure = DioErrorHandler.handle(
        DioException.transformTimeout(
          timeout: const Duration(seconds: 10),
          requestOptions: RequestOptions(path: '/devices', method: 'GET'),
        ),
      );

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.type, FailureType.fullPage);
    });
  });
}

Response<dynamic> _errorResponse({
  required int statusCode,
  required String code,
  String message = 'Client-safe backend message',
  String method = 'POST',
  Object? details,
  Map<String, dynamic>? extra,
}) {
  return Response<dynamic>(
    statusCode: statusCode,
    requestOptions: RequestOptions(
      path: '/test',
      method: method,
      extra: extra,
    ),
    data: {
      'success': false,
      'error': {
        'code': code,
        'message': message,
        if (details != null) 'details': details,
      },
      'metadata': {
        'request_id': 'request-123',
        'timestamp': '2026-07-15T00:00:00Z',
      },
    },
  );
}
