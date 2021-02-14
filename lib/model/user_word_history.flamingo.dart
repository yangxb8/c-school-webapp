// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_word_history.dart';

// **************************************************************************
// FieldValueGenerator
// **************************************************************************

/// Field value key
enum WordHistoryKey {
  wordId,
  _wordMemoryStatus,
  timestamp,
  isLatest,
}

extension WordHistoryKeyExtension on WordHistoryKey {
  String get value {
    switch (this) {
      case WordHistoryKey.wordId:
        return 'wordId';
      case WordHistoryKey._wordMemoryStatus:
        return '_wordMemoryStatus';
      case WordHistoryKey.timestamp:
        return 'timestamp';
      case WordHistoryKey.isLatest:
        return 'isLatest';
      default:
        return null;
    }
  }
}

/// For save data
Map<String, dynamic> _$toData(WordHistory doc) {
  final data = <String, dynamic>{};
  Helper.writeNotNull(data, 'wordId', doc.wordId);
  Helper.writeNotNull(data, '_wordMemoryStatus', doc._wordMemoryStatus);
  Helper.writeNotNull(data, 'timestamp', doc.timestamp);
  Helper.writeNotNull(data, 'isLatest', doc.isLatest);

  return data;
}

/// For load data
void _$fromData(WordHistory doc, Map<String, dynamic> data) {
  doc.wordId = Helper.valueFromKey<String>(data, 'wordId');
  doc._wordMemoryStatus =
      Helper.valueFromKey<String>(data, '_wordMemoryStatus');
  if (data['timestamp'] is Map) {
    doc.timestamp = Helper.timestampFromMap(data, 'timestamp');
  } else {
    doc.timestamp = Helper.valueFromKey<Timestamp>(data, 'timestamp');
  }

  doc.isLatest = Helper.valueFromKey<bool>(data, 'isLatest');
}
