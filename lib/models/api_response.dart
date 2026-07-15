import 'package:equatable/equatable.dart';
import 'package:flutter_dio_package/flutter_dio_package.dart';
import 'package:flutter_dio_package/models/metadata.dart';

/// Standard API response model
///
/// Generic response model for API responses
class ApiResponse<T> extends Equatable {
  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.metadata,
  });

  factory ApiResponse.fromMap(
    Map<String, dynamic> map,
    T Function(Map<String, dynamic>)? fromMapT,
  ) {
    return ApiResponse<T>(
      success: map['success'] as bool? ?? true,
      data: map['data'] != null && fromMapT != null ? fromMapT(map['data'] as Map<String, dynamic>) : map['data'] as T?,
      error: map['error'] != null ? ApiError.fromJson(map['error'] as Map<String, dynamic>) : null,
      metadata: map['metadata'] != null ? Metadata.fromMap(map['metadata'] as Map<String, dynamic>) : null,
    );
  }

  factory ApiResponse.fromList(
    Map<String, dynamic> map,
    T Function(List<Map<String, dynamic>>) fromListT,
  ) {
    return ApiResponse<T>(
      success: map['success'] as bool? ?? true,
      data: map['data'] != null ? fromListT(map['data'] as List<Map<String, dynamic>>) : null,
      error: map['error'] != null ? ApiError.fromJson(map['error'] as Map<String, dynamic>) : null,
      metadata: map['metadata'] != null ? Metadata.fromMap(map['metadata'] as Map<String, dynamic>) : null,
    );
  }

  final bool success;
  final T? data;
  final ApiError? error;
  final Metadata? metadata;

  Map<String, dynamic> toMap(Map<String, dynamic> Function(T)? toMapT) {
    return {
      'success': success,
      'data': data != null && toMapT != null ? toMapT(data as T) : data,
      'error': error?.toJson(),
      'metadata': metadata?.toMap(),
    };
  }

  @override
  List<Object?> get props => [success, data, error, metadata];
}
