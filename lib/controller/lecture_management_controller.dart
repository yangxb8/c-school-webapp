import 'dart:io';

import 'package:cschool_webapp/model/lecture.dart';
import 'package:cschool_webapp/service/audio_service.dart';
import 'package:cschool_webapp/service/lecture_service.dart';
import 'package:cschool_webapp/service/logger_service.dart';
import 'package:flamingo/flamingo.dart';
import 'package:get/get.dart';

class LectureManagementController extends GetxController{
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

  Future<void> handlerValueChange({dynamic origin, dynamic updated}) async {
    if(origin is String && updated is String){
      origin = updated;
    } else if (origin is int && updated is String){
      origin = int.parse(updated);
    } else if (origin is double && updated is String){
      origin = double.parse(updated);
    } else if (origin is StorageFile && updated is File){
      try {
        origin = await storage.save(origin.path, updated,
            filename: origin.name,
            mimeType: origin.mimeType,
            metadata: {'newPost': 'true'});
      } catch (e, _) {
        LoggerService.logger.i(e);
      }
    }
  }
}