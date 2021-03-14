// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:get/get.dart';
import 'package:reactive_forms/reactive_forms.dart';

// Project imports:
import 'package:cschool_webapp/model/lecture.dart';
import '../controller/lecture_management_controller.dart';
import 'ui_view/document_manager.dart';

class LectureManagement extends GetView<LectureManagementController> {
  static const lectureIdPattern = r'^C\d{4}$';

  @override
  Widget build(BuildContext context) {
    const schema = {
      'id': 100.0,
      '标题': 100.0,
      '详细': 200.0,
      '等级': 100.0,
      'tags': 150.0,
      '图片': 100.0,
      '占位图片': 100.0
    };
    var validator = {
      'id':[Validators.required, Validators.pattern(lectureIdPattern)],
      'title': [Validators.required]
    };
    return DocumentManager<Lecture, LectureManagementController>(
      schema: schema,
      validators: validator,
      uneditableFields: const ['picHash'],
    );
  }
}
