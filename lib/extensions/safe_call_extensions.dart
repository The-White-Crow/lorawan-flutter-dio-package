import 'package:flutter_core_package/flutter_core_package.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../core/request_type.dart';
import '../handlers/error_handler.dart';
import '../models/response_code.dart';

/// Extension methods for Dio to perform safe HTTP calls
///
/// Returns Either<Failure, T> where Failure is from core_package
extension SafeCallExtensions on Dio {
  /// A method to perform a safe HTTP call using Dio, handling success and errors.
  ///
  /// Either a [mapper] for single object or a [listMapper] for a list must be provided.
  ///
  /// Returns [Either<Failure, T>] where Failure is from core_package
  Future<Either<Failure, T>> safeCall<T>(
    String endPoint, {
    dynamic data,
    RequestType method = RequestType.GET,
    T Function(Map<String, dynamic>)? mapper,
    T Function(List<dynamic>)? listMapper,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    Options? options,
  }) async {
    // Ensure that either mapper or listMapper is provided
    assert((mapper != null) || (listMapper != null), 'Either mapper or listMapper must be provided');

    try {
      // Perform the HTTP request
      Response response = await fetch(
        RequestOptions(
          baseUrl: this.options.baseUrl,
          contentType: this.options.contentType,
          connectTimeout: this.options.connectTimeout,
          receiveTimeout: this.options.receiveTimeout,
          sendTimeout: this.options.sendTimeout,
          headers: {...this.options.headers, if (options != null && options.headers != null) ...options.headers!},
          method: method.stringValue,
          path: endPoint,
          data: data,
          queryParameters: queryParameters,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress,
          extra: options?.extra ?? this.options.extra,
          responseType: options?.responseType ?? this.options.responseType,
          validateStatus: options?.validateStatus ?? this.options.validateStatus,
        ),
      );

      // Handle success response
      if (response.statusCode == ResponseCode.success || response.statusCode == ResponseCode.created) {
        if (mapper != null) {
          // Use mapper for single object
          if (response.data is Map<String, dynamic>) {
            return Right(mapper(response.data as Map<String, dynamic>));
          } else {
            // If response is not a map, try to convert
            return Right(mapper({'data': response.data}));
          }
        }
        // Use listMapper for list of objects
        if (response.data is List) {
          return Right(listMapper!(response.data as List<dynamic>));
        } else {
          // If response is not a list, wrap it
          return Right(listMapper!([response.data]));
        }
      }

      // Handle error response
      return Left(
        DioErrorHandler.handle(
          DioException(requestOptions: response.requestOptions, response: response, type: DioExceptionType.badResponse),
        ),
      );
    } catch (exception) {
      // Handle exception
      return Left(DioErrorHandler.handle(exception));
    }
  }
}
