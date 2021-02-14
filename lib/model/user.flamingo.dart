// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// FieldValueGenerator
// **************************************************************************

/// Field value key
enum AppUserKey {
  nickName,
  _membershipTypes,
  membershipEndAt,
  likedLectures,
  likedWords,
  rankHistory,
  reviewedClassHistory,
  reviewedWordHistory,
  userMemos,
}

extension AppUserKeyExtension on AppUserKey {
  String get value {
    switch (this) {
      case AppUserKey.nickName:
        return 'nickName';
      case AppUserKey._membershipTypes:
        return '_membershipTypes';
      case AppUserKey.membershipEndAt:
        return 'membershipEndAt';
      case AppUserKey.likedLectures:
        return 'likedLectures';
      case AppUserKey.likedWords:
        return 'likedWords';
      case AppUserKey.rankHistory:
        return 'rankHistory';
      case AppUserKey.reviewedClassHistory:
        return 'reviewedClassHistory';
      case AppUserKey.reviewedWordHistory:
        return 'reviewedWordHistory';
      case AppUserKey.userMemos:
        return 'userMemos';
      default:
        return null;
    }
  }
}

/// For save data
Map<String, dynamic> _$toData(AppUser doc) {
  final data = <String, dynamic>{};
  Helper.writeNotNull(data, 'nickName', doc.nickName);
  Helper.writeNotNull(data, '_membershipTypes', doc._membershipTypes);
  Helper.writeNotNull(data, 'membershipEndAt', doc.membershipEndAt);
  Helper.writeNotNull(data, 'likedLectures', doc.likedLectures);
  Helper.writeNotNull(data, 'likedWords', doc.likedWords);

  Helper.writeModelListNotNull(data, 'rankHistory', doc.rankHistory);
  Helper.writeModelListNotNull(
      data, 'reviewedClassHistory', doc.reviewedClassHistory);
  Helper.writeModelListNotNull(
      data, 'reviewedWordHistory', doc.reviewedWordHistory);
  Helper.writeModelListNotNull(data, 'userMemos', doc.userMemos);

  return data;
}

/// For load data
void _$fromData(AppUser doc, Map<String, dynamic> data) {
  doc.nickName = Helper.valueFromKey<String>(data, 'nickName');
  doc._membershipTypes =
      Helper.valueListFromKey<String>(data, '_membershipTypes');
  if (data['membershipEndAt'] is Map) {
    doc.membershipEndAt = Helper.timestampFromMap(data, 'membershipEndAt');
  } else {
    doc.membershipEndAt =
        Helper.valueFromKey<Timestamp>(data, 'membershipEndAt');
  }

  doc.likedLectures = Helper.valueListFromKey<String>(data, 'likedLectures');
  doc.likedWords = Helper.valueListFromKey<String>(data, 'likedWords');

  final _rankHistory =
      Helper.valueMapListFromKey<String, dynamic>(data, 'rankHistory');
  if (_rankHistory != null) {
    doc.rankHistory = _rankHistory
        .where((d) => d != null)
        .map((d) => UserRank(values: d))
        .toList();
  } else {
    doc.rankHistory = null;
  }

  final _reviewedClassHistory =
      Helper.valueMapListFromKey<String, dynamic>(data, 'reviewedClassHistory');
  if (_reviewedClassHistory != null) {
    doc.reviewedClassHistory = _reviewedClassHistory
        .where((d) => d != null)
        .map((d) => LectureHistory(values: d))
        .toList();
  } else {
    doc.reviewedClassHistory = null;
  }

  final _reviewedWordHistory =
      Helper.valueMapListFromKey<String, dynamic>(data, 'reviewedWordHistory');
  if (_reviewedWordHistory != null) {
    doc.reviewedWordHistory = _reviewedWordHistory
        .where((d) => d != null)
        .map((d) => WordHistory(values: d))
        .toList();
  } else {
    doc.reviewedWordHistory = null;
  }

  final _userMemos =
      Helper.valueMapListFromKey<String, dynamic>(data, 'userMemos');
  if (_userMemos != null) {
    doc.userMemos = _userMemos
        .where((d) => d != null)
        .map((d) => UserMemo(values: d))
        .toList();
  } else {
    doc.userMemos = null;
  }
}
