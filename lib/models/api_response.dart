import 'package:equatable/equatable.dart';

/// Standard API response model
///
/// Generic response model for API responses
class ApiResponse<T> extends Equatable {
  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errors,
  });

  final bool success;
  final T? data;
  final String? message;
  final List<String>? errors;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? true,
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : json['data'] as T?,
      message: json['message'],
      errors: json['errors'] != null ? List<String>.from(json['errors']) : null,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T)? toJsonT) {
    return {
      'success': success,
      'data': data != null && toJsonT != null ? toJsonT(data as T) : data,
      'message': message,
      'errors': errors,
    };
  }

  @override
  List<Object?> get props => [success, data, message, errors];
}
