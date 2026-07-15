import 'package:equatable/equatable.dart';

/// API error model
///
/// Standardized error model for API errors
class ApiError extends Equatable {
  const ApiError({
    required this.message,
    required this.code,
    Object? details,
    Object? errors,
    this.statusCode,
    this.requestId,
  }) : details = details ?? errors;

  factory ApiError.fromJson(
    Map<String, dynamic> json, {
    int? statusCode,
    String? requestId,
  }) {
    return ApiError(
      message:
          _readNonEmptyString(json['message']) ??
          'The request could not be completed.',
      code: _readNonEmptyString(json['code']) ?? 'UNKNOWN_ERROR',
      details: json['details'],
      statusCode: _readInt(json['status_code']) ?? statusCode,
      requestId: _readNonEmptyString(json['request_id']) ?? requestId,
    );
  }

  final String message;
  final String code;

  /// Optional backend validation or diagnostic details.
  ///
  /// The backend declares this value as `any`; validation errors currently
  /// return a `List<String>`, while other endpoints may return an object.
  final Object? details;

  /// HTTP status associated with this API error.
  final int? statusCode;

  /// Request identifier returned in the response metadata.
  final String? requestId;

  /// Backward-compatible alias for the old API.
  @Deprecated('Use details instead.')
  Object? get errors => details;

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'code': code,
      'details': details,
      'status_code': statusCode,
      'request_id': requestId,
    };
  }

  @override
  List<Object?> get props => [message, code, details, statusCode, requestId];

  static String? _readNonEmptyString(Object? value) {
    final result = value?.toString().trim();
    return result == null || result.isEmpty ? null : result;
  }

  static int? _readInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}
