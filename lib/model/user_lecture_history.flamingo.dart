// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_lecture_history.dart';

// **************************************************************************
// FieldValueGenerator
// **************************************************************************

/// Field value key
enum LectureHistoryKey {
  lectureId,
  timestamp,
  isLatest,
}

extension LectureHistoryKeyExtension on LectureHistoryKey {
  String get value {
    switch (this) {
      case LectureHistoryKey.lectureId:
        return 'lectureId';
      case LectureHistoryKey.timestamp:
        return 'timestamp';
      case LectureHistoryKey.isLatest:
        return 'isLatest';
      default:
        return null;
    }
  }
}

/// For save data
Map<String, dynamic> _$toData(LectureHistory doc) {
  final data = <String, dynamic>{};
  Helper.writeNotNull(data, 'lectureId', doc.lectureId);
  Helper.writeNotNull(data, 'timestamp', doc.timestamp);
  Helper.writeNotNull(data, 'isLatest', doc.isLatest);

  return data;
}

/// For load data
void _$fromData(LectureHistory doc, Map<String, dynamic> data) {
  doc.lectureId = Helper.valueFromKey<String>(data, 'lectureId');
  if (data['timestamp'] is Map) {
    doc.timestamp = Helper.timestampFromMap(data, 'timestamp');
  } else {
    doc.timestamp = Helper.valueFromKey<Timestamp>(data, 'timestamp');
  }

  doc.isLatest = Helper.valueFromKey<bool>(data, 'isLatest');
}
