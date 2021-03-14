// 📦 Package imports:
import 'package:flamingo/flamingo.dart';
import 'package:flamingo_annotation/flamingo_annotation.dart';
import 'package:supercharged/supercharged.dart';

// 🌎 Project imports:
import 'word_example.dart';
import '../util/utility.dart';

part 'word_meaning.flamingo.dart';

const PINYIN_SEPARATOR = '-';

class WordMeaning extends Model {
  WordMeaning({
    this.meaning,
    List<String>? examples,
    List<String>? exampleMeanings,
    List<String>? examplePinyins,
    Map<String, dynamic>? values,
  })  : _examples = examples,
        _exampleMeanings = exampleMeanings,
        _examplePinyins = examplePinyins,
        super(values: values);

  @Field()
  String? meaning;

  @Field()
  // ignore: prefer_final_fields
  List<String>? _examples;

  @Field()
  // ignore: prefer_final_fields
  List<String>? _exampleMeanings;

  /// Pinyin for each examples, pinyin is separated by '-' like 'wo-men'
  @Field()
  // ignore: prefer_final_fields
  List<String>? _examplePinyins;

  /// Example ordinal : audio file
  @StorageField()
  // ignore: prefer_final_fields
  List<StorageFile>? exampleMaleAudios = [];

  /// Example ordinal : audio file
  @StorageField()
  // ignore: prefer_final_fields
  List<StorageFile>? exampleFemaleAudios = [];

  @Field()

  /// Start time of each hanzi in milliseconds
  List<List<int>>? exampleMaleAudioTimeSeries = [];

  @Field()

  /// Start time of each hanzi in milliseconds
  List<List<int>>? exampleFemaleAudioTimeSeries = [];

  List<WordExample> get examples {
    var examples = <WordExample>[];
    for (var i = 0; i < _examples!.length; i++) {
      examples.add(WordExample(
          example: _examples!.elementAtOrElse(i, () => ''),
          meaning: _exampleMeanings!.elementAtOrElse(i, () => ''),
          pinyin: _examplePinyins!.elementAtOrElse(i, () => '').split(PINYIN_SEPARATOR),
          audioMale: exampleMaleAudios![i],
          audioFemale: exampleFemaleAudios![i],
          audioMaleTimeSeries: [], //TODO: After we have this data => woexampleMaleAudioTimeSeries![i],
          audioFemaleTimeSeries: [])); //TODO: After we have this data => exampleFemaleAudioTimeSeries![i]));
    }
    return examples;
  }

  int get exampleCount => _examples!.length;

  WordMeaning copyWith(
          {String? meaning,
          List<String>? examples,
          List<String>? exampleMeanings,
          List<String>? examplePinyins}) =>
      WordMeaning(
          meaning: meaning ?? this.meaning!.substring(0),
          examples: examples ?? _examples!.copy,
          exampleMeanings: exampleMeanings ?? _exampleMeanings!.copy,
          examplePinyins: examplePinyins ?? _examplePinyins!.copy)
        ..exampleMaleAudios = exampleMaleAudios!.map((e) => e.copy()).toList()
        ..exampleFemaleAudios = exampleFemaleAudios!.map((e) => e.copy()).toList();

  @override
  Map<String, dynamic> toData() => _$toData(this);

  @override
  void fromData(Map<String, dynamic> data) => _$fromData(this, data);
}
