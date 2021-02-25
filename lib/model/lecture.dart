// Package imports:
import 'package:flamingo/flamingo.dart';
import 'package:flamingo_annotation/flamingo_annotation.dart';
import 'package:get/get.dart';

// Project imports:
import 'package:cschool_webapp/model/updatable.dart';
import '../service/lecture_service.dart';
import '../util/utility.dart';
import 'exam_base.dart';
import 'searchable.dart';
import 'word.dart';

part 'lecture.flamingo.dart';

class Lecture extends Document<Lecture> with UpdatableDocument<Lecture> implements Searchable {
  static const levelPrefix = 'Level';
  static LectureService lectureService = Get.find<LectureService>();

  Lecture({
    String id,
    int level = 0,
    DocumentSnapshot snapshot,
    Map<String, dynamic> values,
  })  : lectureId = id,
        level = level,
        tags = id == null ? [] : ['$levelPrefix$level'],
        super(id: id, snapshot: snapshot, values: values);

  @Field()
  String lectureId;

  /// For display
  @Field()
  int level = 0;

  @Field()
  String title = '';

  @Field()
  String description = '';

  /// Converted from ClassTag enum
  @Field()
  List<String> tags = [];

  /// Hash of lecture pic for display by blurhash
  @Field()
  String picHash = '';

  /// If the lecture has pic in cloud storage
  @StorageField()
  StorageFile pic;

  /// find words related
  List<Word> get words => lectureService.findWordsByTags([lectureId]);

  /// find exams related
  List<Exam> get exams => lectureService.findExamsByTags([lectureId]);

  String get levelForDisplay => '$levelPrefix$level';

  /// 'C0001' => 1
  int get intLectureId => int.parse(lectureId.numericOnly());

  @override
  Map<String, dynamic> toData() => _$toData(this);

  @override
  void fromData(Map<String, dynamic> data) => _$fromData(this, data);

  @override
  Map<String, dynamic> get searchableProperties => {
        'title': title,
        'lectureId': lectureId,
        'description': description,
        'level': level.toString(),
        'tags': tags,
      };

  @override
  Map<String, dynamic> get properties => {
        'title': title,
        'id': id,
        'description': description,
        'level': level,
        'tags': tags,
        'pic': pic,
        'picHash': picHash
      };

  @override
  Lecture copyWith({String id, int level, String title, String description, List<String> tags}) {
    final tagsCopy = <String>[];
    this.tags.forEach((t) => tagsCopy.add('$t'));
    return Lecture(id: id ?? this.id, level: level ?? this.level)
      ..title = title ?? this.title
      ..description = description ?? this.description
      ..tags = tags ?? tagsCopy
      ..pic = pic?.copy() // If not image or new row, this will be null
      ..picHash = picHash.substring(0); // Copy
  }

  @override
  String generateIdFromIndex(int index) => 'C${index.toString().padLeft(4, '0')}';

  @override
  int get indexOfId => int.parse(id.substring(1));

  @override
  bool equalsTo(Lecture other) =>
      id == other.id &&
      level == other.level &&
      title == other.title &&
      description == other.description &&
      tags.every((element) => other.tags.contains(element)) &&
      picHash == other.picHash;
}
