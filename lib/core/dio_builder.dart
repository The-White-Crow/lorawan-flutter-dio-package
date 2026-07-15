import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_core_package/flutter_core_package.dart';
import 'package:flutter_dio_package/handlers/error_handler.dart';
import 'package:flutter_dio_package/interceptors/error_interceptor.dart';
import 'package:flutter_dio_package/interceptors/jwt_interceptor.dart';
import 'package:flutter_dio_package/interceptors/logging_interceptor.dart';

/// A builder class for configuring Dio instances with predefined options.
///
/// Provides easy configuration for Dio with interceptors, authentication, and logging.
class DioBuilder {
  /// Creates a Dio instance with the specified options.
  ///
  /// [baseUrl] - Base URL for all requests (required)
  /// [hasToken] - Whether to include JWT authentication interceptor
  /// [storageService] - IStorageService for token storage (required if hasToken is true)
  /// [tokenGetter] - Callback function to get token (alternative to storageService)
  /// [enableLogging] - Whether to enable logging interceptor
  /// [enableErrorHandling] - Whether to enable error handling interceptor
  /// [queryParameters] - Default query parameters for requests
  /// [extra] - Extra options for requests
  /// [headers] - Custom headers for requests
  /// [responseType] - Expected response type (default: ResponseType.json)
  /// [contentType] - Content type for requests
  /// [connectTimeout] - Connection timeout (default: 60 seconds)
  /// [receiveTimeout] - Receive timeout (default: 60 seconds)
  /// [sendTimeout] - Send timeout (default: 60 seconds)
  /// [refreshTokenEndpoint] - Endpoint for refreshing tokens
  /// [refreshTokenCallback] - Callback function for refreshing tokens
  /// [loggingTag] - Tag for logging (default: 'Dio')
  /// [onErrorCallback] - Callback function called when an error occurs
  /// [errorMessageResolver] - Optional application-specific user message resolver
  /// [failureTypeResolver] - Optional application-specific FailureType resolver
  Dio getDio({
    required String baseUrl,
    bool hasToken = false,
    IStorageService? storageService,
    String? Function()? tokenGetter,
    bool enableLogging = false,
    bool enableErrorHandling = true,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extra,
    Map<String, dynamic>? headers,
    ResponseType responseType = ResponseType.json,
    String? contentType,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    String? refreshTokenEndpoint,
    Future<TokenPair?> Function(String refreshToken)? refreshTokenCallback,
    String loggingTag = 'Dio',
    void Function(Failure failure)? onErrorCallback,
    ApiErrorMessageResolver? errorMessageResolver,
    ApiFailureTypeResolver? failureTypeResolver,
  }) {
    // Validate token configuration
    if (hasToken && storageService == null && tokenGetter == null) {
      throw ArgumentError(
        'Either storageService or tokenGetter must be provided when hasToken is true',
      );
    }

    final dio = Dio()
      ..options = _getBaseOptions(
        baseUrl: baseUrl,
        queryParameters: queryParameters,
        contentType: contentType,
        extra: extra,
        headers: headers,
        responseType: responseType,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: sendTimeout,
      );

    // Add error handling interceptor first (if enabled)
    if (enableErrorHandling) {
      dio.interceptors.add(
        ErrorInterceptor(
          onErrorCallback: onErrorCallback,
          messageResolver: errorMessageResolver,
          failureTypeResolver: failureTypeResolver,
        ),
      );
    }

    // Add logging interceptor (if enabled)
    if (enableLogging) {
      dio.interceptors.add(
        LoggingInterceptor(
          tag: loggingTag,
          requestHeader: false,
          responseHeader: false,
        ),
      );
    }

    // Add JWT authentication interceptor (if enabled)
    if (hasToken) {
      dio.interceptors.add(
        JwtInterceptor(
          storageService: storageService,
          tokenGetter: tokenGetter,
          refreshTokenEndpoint: refreshTokenEndpoint,
          refreshTokenCallback: refreshTokenCallback,
          dio: dio,
        ),
      );
    }

    if (!kIsWeb) return dio;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Browsers cannot apply an upload timeout when there is no body to
          // upload. Dio's web adapter warns if a positive timeout reaches it.
          if (options.data == null) options.sendTimeout = Duration.zero;
          handler.next(options);
        },
      ),
    );

    return dio;
  }

  /// Helper method to get base options for the Dio instance
  BaseOptions _getBaseOptions({
    required String baseUrl,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extra,
    Map<String, dynamic>? headers,
    ResponseType responseType = ResponseType.json,
    String? contentType,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
  }) {
    const defaultTimeout = Duration(seconds: 60);

    return BaseOptions(
      baseUrl: baseUrl,
      contentType: contentType ?? Headers.jsonContentType,
      responseType: responseType,
      headers: headers ?? {'Content-Type': 'application/json', 'Accept': 'application/json'},
      extra: extra,
      queryParameters: queryParameters,
      connectTimeout: connectTimeout ?? defaultTimeout,
      receiveTimeout: receiveTimeout ?? defaultTimeout,
      sendTimeout: sendTimeout ?? defaultTimeout,
    );
  }
}
