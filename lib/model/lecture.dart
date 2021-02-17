// 📦 Package imports:
import 'package:flamingo/flamingo.dart';
import 'package:flamingo_annotation/flamingo_annotation.dart';
import 'package:get/get.dart';

// 🌎 Project imports:
import 'searchable.dart';
import 'word.dart';
import '../service/lecture_service.dart';
import 'exam_base.dart';

part 'lecture.flamingo.dart';

class Lecture extends Document<Lecture> implements Searchable{
  static const levelPrefix = 'Level';
  static LectureService lectureService = Get.find<LectureService>();

  Lecture({
    String id,
    int level,
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
    'description':  description,
    'level': level.toString(),
    'tags': tags,
  };

}
