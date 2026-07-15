import 'dart:convert';

import 'package:equatable/equatable.dart';

class Metadata extends Equatable {
  const Metadata({
    required this.requestId,
    required this.timestamp,
  });

  factory Metadata.fromMap(Map<String, dynamic> map) {
    return Metadata(
      requestId: map['request_id'] as String? ?? '',
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  factory Metadata.fromJson(String source) => Metadata.fromMap(json.decode(source) as Map<String, dynamic>);

  final String requestId;
  final DateTime timestamp;

  Map<String, dynamic> toMap() {
    return {
      'request_id': requestId,
      'timestamp': timestamp,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  List<Object?> get props => [requestId, timestamp];
}
