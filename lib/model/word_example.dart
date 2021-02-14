// 🐦 Flutter imports:
import 'package:flutter/foundation.dart';

// 📦 Package imports:
import 'package:flamingo/flamingo.dart';

/// Represent a single example of word
class WordExample {
  final String example;
  final String meaning;
  final List<String> pinyin;
  final StorageFile audioMale;
  final StorageFile audioFemale;
  WordExample(
      {@required this.example,
        @required this.meaning,
        @required this.pinyin,
        @required this.audioMale,
        @required this.audioFemale});
}
