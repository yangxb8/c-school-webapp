// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:get/get.dart';

// Project imports:
import 'package:cschool_webapp/model/lecture.dart';
import '../controller/lecture_management_controller.dart';
import 'ui_view/document_manager.dart';

class LectureManagement extends GetView<LectureManagementController> {
  @override
  Widget build(BuildContext context) {
    var schema = {
      'id': 100.0,
      'title': 100.0,
      'description': 200.0,
      'level': 100.0,
      'tags': 150.0,
      'pic': 100.0,
      'picHash': 100.0
    };
    return DocumentManager<Lecture, LectureManagementController>(
      controller: controller,
      schema: schema,
    );
  }
}
