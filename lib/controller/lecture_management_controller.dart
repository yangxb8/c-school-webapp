import 'dart:io';

import 'package:cschool_webapp/model/lecture.dart';
import 'package:cschool_webapp/service/audio_service.dart';
import 'package:cschool_webapp/service/lecture_service.dart';
import 'package:cschool_webapp/service/logger_service.dart';
import 'package:flamingo/flamingo.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

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

  addRow(int index) {}

  deleteRow(int index) {}

  Future<void> handlerValueChange(
      {@required Rx<Lecture> lecture,
      @required String name,
      @required dynamic updated}) async {
    var origin = lecture.value.properties[name];
    if (origin is String && updated is String) {
      lecture.update((val) => val.properties[name] = updated);
    } else if (origin is int && updated is String) {
      lecture.update((val) => val.properties[name] = int.parse(updated));
    } else if (origin is StorageFile && updated is File) {
      try {
        lecture.update((val) async => val.properties[name] = await storage.save(
            origin.path, updated,
            filename: origin.name,
            mimeType: origin.mimeType,
            metadata: {'newPost': 'true'}));
      } catch (e, _) {
        LoggerService.logger.i(e);
      }
    }
  }
}
