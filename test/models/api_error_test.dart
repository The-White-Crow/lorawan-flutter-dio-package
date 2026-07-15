import 'package:flutter_dio_package/flutter_dio_package.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses list details and request metadata safely', () {
    final error = ApiError.fromJson(
      const {
        'code': ApiResultCode.validationError,
        'message': 'Validation error',
        'details': ['phone_number is required'],
      },
      statusCode: ResponseCode.badRequest,
      requestId: 'request-123',
    );

    expect(error.code, ApiResultCode.validationError);
    expect(error.details, const ['phone_number is required']);
    expect(error.statusCode, ResponseCode.badRequest);
    expect(error.requestId, 'request-123');
  });

  test('supports the legacy errors constructor argument', () {
    const error = ApiError(
      code: 'LEGACY_ERROR',
      message: 'Legacy',
      errors: {'field': 'message'},
    );

    expect(error.details, const {'field': 'message'});
  });
}
