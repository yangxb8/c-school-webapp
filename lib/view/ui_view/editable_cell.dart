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

class EditableCell<T extends UpdatableDocument<T>, N extends DocumentUpdateController<T>>
    extends StatelessWidget {
  static const _picExtensions = ['jpg', 'jpeg', 'png'];
  static const _audioExtensions = ['mp3'];
  final N controller;
  final int index;
  final String name;
  final double width;

  EditableCell(
      {Key key,
      @required this.controller,
      @required this.index,
      @required this.name,
      @required this.width})
      : super(key: key);

  Widget buildCellContent() => ObxValue((Rx<T> doc) {
        var value = doc.value.properties[name];
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
          var data = controller.getCachedData(doc, name);
          if (data == null) {
            return Container(
              width: width,
              height: defaultHeight,
            );
          } else if (name.contains('pic')) {
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
        }
        // When null
        return Container(
          width: width,
          height: defaultHeight,
        );
      }, controller.docs[index]);

  List<String> _calculateExtensions() {
    if (name.contains('pic')) return _picExtensions;
    if (name.contains('audio')) return _audioExtensions;
    return [];
  }

  @override
  Widget build(BuildContext context) => ObxValue((Rx<T> doc) {
        var value = doc.value.properties[name];
        var origin = buildCellContent();
        Widget input;
        TextEditingController textInputController;
        var uploadedFile = PlatformFile().obs;
        // picHash cannot be modified
        if (name == 'picHash') {
          return origin;
        }
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          child: Container(width: width, height: defaultHeight, child: origin),
          onTap: () {
            if (value is String || value is num || value is List<String>) {
              textInputController = TextEditingController(
                  text: value is List<String> ? value.join('/') : value.toString());
              input = TextField(
                controller: textInputController,
              );
            } else if (value == null || value is StorageFile) {
              input = ObxValue((Rx<PlatformFile> val) {
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
                              .pickFiles(allowedExtensions: _calculateExtensions());
                          if (result != null) {
                            val(result.files.single);
                          }
                        }),
                  ],
                );
              }, uploadedFile);
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
                      if (textInputController != null &&
                          value.toString() != textInputController.text) {
                        await controller.handleValueChange(
                            doc: doc, name: name, updated: textInputController.text);
                      } else if (uploadedFile != null) {
                        await controller.handleValueChange(
                            doc: doc, name: name, updated: uploadedFile.value);
                      }
                      Get.back();
                    },
                    child: Text('变更')),
              ],
            ));
          },
        );
      }, controller.docs[index]);
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
