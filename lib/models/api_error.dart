import 'package:equatable/equatable.dart';

/// API error model
///
/// Standardized error model for API errors
class ApiError extends Equatable {
  const ApiError({
    required this.message,
    required this.code,
    this.errors,
    this.statusCode,
  });

  final String message;
  final String code;
  final Map<String, dynamic>? errors;
  final int? statusCode;

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      message: json['message'] ?? 'An error occurred',
      code: json['code'],
      errors: json['details'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'code': code,
      'errors': errors,
      'status_code': statusCode,
    };
  }

  @override
  List<Object?> get props => [message, code, errors, statusCode];
}
