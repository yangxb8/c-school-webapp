// Dart imports:
import 'dart:convert';

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:blurhash_dart/src/exception.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flamingo/flamingo.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;

// Project imports:
import 'package:cschool_webapp/model/lecture.dart';
import 'package:cschool_webapp/service/api_service.dart';
import 'package:cschool_webapp/service/lecture_service.dart';
import 'package:cschool_webapp/view/ui_view/password_require.dart';
import '../model/lecture.dart';
import '../model/updatable.dart';

class LectureManagementController extends DocumentUpdateController<Lecture> {
  @override
  RxList<Rx<Lecture>> get docs => LectureService.allLecturesObx;

  @override
  Lecture generateDocument([String id]) => Lecture(id: id ?? 'C0001');

  @override
  Future<void> handleValueChange({@required Rx<Lecture> doc, @required String name}) async {
    if (name == '图片') {
      doc.update((val) async {
        final file = uploadedFile.value;
        final path = '${doc.value.documentPath}/${EnumToString.convertToString(LectureKey.pic)}';
        final storageRecord = StorageRecord(
            path: path, data: file.bytes, filename: '${doc.value.lectureId}.${file.extension}');
        registerCacheUpdateRecord(doc: doc, name: name, updateRecords: [storageRecord]);
        try {
          if (!tryLock()) return;
          var image = img.decodeImage(file.bytes);
          final picHash = BlurHash.encode(image, numCompX: 9, numCompY: 9).hash;
          val.picHash = picHash;
        } on BlurHashEncodeException catch (e) {
          logger.e(e.message);
        } finally {
          unlock();
        }
      });
      return;
    }
    final updated = form.value.controls[name].value;
    // If id is changed, move the row
    if (name == 'id') {
      moveRow(doc, updated);
      return;
    }
    doc.update((val) {
      switch (name) {
        case '标题':
          val.title = updated;
          break;
        case '详细':
          val.description = updated;
          break;
        case '等级':
          val.level = int.parse(updated);
          break;
        case 'tags':
          val.tags.assignAll(updated.split('/'));
          break;
        default:
          return;
      }
    });
  }

  /// Upload lectures with zip file
  @override
  Future<void> handleUpload(PlatformFile uploadedFile) async {
    if (!tryLock()) {
      return;
    }
    await showPasswordRequireDialog(
        success: () async {
          final files = unArchive(uploadedFile);
          final csvContent = utf8.decode(files.remove('csv'));
          await apiService.firestoreApi.uploadLecturesByCsv(content: csvContent, assets: files);
          await LectureService.refresh();
        },
        last: () => unlock());
  }

  @override
  void updateStorageFile({Rx<Lecture> doc, String name, List<StorageFile> storageFiles}) {
    if (name == 'pic') {
      doc.update((val) => val.pic = storageFiles.single);
    }
  }
}
