import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cschool_webapp/model/lecture.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flamingo/flamingo.dart';
import 'package:flutter/material.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';
import 'package:styled_widget/styled_widget.dart';

import '../controller/lecture_management_controller.dart';
import 'package:get/get.dart';

import 'ui_view/webapp_drawer.dart';
import '../util/utility.dart';

class LectureManagement extends GetView<LectureManagementController> {
  static const defaultHeight = 100.0;

  Widget buildTitle(String title, double width,
          {double height = defaultHeight, Color color = Colors.white}) =>
      Container(
          width: 100,
          alignment: Alignment.centerLeft,
          height: height,
          child: Text(title),
          color: color);

  Widget buildEditableCell(
      {@required int index, @required String name, @required double width}) {
    var lecture = controller.allLecturesObx[index];

    return ObxValue((Rx<Lecture> lecture) {
      var value = lecture.value.properties[name];
      Widget origin;
      Widget input;
      TextEditingController textInputController;
      Uint8List uploadedFile;

      if (value is String) {
        if (name == 'lectureId') {
          origin = Obx(() => buildTitle(lecture.value.properties[name], width,
              color: controller.isLectureInBatch(lecture)
                  ? Colors.yellowAccent
                  : Colors.white));
        } else {
          origin = Obx(() => buildTitle(lecture.value.properties[name], width));
        }
      } else if (value is num) {
        origin = Obx(
            () => buildTitle(lecture.value.properties[name].toString(), width));
      } else if (value is StorageFile) {
        if ([mimeTypeJpeg, mimeTypePng].contains(value.mimeType)) {
          origin = Obx(
            () => CachedNetworkImage(
              width: width,
              fit: BoxFit.cover,
              httpHeaders: {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
              },
              imageUrl: lecture.value.properties[name].url,
            ),
          );
        }
      }
      if (value is String || value is num) {
        textInputController = TextEditingController(text: value.toString());
        input = TextField(
          controller: textInputController,
        );
      } else if (value is StorageFile) {
        input = IconButton(
            icon: Icon(Icons.cloud_upload),
            onPressed: () async {
              var result =
                  await FilePicker.platform.pickFiles(type: FileType.image);
              if (result != null) {
                uploadedFile = result.files.single.bytes;
              }
            });
      }
      return GestureDetector(
        child: SizedBox(width: width, height: defaultHeight, child: origin),
        onTap: () => Get.dialog(AlertDialog(
          title: Text('变更内容'),
          content: Column(
            children: [Text('变更前:'), origin, Text('变更后:'), input],
          ),
          actions: [
            TextButton(
                onPressed: () {
                  // if (textInputController != null) {
                  //   textInputController.dispose();
                  // }
                  Get.back();
                },
                child: Text('取消')),
            TextButton(
                onPressed: () async {
                  if ((value is String || value is num) &&
                      value.toString() != textInputController.text) {
                    await controller.handlerValueChange(
                        lecture: lecture,
                        name: name,
                        updated: textInputController.text);
                  } else if (value is StorageFile) {
                    await controller.handlerValueChange(
                        lecture: lecture, name: name, updated: uploadedFile);
                  }
                  // if (textInputController != null) {
                  //   textInputController.dispose();
                  // }
                  Get.back();
                },
                child: Text('变更')),
          ],
        )),
      );
    }, lecture);
  }

  @override
  Widget build(BuildContext context) {
    var columns = <Widget>[
      buildTitle('课程编号', 100),
      buildTitle('课程LEVEL', 50),
      buildTitle('课程标题', 400),
      buildTitle('课程描述', 400),
      buildTitle('课程图片', 100),
      buildTitle('标签', 400),
      buildTitle('插入删除', 100),
    ];
    return WillPopScope(
      onWillPop: () async {
        if (controller.batchSet.isEmpty) return Future.value(true);
        Get.snackbar(
            '尚有以下未保存的修改存在，请保存或放弃修改',
            controller.batchSet
                .map((e) => e.values.single.value.lectureId)
                .join(', '),
            duration: 5.seconds);
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('课程管理'),
        ),
        drawer: const CSchoolWebAppDrawer(),
        body: Container(
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                Obx(
                  () => HorizontalDataTable(
                    leftHandSideColumnWidth: 100,
                    rightHandSideColumnWidth: 1500,
                    itemCount: controller.allLecturesObx.length,
                    isFixedHeader: true,
                    headerWidgets: columns,
                    leftSideItemBuilder: (context, index) => Obx(() =>
                        buildEditableCell(
                            index: index, name: 'lectureId', width: 100)),
                    rightSideItemBuilder: (context, index) => Row(
                      children: [
                        buildEditableCell(
                            index: index, name: 'level', width: 50),
                        buildEditableCell(
                            index: index, name: 'title', width: 400),
                        buildEditableCell(
                            index: index, name: 'description', width: 400),
                        buildEditableCell(
                            index: index, name: 'pic', width: 100),
                        buildEditableCell(
                            index: index, name: 'tags', width: 400),
                        Container(
                          width: 100,
                          alignment: Alignment.center,
                          child: Row(
                            children: [
                              IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () => controller.addRow(index)),
                              IconButton(
                                  icon: Icon(
                                      Icons.indeterminate_check_box_outlined),
                                  onPressed: () => controller.deleteRow(index)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                        icon: Icon(Icons.cloud_upload),
                        onPressed: () => Get.dialog(ValueBuilder<PlatformFile>(
                              builder: (uploadedFile, updateFn) => AlertDialog(
                                  title: Text('上传课程'),
                                  content: IconButton(
                                      icon: Icon(Icons.cloud_upload),
                                      onPressed: () async {
                                        var result = await FilePicker.platform
                                            .pickFiles(
                                                allowedExtensions: ['zip']);
                                        uploadedFile = result.files.single;
                                      }).center(),
                                  actions: uploadedFile == null
                                      ? []
                                      : [
                                          TextButton(
                                              onPressed: () {
                                                Get.back();
                                              },
                                              child: Text('取消')),
                                          TextButton(
                                              onPressed: () async {
                                                await controller
                                                    .handleLectureUpload(
                                                        uploadedFile.bytes);
                                                Get.back();
                                              },
                                              child: Text('上传')),
                                        ]),
                            ))),
                    IconButton(
                      icon: Icon(Icons.save),
                      onPressed: controller.batchSet.isEmpty
                          ? null
                          : controller.saveChange,
                      disabledColor: Colors.grey,
                      tooltip: '保存修改',
                    ),
                    IconButton(
                      icon: Icon(Icons.cancel),
                      onPressed: controller.batchSet.isEmpty
                          ? null
                          : controller.cancelChange,
                      disabledColor: Colors.grey,
                      tooltip: '放弃修改',
                    )
                  ],
                )
              ],
            )),
      ),
    );
  }
}
