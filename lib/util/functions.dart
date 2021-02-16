// 🎯 Dart imports:
import 'dart:io';

// 🐦 Flutter imports:
import 'package:flutter/services.dart';
import 'package:supercharged/supercharged.dart';

// 📦 Package imports:
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../model/lecture.dart';
import '../model/word.dart';

/// Read asset from assets/ and write to temp file, return the file
Future<File> createFileFromAssets(String path) async {
  final byteData = await rootBundle.load('assets/$path');
  final file = File('${(await getTemporaryDirectory()).path}/$path');
  file.createSync(recursive: true);
  file.writeAsBytesSync(byteData.buffer
      .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
  return file;
}

/// Write string to temp file and return the file
Future<File> createFileFromString(String str) async {
  final file = File('${(await getTemporaryDirectory()).path}/${Uuid().v1()}');
  file.createSync(recursive: true);
  file.writeAsStringSync(str, flush: true);
  return file;
}

/// Extract index from lectureId
int getIndexOfLectureId(String lectureId) => int.parse(lectureId.substring(1));

/// Extract index from wordId
int getIndexOfWordId(String wordId) => int.parse(wordId.split('-')[1]);

/// Generate lecture id by index
String generateLectureIdFromIndex(int index) => 'C${index.toString().padLeft(4,'0')}';

/// Generate word id by index and lecture it belongs to
String generateWordIdFromIndex(int index, String lectureId) => '$lectureId-${index.toString().padLeft(3,'0')}';

/// Increase LectureId by 1
String increaseLectureId(String lectureId) => generateLectureIdFromIndex(getIndexOfLectureId(lectureId)+1);

/// Decrease lectureId by 1, lectureId can't be 1 or below
String decreaseLectureId(String lectureId) {
  final index = getIndexOfLectureId(lectureId);
  assert(index>1);
  return generateLectureIdFromIndex(index-1);
}

/// Increase wordId by 1
String increaseWordId(String wordId) => generateWordIdFromIndex(getIndexOfWordId(wordId)+1, wordId.split('-')[0]);

/// Decrease wordId by 1, wordId can't be 1 or below
String decreaseWordId(String wordId) {
  final index = getIndexOfWordId(wordId);
  assert(index>1);
  return generateWordIdFromIndex(index-1, wordId.split('-')[0]);
}