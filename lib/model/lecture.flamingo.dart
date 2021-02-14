// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lecture.dart';

// **************************************************************************
// FieldValueGenerator
// **************************************************************************

/// Field value key
enum LectureKey {
  lectureId,
  level,
  title,
  description,
  tags,
  picHash,

  pic,
}

extension LectureKeyExtension on LectureKey {
  String get value {
    switch (this) {
      case LectureKey.lectureId:
        return 'lectureId';
      case LectureKey.level:
        return 'level';
      case LectureKey.title:
        return 'title';
      case LectureKey.description:
        return 'description';
      case LectureKey.tags:
        return 'tags';
      case LectureKey.picHash:
        return 'picHash';
      case LectureKey.pic:
        return 'pic';
      default:
        return null;
    }
  }
}

/// For save data
Map<String, dynamic> _$toData(Lecture doc) {
  final data = <String, dynamic>{};
  Helper.writeNotNull(data, 'lectureId', doc.lectureId);
  Helper.writeNotNull(data, 'level', doc.level);
  Helper.writeNotNull(data, 'title', doc.title);
  Helper.writeNotNull(data, 'description', doc.description);
  Helper.writeNotNull(data, 'tags', doc.tags);
  Helper.writeNotNull(data, 'picHash', doc.picHash);

  Helper.writeStorageNotNull(data, 'pic', doc.pic, isSetNull: true);

  return data;
}

/// For load data
void _$fromData(Lecture doc, Map<String, dynamic> data) {
  doc.lectureId = Helper.valueFromKey<String>(data, 'lectureId');
  doc.level = Helper.valueFromKey<int>(data, 'level');
  doc.title = Helper.valueFromKey<String>(data, 'title');
  doc.description = Helper.valueFromKey<String>(data, 'description');
  doc.tags = Helper.valueListFromKey<String>(data, 'tags');
  doc.picHash = Helper.valueFromKey<String>(data, 'picHash');

  doc.pic = Helper.storageFile(data, 'pic');
}
