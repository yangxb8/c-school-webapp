import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flamingo/flamingo.dart';
import 'package:flutter/material.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';

import '../controller/lecture_management_controller.dart';
import 'package:get/get.dart';

import 'ui_view/webapp_drawer.dart';

class LectureManagement extends GetView<LectureManagementController> {
  Widget buildTitle(String title, double width, [double height = 100]) => Container(
        width: 100,
        alignment: Alignment.centerLeft,
        height: height,
        child: Text(title),
      );

  Widget buildEditableCell(dynamic value, double width) {
    Widget origin;
    Widget input;
    TextEditingController textInputController;
    File uploadedFile;

    if (value is String) {
      origin = buildTitle(value, width);
    } else if (value is num) {
      origin = buildTitle(value.toString(), width);
    } else if (value is StorageFile) {
      if ([mimeTypeJpeg, mimeTypePng].contains(value.mimeType)) {
        origin = CachedNetworkImage(
          width: 100,
          fit: BoxFit.cover,
          httpHeaders: {
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "OPTIONS,POST,GET"
          },
          imageUrl: value.url,
        );
      }
    }
    if (value is String || value is num) {
      final textInputController = TextEditingController(text: value.toString());
      input = TextField(
        controller: textInputController,
      );
    } else if (value is StorageFile) {
      input = IconButton(
          icon: Icon(Icons.cloud_upload),
          onPressed: () async {
            FilePickerResult result = await FilePicker.platform.pickFiles();
            if (result != null) {
              uploadedFile = File(result.files.single.path);
            }
          });
    }
    return GestureDetector(
      child: origin,
      onTap: () => Get.dialog(AlertDialog(
        title: Text('变更内容'),
        content: Column(
          children: [Text('变更前:'), origin, Text('变更后:'), input],
        ),
        actions: [
          TextButton(
              onPressed: () {
                if (textInputController != null) {
                  textInputController.dispose();
                }
                Get.back();
              },
              child: Text('取消')),
          TextButton(
              onPressed: () async {
                if ((value is String || value is num) && value != textInputController.text) {
                  await controller.handlerValueChange(
                      origin: value, updated: textInputController.text);
                } else if (value is StorageFile) {
                  await controller.handlerValueChange(origin: value, updated: uploadedFile);
                }
                if (textInputController != null) {
                  textInputController.dispose();
                }
                Get.back();
              },
              child: Text('变更')),
        ],
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> columns = [
      buildTitle('课程编号', 100),
      buildTitle('课程LEVEL', 50),
      buildTitle('课程标题', 400),
      buildTitle('课程描述', 400),
      buildTitle('课程图片', 100),
      buildTitle('插入删除', 100),
    ];
    return Scaffold(
      appBar: AppBar(title: Text('课程管理'),),
      drawer: const CSchoolWebAppDrawer(),
      body: Container(
          alignment: Alignment.topCenter,
          child: Obx(
            () => HorizontalDataTable(
              leftHandSideColumnWidth: 100,
              rightHandSideColumnWidth: 1100,
              itemCount: controller.allLecturesObx.length,
              isFixedHeader: true,
              headerWidgets: columns,
              leftSideItemBuilder: (context, index) =>
                  Obx(() => buildEditableCell(controller.allLecturesObx[index].lectureId, 100)),
              rightSideItemBuilder: (context, index) => Row(
                children: [
                  Obx(() => buildEditableCell(controller.allLecturesObx[index].level, 50)),
                  Obx(() => buildEditableCell(controller.allLecturesObx[index].title, 400)),
                  Obx(() => buildEditableCell(controller.allLecturesObx[index].description, 400)),
                  Obx(() => buildEditableCell(controller.allLecturesObx[index].pic, 100)),
                  Container(
                    width: 100,
                    height: 60,
                    alignment: Alignment.center,
                    child: Row(
                      children: [
                        IconButton(icon: Icon(Icons.add), onPressed: () => controller.addRow(index)),
                        IconButton(
                            icon: Icon(Icons.indeterminate_check_box_outlined),
                            onPressed: () => controller.deleteRow(index)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          )),
    );
  }
}
