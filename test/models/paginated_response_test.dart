import 'package:flutter_dio_package/flutter_dio_package.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes a paginated response and its items', () {
    final response = PaginatedResponse<_User>.fromMap(
      {
        'success': true,
        'data': {
          'count': 1,
          'total': 11,
          'limit': 10,
          'offset': 0,
          'has_next': true,
          'has_prev': false,
          'total_pages': 2,
          'data': [
            {'id': 'user-1', 'name': 'Mobin'},
          ],
        },
        'metadata': {
          'request_id': 'request-1',
          'timestamp': '2026-07-16T07:43:18.955186Z',
        },
      },
      _User.fromMap,
    );

    expect(response.success, isTrue);
    expect(response.data.count, 1);
    expect(response.data.total, 11);
    expect(response.data.limit, 10);
    expect(response.data.offset, 0);
    expect(response.data.hasNext, isTrue);
    expect(response.data.hasPrev, isFalse);
    expect(response.data.totalPages, 2);
    expect(response.data.items, hasLength(1));
    expect(response.data.items.first.id, 'user-1');
    expect(response.data.items.first.name, 'Mobin');
    expect(response.metadata?.requestId, 'request-1');
  });

  test('decodes an empty page when the nested data list is absent', () {
    final response = PaginatedResponse<_User>.fromMap(
      {
        'success': true,
        'data': <String, dynamic>{},
      },
      _User.fromMap,
    );

    expect(response.data.items, isEmpty);
    expect(response.data.count, 0);
    expect(response.metadata, isNull);
  });
}

class _User {
  const _User({required this.id, required this.name});

  factory _User.fromMap(Map<String, dynamic> map) {
    return _User(
      id: map['id'] as String,
      name: map['name'] as String,
    );
  }

  final String id;
  final String name;
}
