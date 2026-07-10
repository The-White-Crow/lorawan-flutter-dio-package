import 'dart:convert';

import 'package:equatable/equatable.dart';

class Metadata extends Equatable {
  const Metadata({
    required this.requestId,
    required this.timestamp,
  });

  final String requestId;
  final DateTime timestamp;

  Map<String, dynamic> toMap() {
    return {
      'request_id': requestId,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory Metadata.fromMap(Map<String, dynamic> map) {
    return Metadata(
      requestId: map['request_id'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Metadata.fromJson(String source) => Metadata.fromMap(json.decode(source));

  @override
  List<Object?> get props => [requestId, timestamp];
}
