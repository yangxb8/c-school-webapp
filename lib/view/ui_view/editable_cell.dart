// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:auto_size_text/auto_size_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flamingo/flamingo.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:get/get.dart';

// Project imports:
import 'package:cschool_webapp/model/updatable.dart';
import 'package:cschool_webapp/service/audio_service.dart';

const double defaultHeight = 100.0;

typedef ContentBuilder<T extends UpdatableDocument<T>> = Widget Function(T doc);

/// Only text input is supported now
typedef InputBuilder<T extends UpdatableDocument<T>> = Widget Function(
    T doc, TextEditingController textInputController);

class EditableCell<T extends UpdatableDocument<T>, N extends DocumentUpdateController<T>>
    extends StatelessWidget {
  final N controller;

  /// Index of document
  final int index;

  /// Field name of document
  final String name;

  /// Width of this cell
  final double width;

  /// User usually don't need to care about this field. It's used for setup cell in cell
  final int subIndex;

  /// For building special cell content. Example: <'例句', WordExample content builder>
  final Map<String, ContentBuilder<T>> contentBuilder;

  /// For building special cell input. Example: <'例句', WordExample input builder>
  final Map<String, InputBuilder<T>> inputBuilder;

  EditableCell(
      {Key key,
      @required this.controller,
      @required this.index,
      @required this.name,
      @required this.width,
      this.subIndex,
      this.contentBuilder,
      this.inputBuilder})
      : super(key: key);

  Widget _emptyCell(double width) => Container(
        width: width,
        height: defaultHeight,
      );

  Widget buildCellContent() => ObxValue((Rx<T> doc) {
        if (contentBuilder.containsKey(name)) {
          return contentBuilder[name](doc.value);
        }
        var value =
            subIndex == null ? doc.value.properties[name] : doc.value.properties[name][subIndex];
        if (name == 'picHash') {
          return Container(
              width: width,
              height: defaultHeight,
              child: BlurHash(hash: value, imageFit: BoxFit.cover));
        } else if (value is String || value is num) {
          return TitleCell(title: value.toString(), width: width);
        } else if (value is List<String>) {
          return TitleCell(
            title: value.join('/'),
            width: width,
          );
        } else if (value is StorageFile) {
          var cache = controller.getCachedData(doc, name);
          if (cache == null) {
            return _emptyCell(width);
          }
          var data = cache[subIndex ?? 0];
          if (name.contains('pic')) {
            return Image.memory(
              data,
              width: width,
              height: defaultHeight,
              fit: BoxFit.cover,
            );
          } else if (name.contains('audio')) {
            return IconButton(
                icon: Icon(Icons.play_arrow), onPressed: () => Get.find<AudioService>().play(data));
          }
        } else if (value is List<StorageFile>) {
          // Audios
          if (value.isEmpty) {
            return _emptyCell(width);
          }
          return Container(
            width: width,
            height: defaultHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                  value.length,
                  (idx) => EditableCell<T, N>(
                        controller: controller,
                        index: index,
                        name: name,
                        width: width,
                        subIndex: index,
                      )),
            ),
          );
        }
        // When null
        return _emptyCell(width);
      }, controller.docs[index]);

  Widget buildInput(Rx<T> doc,
      {@required TextEditingController textInputController,
      @required Rx<PlatformFile> uploadedFile}) {
    return ObxValue((Rx<T> doc) {
      var value =
          subIndex == null ? doc.value.properties[name] : doc.value.properties[name][subIndex];
      if (inputBuilder.containsKey(name)) {
        return inputBuilder[name](doc.value, textInputController);
      }
      if (value is String || value is num || value is List<String>) {
        return TextField(
          controller: textInputController,
        );
      } else if (value == null || value is StorageFile) {
        return ObxValue((Rx<PlatformFile> val) {
          var uploadedWidget;
          if (val.value.bytes == null) {
            uploadedWidget = Container();
          } else if (name.contains('pic')) {
            uploadedWidget = Image.memory(
              val.value.bytes,
              height: defaultHeight,
              width: width,
            );
          } else if (name.contains('audio')) {
            uploadedWidget = IconButton(
                icon: Icon(Icons.play_arrow),
                onPressed: () => Get.find<AudioService>().play(val.value.bytes));
          }
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              uploadedWidget,
              IconButton(
                  icon: Icon(Icons.cloud_upload),
                  onPressed: () async {
                    var result = await FilePicker.platform
                        .pickFiles(allowedExtensions: controller.calculateAllowedExtensions(name));
                    if (result != null) {
                      val(result.files.single);
                    }
                  }),
            ],
          );
        }, uploadedFile);
      }
      return Container();
    }, doc);
  }

  @override
  Widget build(BuildContext context) {
    return ObxValue((RxList<Rx<T>> docs) {
      // Sometime especially last row, DocumentManager fail to observe the list change
      // So we stop it here
      if (index >= docs.length) {
        return Container();
      }
      final doc = docs[index];
      var value =
          subIndex == null ? doc.value.properties[name] : doc.value.properties[name][subIndex];
      var origin = buildCellContent();
      var textInputController =
          TextEditingController(text: value is List<String> ? value.join('/') : value.toString());
      ;
      var uploadedFile = PlatformFile().obs;
      var input =
          buildInput(doc, uploadedFile: uploadedFile, textInputController: textInputController);
      // picHash/audio cannot be modified directly.
      if (controller.uneditableFields.contains(name)) {
        return origin;
      }
      void onTap() {
        Get.dialog(AlertDialog(
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
                  if (value is String || value is num || value is List<String>) {
                    await controller.handleValueChange(
                        doc: doc, name: name, updated: textInputController.text);
                  } else if (value == null || value is StorageFile) {
                    await controller.handleValueChange(
                        doc: doc, name: name, updated: uploadedFile.value);
                  }
                  Get.back();
                },
                child: Text('变更')),
          ],
        ));
      }

      ;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        child: Container(width: width, height: defaultHeight, child: origin),
        onTap: onTap,
      );
    }, controller.docs);
  }
}

class TitleCell extends StatelessWidget {
  final String title;
  final double width;
  final Color color;

  const TitleCell({Key key, @required this.title, @required this.width, this.color = Colors.white})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      alignment: Alignment.center,
      height: defaultHeight,
      child: AutoSizeText(
        title ?? '',
        maxLines: 2,
      ),
      color: color,
    );
  }
}
