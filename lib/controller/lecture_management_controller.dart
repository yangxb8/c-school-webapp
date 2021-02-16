import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cschool_webapp/model/lecture.dart';
import 'package:cschool_webapp/service/api_service.dart';
import 'package:supercharged/supercharged.dart';
import 'package:cschool_webapp/service/audio_service.dart';
import 'package:cschool_webapp/service/lecture_service.dart';
import 'package:cschool_webapp/service/logger_service.dart';
import 'package:flamingo/flamingo.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../model/lecture.dart';
import '../util/utility.dart';

class LectureManagementController extends GetxController {
  final LectureService lectureService = Get.find();
  final AudioService audioService = Get.find();
  final storage = Storage()..fetch();
  RxList<Rx<Lecture>> allLecturesObx;

  @override
  void onInit() {
    allLecturesObx = LectureService.allLecturesObx;
    super.onInit();
  }

  void addRow(int index) {
    allLecturesObx.forEachIndexed((idx, lecture) {
      if(idx<index) return;
      lecture.update((val) => val.lectureId = increaseLectureId(val.lectureId));
    });
    // lectureId start from 1, so index+1
    allLecturesObx.insert(index, new Lecture(id: generateLectureIdFromIndex(index+1)).obs);
  }

  void deleteRow(int index) {
    allLecturesObx.removeAt(index);
    allLecturesObx.forEachIndexed((idx, lecture) {
      if(idx<index) return;
      lecture.update((val) => val.lectureId = decreaseLectureId(val.lectureId));
    });
  }

  void moveRow(String fromId, String toId) {
    final toIndex = getIndexOfWordId(toId);
    final target = allLecturesObx.removeAt(getIndexOfWordId(fromId)-1);
    target.update((val) => val.lectureId=toId);
    allLecturesObx.forEachIndexed((index, lecture) {
      if(index+1<toIndex) return;
      lecture.update((val) => val.lectureId = increaseLectureId(val.lectureId));
    });
    allLecturesObx.insert(toIndex-1, target);
  }

  Future<void> handlerValueChange(
      {@required Rx<Lecture> lecture,
      @required String name,
      @required dynamic updated}) async {
    // If lectureId is changed, move the row
    if(name=='lectureId' && updated is String){
      moveRow(lecture.value.lectureId, updated);
      return;
    }
    var origin = lecture.value.properties[name];
    if (origin is String && updated is String) {
      lecture.update((val) => val.properties[name] = updated);
    } else if (origin is int && updated is String) {
      lecture.update((val) => val.properties[name] = int.parse(updated));
    } else if (origin is StorageFile && updated is Uint8List) {
      try {
        lecture.update((val) async => val.properties[name] = await storage.saveFromBytes(
            origin.path, updated,
            filename: origin.name,
            mimeType: origin.mimeType,
            metadata: {'newPost': 'true'}));
      } catch (e, _) {
        LoggerService.logger.i(e);
      }
    }
  }

  /// Upload lectures with zip file
  Future<void> handleLectureUpload(Uint8List uploadedFile) async{
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
    await Get.find<ApiService>().firestoreApi.uploadLecturesByCsv(csv: csvContent, assets: assets);
  }
}
