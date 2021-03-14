// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_memo.dart';

// **************************************************************************
// FieldValueGenerator
// **************************************************************************

/// Field value key
enum UserMemoKey {
  title,
  content,
  relatedClassId,
  timestamp,
}

extension UserMemoKeyExtension on UserMemoKey {
  String get value {
    switch (this) {
      case UserMemoKey.title:
        return 'title';
      case UserMemoKey.content:
        return 'content';
      case UserMemoKey.relatedClassId:
        return 'relatedClassId';
      case UserMemoKey.timestamp:
        return 'timestamp';
      default:
        throw Exception('Invalid data key.');
    }
  }
}

/// For save data
Map<String, dynamic> _$toData(UserMemo doc) {
  final data = <String, dynamic>{};
  Helper.writeNotNull(data, 'title', doc.title);
  Helper.writeNotNull(data, 'content', doc.content);
  Helper.writeNotNull(data, 'relatedClassId', doc.relatedClassId);
  Helper.writeNotNull(data, 'timestamp', doc.timestamp);

  return data;
}

/// For load data
void _$fromData(UserMemo doc, Map<String, dynamic> data) {
  doc.title = Helper.valueFromKey<String>(data, 'title');
  doc.content = Helper.valueFromKey<String>(data, 'content');
  doc.relatedClassId = Helper.valueFromKey<String>(data, 'relatedClassId');
  if (data['timestamp'] is Map) {
    doc.timestamp = Helper.timestampFromMap(data, 'timestamp');
  } else {
    doc.timestamp = Helper.valueFromKey<Timestamp>(data, 'timestamp');
  }
}
