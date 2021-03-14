// 📦 Package imports:
import 'package:flamingo/flamingo.dart';

/// Represent a single example of word
class WordExample {
  final String example;
  final String meaning;
  final List<String> pinyin;
  final StorageFile audioMale;
  final StorageFile audioFemale;
  /// Start time of each hanzi in milliseconds
  final List<int> audioMaleTimeSeries;
  /// Start time of each hanzi in milliseconds
  final List<int> audioFemaleTimeSeries;

  WordExample(
      {required this.example,
        required this.meaning,
        required this.pinyin,
        required this.audioMale,
        required this.audioFemale,
        required this.audioMaleTimeSeries,
        required this.audioFemaleTimeSeries,});
}
