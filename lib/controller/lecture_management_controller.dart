// Flutter imports:
import 'dart:convert';

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
  List<String> get uneditableFields => ['picHash'];

  @override
  Lecture generateDocument([String id]) => Lecture(id: id ?? 'C0001');

  @override
  Future<void> handleValueChange(
      {@required Rx<Lecture> doc, @required String name, @required dynamic updated}) async {
    // If id is changed, move the row
    if (name == 'id') {
      moveRow(doc, updated);
      return;
    }
    await doc.update((val) async {
      switch (name) {
        case 'title':
          val.title = updated;
          break;
        case 'description':
          val.description = updated;
          break;
        case 'level':
          val.level = int.parse(updated);
          break;
        case 'tags':
          val.tags.assignAll(updated.split('/'));
          break;
        case 'pic':
          final file = updated as PlatformFile;
          final path = '${doc.value.documentPath}/${EnumToString.convertToString(LectureKey.pic)}';
          final storageRecord = StorageRecord(
              path: path, data: file.bytes, filename: '${doc.value.lectureId}.${file.extension}');
          registerCacheUpdateRecord(doc: doc, name: name, updateRecords: [storageRecord]);
          try {
            if (!tryLock()) return;
            var image = img.decodeImage(file.bytes);
            final picHash = await encodeBlurHash(image.getBytes(), image.width, image.height);
            val.picHash = picHash;
          } on BlurHashEncodeException catch (e) {
            logger.e(e.message);
          } finally {
            unlock();
          }
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
