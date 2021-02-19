import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cschool_webapp/model/lecture.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flamingo/flamingo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';
import 'package:styled_widget/styled_widget.dart';

import '../controller/lecture_management_controller.dart';
import 'package:get/get.dart';

import 'ui_view/webapp_drawer.dart';
import '../util/utility.dart';

class LectureManagement extends GetView<LectureManagementController> {
  static const defaultHeight = 100.0;

  Widget buildTitle(String title, double width, {Color color = Colors.white}) => Container(
        width: width,
        alignment: Alignment.center,
        height: defaultHeight,
        child: Text(title ?? ' '),
        color: color,
      );

  Widget buildCellContent(
      {@required Rx<Lecture> lecture, @required String name, @required double width}) {
    var value = lecture.value.properties[name];
    if (value is String) {
      if (name == 'picHash') {
        return Obx(() => Container(
            width: width,
            height: defaultHeight,
            child: BlurHash(hash: lecture.value.properties[name], imageFit: BoxFit.cover)));
      } else if (name == 'lectureId') {
        return Obx(() => buildTitle(lecture.value.properties[name], width));
      } else {
        return Obx(() => buildTitle(lecture.value.properties[name], width));
      }
    } else if (value is List<String>) {
      // tags
      return Obx(() => buildTitle(
            lecture.value.properties[name].join('/'),
            width,
          ));
    } else if (value is num) {
      return Obx(() => buildTitle(lecture.value.properties[name].toString(), width));
    } else if (value is StorageFile) {
      if ([mimeTypeJpeg, mimeTypePng].contains(value.mimeType)) {
        return Obx(
          () => lecture.value.properties[name].url == null
              ? const SizedBox.expand()
              : CachedNetworkImage(
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
    return null;
  }

  Widget buildEditableCell({@required int index, @required String name, @required double width}) {
    var lecture = controller.allLecturesObx[index];

    var value = lecture.value.properties[name];
    var origin = buildCellContent(lecture: lecture, name: name, width: width);
    Widget input;
    TextEditingController textInputController;
    Uint8List uploadedFile;
    if (name == 'picHash') {
      return origin;
    }
    return GestureDetector(
      child: SizedBox(width: width, height: defaultHeight, child: origin),
      onTap: () {
        if (value is String || value is List<String> || value is num) {
          textInputController = TextEditingController(
              text: value is List<String> ? value.join('/') : value.toString());
          input = TextField(
            controller: textInputController,
          );
        } else if (value is StorageFile) {
          input = IconButton(
              icon: Icon(Icons.cloud_upload),
              onPressed: () async {
                var result = await FilePicker.platform.pickFiles(type: FileType.image);
                if (result != null) {
                  uploadedFile = result.files.single.bytes;
                }
              });
        }
        return Get.dialog(AlertDialog(
          title: Text('变更内容'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [Text('变更前:'), origin, Text('变更后:'), input],
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Get.back();
                },
                child: Text('取消')),
            TextButton(
                onPressed: () async {
                  if ((value is String || value is List<String> || value is num) &&
                      value.toString() != textInputController.text) {
                    await controller.handlerValueChange(
                        lecture: lecture, name: name, updated: textInputController.text);
                  } else if (value is StorageFile) {
                    await controller.handlerValueChange(
                        lecture: lecture, name: name, updated: uploadedFile);
                  }
                  Get.back();
                },
                child: Text('变更')),
          ],
        ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var columns = <Widget>[
      buildTitle('课程编号', 100),
      buildTitle('LEVEL', 50),
      buildTitle('课程标题', 200),
      buildTitle('课程描述', 200),
      buildTitle('课程图片', 100),
      buildTitle('占位图片', 100),
      buildTitle('标签(用/分隔)', 200),
      buildTitle('插入删除', 100),
    ];
    return WillPopScope(
      onWillPop: () async {
        if (controller.batchSet.isEmpty) return Future.value(true);
        Get.snackbar('尚有以下未保存的修改存在，请保存或放弃修改',
            controller.batchSet.map((e) => e.values.single.value.lectureId).join(', '),
            duration: 5.seconds);
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('课程管理').alignment(Alignment.center),
          actions: [
            IconButton(
                tooltip: '上传课程',
                icon: Icon(Icons.cloud_upload),
                onPressed: () => Get.dialog(ValueBuilder<PlatformFile>(
                      builder: (uploadedFile, updateFn) => AlertDialog(
                          title: Text('上传课程'),
                          content: IconButton(
                              icon: Icon(Icons.cloud_upload),
                              onPressed: () async {
                                var result =
                                    await FilePicker.platform.pickFiles(allowedExtensions: ['zip']);
                                uploadedFile = result.files.single;
                              }),
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
                                        await controller.handleLectureUpload(uploadedFile.bytes);
                                        Get.back();
                                      },
                                      child: Text('上传')),
                                ]),
                    ))),
            Obx(
              () => IconButton(
                icon: Icon(Icons.save),
                onPressed: controller.batchSet.isEmpty ? null : controller.saveChange,
                disabledColor: Colors.grey,
                tooltip: '保存修改',
              ),
            ),
            Obx(
              () => IconButton(
                icon: Icon(Icons.cancel),
                onPressed: controller.batchSet.isEmpty ? null : controller.cancelChange,
                disabledColor: Colors.grey,
                tooltip: '放弃修改',
              ),
            )
          ],
        ),
        drawer: const CSchoolWebAppDrawer(),
        body: Obx(
          () => HorizontalDataTable(
            leftHandSideColumnWidth: 100,
            rightHandSideColumnWidth: 1500,
            itemCount: controller.allLecturesObx.length,
            isFixedHeader: true,
            headerWidgets: columns,
            leftSideItemBuilder: (context, index) =>
                Obx(() => buildEditableCell(index: index, name: 'lectureId', width: 100)),
            rightSideItemBuilder: (context, index) => Row(
              children: [
                buildEditableCell(index: index, name: 'level', width: 50),
                buildEditableCell(index: index, name: 'title', width: 200),
                buildEditableCell(index: index, name: 'description', width: 200),
                buildEditableCell(index: index, name: 'pic', width: 100),
                buildEditableCell(index: index, name: 'picHash', width: 100),
                buildEditableCell(index: index, name: 'tags', width: 200),
                Container(
                  width: 100,
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
        ),
      ),
    );
  }
}
