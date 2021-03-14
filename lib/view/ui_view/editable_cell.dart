// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:auto_size_text/auto_size_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flamingo/flamingo.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:get/get.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:styled_widget/styled_widget.dart';

// Project imports:
import 'package:cschool_webapp/model/updatable.dart';

typedef ContentBuilder<T extends UpdatableDocument<T>> = Widget Function(T doc);

class EditableCell<T extends UpdatableDocument<T>, N extends DocumentUpdateController<T>>
    extends GetView<N> {
  /// Index of document
  final int index;

  /// Field name of document
  final String name;

  /// Width of this cell
  final double width;

  /// Height of this cell
  final double height;

  /// User usually don't need to care about this field. It's used for setup cell in cell
  final int subIndex;

  /// If the cell is editable
  final bool editable;

  /// validator of form data
  final List<ValidatorFunction> validators;

  /// For building special cell content. Example: <'例句', WordExample content builder>
  final ContentBuilder<T> contentBuilder;

  /// For building special cell input. Example: <'例句', WordExample input builder>
  final ContentBuilder<T> inputBuilder;

  EditableCell(
      {Key key,
      @required this.index,
      @required this.name,
      @required this.width,
      @required this.height,
      this.subIndex,
      this.editable = true,
      this.validators,
      this.contentBuilder,
      this.inputBuilder})
      : super(key: key);

  Widget _emptyCell() => const SizedBox.expand();

  Widget buildCellContent() => Container(
        height: height,
        width: width,
        decoration: BoxDecoration(border: Border.all()),
        child: ObxValue((Rx<T> doc) {
          if (contentBuilder != null) {
            return contentBuilder(doc.value);
          }
          var value =
              subIndex == null ? doc.value.properties[name] : doc.value.properties[name][subIndex];
          if (name == '占位图片') {
            if ((value as String).isEmpty) {
              return _emptyCell();
            }
            return BlurHash(hash: value, imageFit: BoxFit.cover);
          } else if (value is String || value is num) {
            return TitleCell(title: value.toString(), width: width);
          } else if (value is List<String>) {
            return TitleCell(
              title: value.join('/'),
              width: width,
            );
          } else if (value is StorageFile) {
            var cache = controller.getCachedData(doc, name);
            if (cache == null || (subIndex ?? 0) >= cache.length) {
              return _emptyCell();
            }
            var data = cache[subIndex ?? 0];
            if (name.contains('图片')) {
              return Image.memory(
                data,
                fit: BoxFit.cover,
              );
            }
          } else if (value is List<StorageFile>) {
            // Audios
            if (value.isEmpty) {
              return _emptyCell();
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                  value.length,
                  (idx) => EditableCell<T, N>(
                        index: index,
                        name: name,
                        width: width,
                        height: height,
                        subIndex: idx,
                      ).expanded()),
            );
          }
          // When null
          return _emptyCell();
        }, controller.docs[index]),
      );

  Widget buildInput() {
    return ObxValue((Rx<T> doc) {
      var value =
          subIndex == null ? doc.value.properties[name] : doc.value.properties[name][subIndex];
      if (inputBuilder != null) {
        return inputBuilder(doc.value);
      }
      if (value is String || value is num || value is List<String>) {
        controller.form(FormGroup({
          name: FormControl(
              value: value is List<String> ? value.join('/') : value.toString(),
              validators: validators)
        }));
        return ReactiveForm(
            formGroup: controller.form.value,
            child: ReactiveTextField(
              formControlName: name,
            ));
      } else if (value == null || value is StorageFile) {
        return ObxValue((Rx<PlatformFile> val) {
          var uploadedWidget;
          if (val.value.bytes == null) {
            uploadedWidget = Container();
          } else if (name.contains('pic')) {
            uploadedWidget = Image.memory(
              val.value.bytes,
              height: height,
              width: width,
            );
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
        }, controller.uploadedFile);
      }
      return Container();
    }, controller.docs[index]);
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
      var origin = buildCellContent();
      var input = buildInput();
      // picHash/audio cannot be modified directly.
      if (!editable) {
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
                  if (controller.validateForm) {
                    await controller.handleValueChange(doc: doc, name: name);
                    Get.back();
                  }
                },
                child: Text('变更')),
          ],
        ));
      }

      ;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(width: width, height: height, child: origin),
      );
    }, controller.docs);
  }
}

class TitleCell extends StatelessWidget {
  final String title;
  final double width;
  final double height;
  final Color color;

  const TitleCell(
      {Key key, @required this.title, @required this.width, this.height, this.color = Colors.white})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      alignment: Alignment.center,
      height: height,
      color: color,
      child: AutoSizeText(
        title ?? '',
      ),
    );
  }
}
