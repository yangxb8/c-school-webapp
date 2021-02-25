// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:flamingo/flamingo.dart';
import 'package:flamingo_annotation/flamingo_annotation.dart';
import 'package:supercharged/supercharged.dart';

// Project imports:
import 'word_example.dart';

part 'word_meaning.flamingo.dart';

const PINYIN_SEPARATOR = '-';

class WordMeaning extends Model {
  WordMeaning({
    @required this.meaning,
    @required List<String> examples,
    @required List<String> exampleMeanings,
    @required List<String> examplePinyins,
    Map<String, dynamic> values,
  })  : _examples = examples,
        _exampleMeanings = exampleMeanings,
        _examplePinyins = examplePinyins,
        super(values: values);

  @Field()
  String meaning;

  @Field()
  // ignore: prefer_final_fields
  List<String> _examples;

  @Field()
  // ignore: prefer_final_fields
  List<String> _exampleMeanings;

  @Field()

  /// Pinyin for each examples, pinyin is separated by '-' like 'wo-men'
  // ignore: prefer_final_fields
  List<String> _examplePinyins;

  /// Example ordinal : audio file
  @StorageField()
  // ignore: prefer_final_fields
  List<StorageFile> exampleMaleAudios = [];

  /// Example ordinal : audio file
  @StorageField()
  // ignore: prefer_final_fields
  List<StorageFile> exampleFemaleAudios = [];

  List<WordExample> get examples {
    var examples = <WordExample>[];
    for (var i = 0; i < _examples.length; i++) {
      examples.add(WordExample(
          example: _examples.elementAtOrElse(i, () => ''),
          meaning: _exampleMeanings.elementAtOrElse(i, () => ''),
          pinyin: _examplePinyins.elementAtOrElse(i,()=>'').split(PINYIN_SEPARATOR),
          audioMale: exampleMaleAudios.elementAtOrNull(i),
          audioFemale: exampleFemaleAudios.elementAtOrNull(i)));
    }
    return examples;
  }

  int get exampleCount => _examples.length;

  @override
  Map<String, dynamic> toData() => _$toData(this);

  @override
  void fromData(Map<String, dynamic> data) => _$fromData(this, data);
}
