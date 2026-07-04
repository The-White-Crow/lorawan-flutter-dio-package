import 'package:flutter_core_package/flutter_core_package.dart';
import 'package:dio/dio.dart';

/// Logging interceptor for Dio
///
/// Uses Log extension from flutter_core_package for logging requests and responses
class LoggingInterceptor extends Interceptor {
  /// Creates a LoggingInterceptor
  ///
  /// [request] - Print request information
  /// [requestHeader] - Print request headers
  /// [requestBody] - Print request body
  /// [responseHeader] - Print response headers
  /// [responseBody] - Print response body
  /// [error] - Print error information
  /// [tag] - Tag for logging (default: 'Dio')
  LoggingInterceptor({
    this.request = true,
    this.requestHeader = true,
    this.requestBody = false,
    this.responseHeader = true,
    this.responseBody = false,
    this.error = true,
    this.tag = 'Dio',
  });

  /// Print request [Options]
  final bool request;

  /// Print request header [Options.headers]
  final bool requestHeader;

  /// Print request data [Options.data]
  final bool requestBody;

  /// Print [Response.headers]
  final bool responseHeader;

  /// Print [Response.data]
  final bool responseBody;

  /// Print error message
  final bool error;

  /// Tag for logging
  final String tag;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    '*** DioRequest ***'.log(tag: tag, level: LogLevel.debug);
    'uri: ${options.uri}'.log(tag: tag, level: LogLevel.debug);

    if (request) {
      'method: ${options.method}'.log(tag: tag, level: LogLevel.debug);
      'responseType: ${options.responseType.toString()}'.log(tag: tag, level: LogLevel.debug);
      'followRedirects: ${options.followRedirects}'.log(tag: tag, level: LogLevel.debug);
      'connectTimeout: ${options.connectTimeout?.inSeconds ?? 0}'.log(tag: tag, level: LogLevel.debug);
      'receiveTimeout: ${options.receiveTimeout?.inSeconds ?? 0}'.log(tag: tag, level: LogLevel.debug);
      'extra: ${options.extra}'.log(tag: tag, level: LogLevel.debug);
    }

    if (requestHeader) {
      'Headers:'.log(tag: tag, level: LogLevel.debug);
      options.headers.forEach((k, v) => '$k: $v'.log(tag: tag, level: LogLevel.debug));
    }

    if (requestBody && options.data != null) {
      'Body:'.log(tag: tag, level: LogLevel.debug);
      options.data.toString().log(tag: tag, level: LogLevel.debug);
    }

    ''.log(tag: tag, level: LogLevel.debug);
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    '*** DioResponse ***'.log(tag: tag, level: LogLevel.debug);
    'uri: ${response.requestOptions.uri}'.log(tag: tag, level: LogLevel.debug);

    if (responseHeader) {
      'statusCode: ${response.statusCode ?? 0}'.log(tag: tag, level: LogLevel.debug);
      if (response.isRedirect) {
        'redirect: ${response.realUri}'.log(tag: tag, level: LogLevel.debug);
      }
      'Headers:'.log(tag: tag, level: LogLevel.debug);
      response.headers.forEach((k, v) => '$k: $v'.log(tag: tag, level: LogLevel.debug));
    }

    if (responseBody) {
      'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}'.log(tag: tag, level: LogLevel.debug);
      'Body: ${response.data}'.log(tag: tag, level: LogLevel.debug);
    }

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (error) {
      '*** DioError ***'.log(tag: tag, level: LogLevel.error);
      'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}'.log(tag: tag, level: LogLevel.error);
      if (err.response != null) {
        'Body: ${err.response?.data}'.log(tag: tag, level: LogLevel.error);
      }
      ''.log(tag: tag, level: LogLevel.error);
    }
    return super.onError(err, handler);
  }
}
