// Package imports:
import 'package:flamingo/flamingo.dart';
import 'package:flamingo_annotation/flamingo_annotation.dart';
import 'package:get/get.dart';

// Project imports:
import 'package:cschool_webapp/model/updatable.dart';
import '../service/lecture_service.dart';
import 'lecture.dart';
import 'searchable.dart';
import 'word_meaning.dart';

part 'word.flamingo.dart';

/// id is used as primary key for any word
class Word extends Document<Word> with UpdatableDocument<Word> implements Searchable{
  static LectureService lectureService = Get.find<LectureService>();

  Word({
    String id,
    DocumentSnapshot snapshot,
    Map<String, dynamic> values,
  })  : wordId = id,
        tags =
            id == null ? [] : [id.split('-').first], // Assign lectureId to tags
        super(id: id, snapshot: snapshot, values: values);

  @Field()
  String wordId;

  /// Example: [['我'],[们]]
  @Field()
  List<String> word = [];

  /// Example: [['wo'],['men']]
  @Field()
  List<String> pinyin = [];

  /// Usage and other information about this word
  @Field()
  String explanation = '';

  @Field()
  String partOfSentence = '';

  @Field()
  String hint = '';

  /// 日语意思
  @ModelField()
  List<WordMeaning> wordMeanings = [];

  /// related word in examples
  @Field()
  List<String> _relatedWordIds = [];

  /// Same word but with different meanings
  @Field()
  List<String> _otherMeaningIds = [];

  /// 拆字
  @Field()
  List<String> breakdowns = [];

  /// Converted from WordTag enum
  @Field()
  List<String> tags = [];

  /// Hash of word pic for display by blurhash
  @Field()
  String picHash = '';

  /// If the word has pic in cloud storage
  @StorageField()
  StorageFile pic;

  /// If the word has wordAudio in cloud storage
  @StorageField()
  StorageFile wordAudioMale;

  @StorageField()
  StorageFile wordAudioFemale;

  List<Word> get relatedWords {
    if (_relatedWordIds.isBlank) {
      return [];
    } else {
      return lectureService.findWordsByIds(_relatedWordIds);
    }
  }

  set relatedWordIDs(List<String> relatedWordIDs) =>
      _relatedWordIds = relatedWordIDs;

  List<Word> get otherMeanings {
    if (_otherMeaningIds.isBlank) {
      return [];
    } else {
      return lectureService.findWordsByIds(_otherMeaningIds);
    }
  }

  set otherMeaningIds(List<String> otherMeaningIds) =>
      _otherMeaningIds = otherMeaningIds;

  Lecture get lecture => lectureService.findLectureById(lectureId);

  String get lectureId => id.split('-').first;

  String get wordAsString => word.join();

  @override
  Map<String, dynamic> toData() => _$toData(this);

  @override
  void fromData(Map<String, dynamic> data) => _$fromData(this, data);

  @override
  Map<String, dynamic> get searchableProperties => {
    'wordAsString': wordAsString,
    'pinyin':pinyin,
    'wordMeanings': wordMeanings.map((m) => m.meaning),
    'tags':tags
  };

  @override
  Word copyWith({String id}) {
    // TODO: implement copyWith
    throw UnimplementedError();
  }

  @override
  String generateIdFromIndex(int index) => '$lectureId-${index.toString().padLeft(3,'0')}';

  @override
  int get indexOfId => int.parse(id.split('-')[1]);

  @override
  // TODO: implement properties
  Map<String, dynamic> get properties => throw UnimplementedError();

  @override
  bool equalsTo(Word other) {
    // TODO: implement equalsTo
    throw UnimplementedError();
  }
}

enum WordMemoryStatus { REMEMBERED, NORMAL, FORGOT, NOT_REVIEWED }
