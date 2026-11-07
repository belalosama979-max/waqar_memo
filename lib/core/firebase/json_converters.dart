import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

/// Converts Firestore [Timestamp]s (and ISO strings / millis in tests) to [DateTime].
class TimestampConverter implements JsonConverter<DateTime?, Object?> {
  const TimestampConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json == null) return null;
    if (json is Timestamp) return json.toDate();
    if (json is DateTime) return json;
    if (json is int) return DateTime.fromMillisecondsSinceEpoch(json);
    if (json is String) return DateTime.tryParse(json);
    return null;
  }

  @override
  Object? toJson(DateTime? date) => date == null ? null : Timestamp.fromDate(date);
}

/// Reads a Firestore document into a JSON map including its id.
Map<String, dynamic> docToJson(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data() ?? <String, dynamic>{};
  return {...data, 'id': doc.id};
}
