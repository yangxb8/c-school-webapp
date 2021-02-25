// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/services.dart';

// Package imports:
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

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
