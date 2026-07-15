import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_core_package/flutter_core_package.dart';
import 'package:flutter_dio_package/flutter_dio_package.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'rejects a backend failure envelope even when HTTP status is 202',
    () async {
      final observedFailures = <Failure>[];
      final dio = _dioWithResponse(
        statusCode: ResponseCode.accepted,
        body: const {
          'success': false,
          'error': {
            'code': ApiResultCode.chirpstackSyncPending,
            'message': 'Synchronization is pending.',
          },
          'metadata': {
            'request_id': 'request-202',
            'timestamp': '2026-07-15T00:00:00Z',
          },
        },
        onFailure: observedFailures.add,
      );

      await expectLater(
        dio.get<void>('/device-profiles/sync'),
        throwsA(
          isA<DioException>().having(
            (error) => error.error,
            'normalized failure',
            isA<CustomFailure>()
                .having(
                  (failure) => failure.errorCode,
                  'code',
                  ApiResultCode.chirpstackSyncPending,
                )
                .having((failure) => failure.type, 'type', FailureType.popUp),
          ),
        ),
      );
      expect(observedFailures, hasLength(1));
    },
  );

  test('passes a successful 202 response through unchanged', () async {
    final dio = _dioWithResponse(
      statusCode: ResponseCode.accepted,
      body: const {
        'success': true,
        'data': {'queued': true},
      },
    );

    final response = await dio.get<Map<String, dynamic>>('/jobs');

    expect(response.statusCode, ResponseCode.accepted);
    expect(response.data?['success'], isTrue);
  });

  test('normalizes regular HTTP errors and notifies once', () async {
    final observedFailures = <Failure>[];
    final dio = _dioWithResponse(
      statusCode: ResponseCode.conflict,
      body: const {
        'success': false,
        'error': {
          'code': ApiResultCode.gatewayAlreadyOwned,
          'message': 'This gateway is already in your account.',
        },
      },
      validateStatus: (status) => status != null && status < 400,
      onFailure: observedFailures.add,
    );

    await expectLater(
      dio.post<void>('/gateways'),
      throwsA(
        isA<DioException>().having(
          (error) => error.error,
          'normalized failure',
          isA<CustomFailure>().having(
            (failure) => failure.type,
            'type',
            FailureType.popUp,
          ),
        ),
      ),
    );
    expect(observedFailures, hasLength(1));
  });
}

Dio _dioWithResponse({
  required int statusCode,
  required Map<String, Object?> body,
  ValidateStatus? validateStatus,
  void Function(Failure failure)? onFailure,
}) {
  final dio =
      Dio(
          BaseOptions(
            validateStatus: validateStatus ?? (_) => true,
          ),
        )
        ..httpClientAdapter = _JsonAdapter(statusCode: statusCode, body: body)
        ..interceptors.add(ErrorInterceptor(onErrorCallback: onFailure));
  return dio;
}

class _JsonAdapter implements HttpClientAdapter {
  const _JsonAdapter({required this.statusCode, required this.body});

  final int statusCode;
  final Map<String, Object?> body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
