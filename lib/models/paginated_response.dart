import 'package:equatable/equatable.dart';
import 'package:flutter_dio_package/models/metadata.dart';

/// A standard API response whose data is paginated.
class PaginatedResponse<T> extends Equatable {
  const PaginatedResponse({
    required this.success,
    required this.data,
    this.metadata,
  });

  factory PaginatedResponse.fromMap(
    Map<String, dynamic> map,
    T Function(Map<String, dynamic>) itemFromMap,
  ) {
    return PaginatedResponse<T>(
      success: map['success'] as bool? ?? true,
      data: PaginatedData<T>.fromMap(
        map['data'] as Map<String, dynamic>,
        itemFromMap,
      ),
      metadata: map['metadata'] != null
          ? Metadata.fromMap(map['metadata'] as Map<String, dynamic>)
          : null,
    );
  }

  final bool success;
  final PaginatedData<T> data;
  final Metadata? metadata;

  Map<String, dynamic> toMap(
    Map<String, dynamic> Function(T) itemToMap,
  ) {
    return {
      'success': success,
      'data': data.toMap(itemToMap),
      'metadata': metadata?.toMap(),
    };
  }

  @override
  List<Object?> get props => [success, data, metadata];
}

/// Pagination information and the items returned for the current page.
class PaginatedData<T> extends Equatable {
  const PaginatedData({
    required this.count,
    required this.total,
    required this.limit,
    required this.offset,
    required this.hasNext,
    required this.hasPrev,
    required this.totalPages,
    required this.items,
  });

  factory PaginatedData.fromMap(
    Map<String, dynamic> map,
    T Function(Map<String, dynamic>) itemFromMap,
  ) {
    final rawItems = map['data'] as List<dynamic>? ?? const [];

    return PaginatedData<T>(
      count: map['count'] as int? ?? rawItems.length,
      total: map['total'] as int? ?? 0,
      limit: map['limit'] as int? ?? 0,
      offset: map['offset'] as int? ?? 0,
      hasNext: map['has_next'] as bool? ?? false,
      hasPrev: map['has_prev'] as bool? ?? false,
      totalPages: map['total_pages'] as int? ?? 0,
      items: rawItems
          .map((item) => itemFromMap(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final int count;
  final int total;
  final int limit;
  final int offset;
  final bool hasNext;
  final bool hasPrev;
  final int totalPages;

  /// Items stored under the nested API `data` key.
  final List<T> items;

  Map<String, dynamic> toMap(
    Map<String, dynamic> Function(T) itemToMap,
  ) {
    return {
      'count': count,
      'total': total,
      'limit': limit,
      'offset': offset,
      'has_next': hasNext,
      'has_prev': hasPrev,
      'total_pages': totalPages,
      'data': items.map(itemToMap).toList(growable: false),
    };
  }

  @override
  List<Object?> get props => [
    count,
    total,
    limit,
    offset,
    hasNext,
    hasPrev,
    totalPages,
    items,
  ];
}
