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
  final ApiService apiService = Get.find();

  @override
  RxList<Rx<Lecture>> get docs => LectureService.allLecturesObx;

  @override
  Lecture generateDocument(String id) => Lecture(id: id);

  @override
  Future<void> handleValueChange(
      {@required Rx<Lecture> doc,
      @required String name,
      @required dynamic updated}) async {
    // If lectureId is changed, move the row
    if (name == 'lectureId') {
      moveRow(doc, updated);
      return;
    }
    await doc.update((val) async {
      switch (name) {
        case 'lectureId':
          val.lectureId = updated;
          break;
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
          final path =
              '${doc.value.documentPath}/${EnumToString.convertToString(LectureKey.pic)}';
          var mimeType;
          if (file.extension == 'png') {
            mimeType = mimeTypePng;
          } else if (['jpg', 'jpeg'].contains(file.extension)) {
            mimeType = mimeTypeJpeg;
          }
          final storageRecord = StorageRecord(
              path,
              file.bytes,
              '${doc.value.lectureId}.${file.extension}',
              mimeType,
              {'newPost': 'true'});
          registerCacheUpdateRecord(
              doc: doc, name: name, updateRecord: storageRecord);
          try {
            var image = img.decodeImage(file.bytes);
            final picHash = await encodeBlurHash(
                image.getBytes(), image.width, image.height);
            val.picHash = picHash;
          } on BlurHashEncodeException catch (e) {
            logger.e(e.message);
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
    showPasswordRequireDialog(
        success: () async {
          final files = unArchive(uploadedFile);
          final csvContent = files.remove('csv') as String;
          await apiService.firestoreApi
              .uploadLecturesByCsv(content: csvContent, assets: files);
          await LectureService.refresh();
        },
        last: () => unlock());
  }

  @override
  void updateStorageFile(
      {Rx<Lecture> doc, String name, StorageFile storageFile}) {
    if (name == 'pic') {
      doc.update((val) => val.pic = storageFile);
    }
  }
}
