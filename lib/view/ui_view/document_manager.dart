// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:supercharged/supercharged.dart';

// Project imports:
import 'package:cschool_webapp/model/updatable.dart';
import 'package:cschool_webapp/service/lecture_service.dart';
import 'package:cschool_webapp/service/logger_service.dart';
import 'editable_cell.dart';
import 'webapp_drawer.dart';

const double defaultHeight = 100.0;

class DocumentManager<T extends UpdatableDocument<T>, N extends DocumentUpdateController<T>>
    extends GetView<N> {
  /// <name, width>
  static const addDeleteCellWidth = 100.0;

  /// Schema of table
  final Map<String, double> schema;

  /// Validator of table
  final Map<String, List<ValidatorFunction>> validators;

  /// Column name
  final String name;
  final double height;

  /// For building special cell content. Example: <'例句', WordExample content builder>
  final Map<String, ContentBuilder<T>> contentBuilder;

  /// For building special cell input. Example: <'例句', WordExample input builder>
  final Map<String, ContentBuilder<T>> inputBuilder;

  /// Pull to refresh controller
  final _hdtRefreshController = HDTRefreshController();

  DocumentManager({
    @required this.schema,
    this.validators = const {},
    this.contentBuilder = const {},
    this.inputBuilder = const {},
    this.height = defaultHeight,
  }) : name = T.toString();

  /// Prevent user from exiting if there is uncommit change
  Future<bool> onWillPop() async {
    if (controller.uncommitUpdateExist.isFalse) return Future.value(true);
    Get.snackbar(
        '尚有以下未保存的修改存在，请保存或放弃修改', controller.modifiedDocuments.keys.map((e) => e.value.id).join(','),
        duration: 5.seconds);
    return Future.value(false);
  }

  Widget get _leftSideEmptyWidget => Container(
        width: schema['id'],
        height: height,
      );

  double get _rightSideWidth =>
      schema.values.reduce((a, b) => a + b) - schema['id'] + addDeleteCellWidth;

  List<Widget> get _columns =>
      schema.entries.map((e) => TitleCell(title: e.key, width: e.value)).toList();

  List<Widget> _generateCells(int row) {
    final cells = <Widget>[];
    for (final entry in schema.entries) {
      if (entry.key == 'id') continue;
      cells.add(EditableCell<T, N>(
        name: entry.key,
        index: row,
        width: entry.value,
        height: height,
        validators: validators.containsKey(entry.key) ? validators[entry.key] : const [],
        contentBuilder: contentBuilder,
        inputBuilder: inputBuilder,
      ));
    }
    return cells;
  }

  Future<void> _onRefresh() async {
    try {
      await LectureService.refresh();
      controller.refreshCachedStorageFile();
      _hdtRefreshController.refreshCompleted();
    } catch (e) {
      LoggerService.logger.e(e);
      _hdtRefreshController.refreshFailed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('$name管理').width(100),
          actions: [
            Obx(
              () => IconButton(
                tooltip: '上传$name',
                icon: Icon(Icons.cloud_upload),
                onPressed: controller.processing.isTrue
                    ? null
                    : () => Get.dialog(ObxValue<Rx<PlatformFile>>(
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
                                          await controller.handleUpload(uploadedFile.value);
                                          Get.back();
                                        },
                                        child: Text('上传')),
                                  ]),
                        PlatformFile().obs)),
              ),
            ),
            Obx(
              () => IconButton(
                icon: Icon(Icons.save),
                onPressed: (controller.processing.isTrue || controller.uncommitUpdateExist.isFalse)
                    ? null
                    : controller.saveChange,
                disabledColor: Colors.grey,
                tooltip: '保存修改',
              ),
            ),
            Obx(
              () => IconButton(
                icon: Icon(Icons.cancel),
                onPressed: (controller.processing.isTrue || controller.uncommitUpdateExist.isFalse)
                    ? null
                    : controller.cancelChange,
                disabledColor: Colors.grey,
                tooltip: '放弃修改',
              ),
            )
          ],
        ),
        drawer: const CSchoolWebAppDrawer(),
        body: ObxValue(
            (RxList<Rx<T>> docs) => HorizontalDataTable(
                  leftHandSideColumnWidth: schema['id'],
                  rightHandSideColumnWidth: _rightSideWidth,
                  itemCount: docs.length + 1, // Add a Line for insert new row add bottom
                  isFixedHeader: true,
                  headerWidgets: _columns,
                  enablePullToRefresh: true,
                  refreshIndicator: const WaterDropHeader(),
                  onRefresh: _onRefresh,
                  htdRefreshController: _hdtRefreshController,
                  leftSideItemBuilder: (context, index) {
                    if (index == docs.length) {
                      return _leftSideEmptyWidget;
                    }
                    return EditableCell<T, N>(
                      index: index,
                      name: 'id',
                      width: schema['id'],
                      height: height,
                      validators:
                          validators.containsKey('id') ? validators['id'] : [Validators.required],
                      contentBuilder: contentBuilder,
                      inputBuilder: inputBuilder,
                    );
                  },
                  rightSideItemBuilder: (context, index) {
                    var addButton = Obx(() => IconButton(
                        icon: Icon(Icons.add),
                        onPressed: controller.processing.isTrue
                            ? null
                            : () async => await controller.addRow(index: index)));
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
                    return index == docs.length
                        ? addButton.center()
                        : Row(
                            children: [
                              ..._generateCells(index),
                              Container(
                                width: 100,
                                alignment: Alignment.center,
                                child: addDeleteRow,
                              )
                            ],
                          );
                  },
                ).center(),
            controller.docs),
      ),
    );
  }
}
