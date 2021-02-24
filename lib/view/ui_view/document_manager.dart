import 'package:cschool_webapp/model/updatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../controller/lecture_management_controller.dart';
import 'package:get/get.dart';
import 'editable_cell.dart';

import 'webapp_drawer.dart';

class DocumentManager<T extends UpdatableDocument<T>,
    N extends DocumentUpdateController<T>> extends StatelessWidget {
  /// Usually TitleCell
  final List<Widget> columns;
  final N controller;
  final String name;

  DocumentManager({@required this.columns, @required this.controller})
      : name = T.toString();

  /// Prevent user from exiting if there is uncommit change
  void onWillPop() async {
    if (controller.uncommitUpdateExist.isFalse) return Future.value(true);
    Get.snackbar('尚有以下未保存的修改存在，请保存或放弃修改',
        controller.modifiedDocuments.keys.map((e) => e.value.id).join(','),
        duration: 5.seconds);
    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('$name管理').width(100),
          actions: [
            IconButton(
              tooltip: '上传$name',
              icon: Icon(Icons.cloud_upload),
              onPressed: () => Get.dialog(ObxValue<Rx<PlatformFile>>(
                  (uploadedFile) => AlertDialog(
                      title: Text('上传$name'),
                      content: IconButton(
                          icon: Icon(Icons.cloud_upload),
                          onPressed: () async {
                            var result = await FilePicker.platform
                                .pickFiles(allowedExtensions: ['zip']);
                            uploadedFile(result.files.single);
                          }),
                      actions: uploadedFile.value.name == null
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
                                        .handleUpload(uploadedFile.value);
                                    Get.back();
                                  },
                                  child: Text('上传')),
                            ]),
                  PlatformFile().obs)),
            ),
            Obx(
              () => IconButton(
                icon: Icon(Icons.save),
                onPressed: (controller.processing.isTrue ||
                        controller.uncommitUpdateExist.isFalse)
                    ? null
                    : controller.saveChange,
                disabledColor: Colors.grey,
                tooltip: '保存修改',
              ),
            ),
            Obx(
              () => IconButton(
                icon: Icon(Icons.cancel),
                onPressed: (controller.processing.isTrue ||
                        controller.uncommitUpdateExist.isFalse)
                    ? null
                    : controller.cancelChange,
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
            itemCount: controller
                .docs.length, // Add a Line for insert new row add bottom
            isFixedHeader: true,
            headerWidgets: columns,
            leftSideItemBuilder: (context, index) => EditableCell<T, N>(
              index: index,
              name: 'id',
              width: 100,
              controller: controller,
            ),
            rightSideItemBuilder: (context, index) {
              var addButton = Obx(() => IconButton(
                  icon: Icon(Icons.add),
                  onPressed: controller.processing.isTrue
                      ? null
                      : () => controller.addRow(index: index)));
              var deleteButton = Obx(
                () => IconButton(
                    icon: Icon(Icons.indeterminate_check_box_outlined),
                    onPressed: controller.processing.isTrue
                        ? null
                        : () => controller.deleteRow(index)),
              );
              var addDeleteRow = Row(
                children: [
                  addButton,
                  deleteButton,
                ],
              );
              return index == controller.docs.length
                  ? addButton.center()
                  : Row(
                      children: [
                        buildEditableCell(
                            index: index, name: 'level', width: 50),
                        buildEditableCell(
                            index: index, name: 'title', width: 200),
                        buildEditableCell(
                            index: index, name: 'description', width: 200),
                        buildEditableCell(
                            index: index, name: 'pic', width: 100),
                        buildEditableCell(
                            index: index, name: 'picHash', width: 100),
                        buildEditableCell(
                            index: index, name: 'tags', width: 200),
                        Container(
                          width: 100,
                          alignment: Alignment.center,
                          child: addDeleteRow,
                        )
                      ],
                    );
            },
          ),
        ),
      ),
    );
  }
}
