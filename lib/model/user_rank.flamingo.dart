// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_rank.dart';

// **************************************************************************
// FieldValueGenerator
// **************************************************************************

/// Field value key
enum UserRankKey {
  rank,
  timestamp,
}

extension UserRankKeyExtension on UserRankKey {
  String get value {
    switch (this) {
      case UserRankKey.rank:
        return 'rank';
      case UserRankKey.timestamp:
        return 'timestamp';
      default:
        return null;
    }
  }
}

/// For save data
Map<String, dynamic> _$toData(UserRank doc) {
  final data = <String, dynamic>{};
  Helper.writeNotNull(data, 'rank', doc.rank);
  Helper.writeNotNull(data, 'timestamp', doc.timestamp);

  return data;
}

/// For load data
void _$fromData(UserRank doc, Map<String, dynamic> data) {
  doc.rank = Helper.valueFromKey<int>(data, 'rank');
  if (data['timestamp'] is Map) {
    doc.timestamp = Helper.timestampFromMap(data, 'timestamp');
  } else {
    doc.timestamp = Helper.valueFromKey<Timestamp>(data, 'timestamp');
  }
}
