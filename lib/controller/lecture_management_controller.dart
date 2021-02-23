import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:image/image.dart' as img;
import 'package:blurhash_dart/src/exception.dart';
import 'package:cschool_webapp/model/lecture.dart';
import 'package:cschool_webapp/service/api_service.dart';
import 'package:cschool_webapp/service/lecture_service.dart';
import 'package:flamingo/flamingo.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../model/lecture.dart';
import '../model/updatable.dart';

class LectureManagementController extends DocumentUpdateDelegate<Lecture>
    with DocumentUpdateMixin<Lecture> {
  final ApiService apiService = Get.find();

  @override
  RxList<Rx<Lecture>> get docs => LectureService.allLecturesObx;

  @override
  Lecture generateDocument(String id) => Lecture(id: id);

  @override
  Future<void> handleValueChange(
      {@required Rx<Lecture> lecture, @required String name, @required dynamic updated}) async {
    // If lectureId is changed, move the row
    if (name == 'lectureId') {
      moveRow(lecture, updated);
      return;
    }
    if (['title', 'description'].contains(name)) {
      _updateProperties(lecture: lecture, property: name, newVal: updated);
    } else if (name == 'tags') {
      // tags
      _updateProperties(lecture: lecture, property: name, newVal: updated.split('/'));
    } else if (name == 'level') {
      _updateProperties(lecture: lecture, property: name, newVal: int.parse(updated));
    } else if (name == 'pic') {
      final file = updated as PlatformFile;
      final path = '${lecture.value.documentPath}/${EnumToString.convertToString(LectureKey.pic)}';
      var mimeType;
      if (file.extension == 'png') {
        mimeType = mimeTypePng;
      } else if (['jpg', 'jpeg'].contains(file.extension)) {
        mimeType = mimeTypeJpeg;
      }
      final storageRecord = StorageRecord(path, file.bytes,
          '${lecture.value.lectureId}.${file.extension}', mimeType, {'newPost': 'true'});
      registerCacheUpdateRecord(doc: lecture, name: name, updateRecord: storageRecord);
      try {
        var image = img.decodeImage(file.bytes);
        final picHash = await encodeBlurHash(image.getBytes(), image.width, image.height);
        _updateProperties(lecture: lecture, property: 'picHash', newVal: picHash);
      } on BlurHashEncodeException catch (e) {
        logger.e(e.message);
      }
    }
  }

  /// Upload lectures with zip file
  @override
  Future<void> handleUpload(Uint8List uploadedFile) async {
    String csvContent;
    Map<String, Uint8List> assets;
    final archive = ZipDecoder().decodeBytes(uploadedFile);
    // Extract the contents of the Zip archive
    for (final file in archive) {
      final filename = file.name;
      if (filename.endsWith('csv')) {
        csvContent = Utf8Decoder().convert(file.content as Uint8List);
      } else if (filename.endsWith('jpg') || filename.endsWith('png')) {
        assets[filename] = file.content as Uint8List;
      }
    }
    await apiService.firestoreApi.uploadLecturesByCsv(csv: csvContent, assets: assets);
  }

  void _updateProperties(
      {@required Rx<Lecture> lecture, @required String property, @required dynamic newVal}) {
    lecture.update((val) {
      switch (property) {
        case 'lectureId':
          val.lectureId = newVal;
          break;
        case 'title':
          val.title = newVal;
          break;
        case 'description':
          val.description = newVal;
          break;
        case 'level':
          val.level = newVal;
          break;
        case 'tags':
          val.tags.assignAll(newVal);
          break;
        case 'pic':
          val.pic = newVal;
          break;
        case 'picHash':
          val.picHash = newVal;
          break;
        default:
          return;
      }
    });
  }

}
