// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:blurhash_dart/src/exception.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:file_picker/src/platform_file.dart';
import 'package:flamingo/src/model/storage_file.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:image/image.dart' as img;

// Project imports:
import 'package:cschool_webapp/model/updatable.dart';
import 'package:cschool_webapp/model/word.dart';
import 'package:cschool_webapp/service/lecture_service.dart';
import 'package:cschool_webapp/view/ui_view/password_require.dart';

class WordManagementController extends DocumentUpdateController<Word> {
  late String lectureId;
  RxList<Rx<Word>>? _docs;

  @override
  void onInit() {
    lectureId = Get.currentRoute.split('/').last;
    super.onInit();
  }

  @override
  RxList<Rx<Word>> get docs {
    _docs ??= lectureService.findLectureById(lectureId)!.words.map((w) => w.obs).toList().obs;
    return _docs!;
  }

  @override
  Word generateDocument([String? id]) => Word(id: id ?? '$lectureId-001');

  @override
  Future<void> handleUpload(PlatformFile uploadedFile) async {
    if (!tryLock()) {
      return;
    }
    await showPasswordRequireDialog(
        success: () async {
          final files = unArchive(uploadedFile);
          final csvContent = utf8.decode(files.remove('csv')!);
          apiService.firestoreApi.uploadWordsByCsv(content: csvContent, assets: files);
          await LectureService.refresh();
        },
        last: () => unlock());
  }

  @override
  Future<void> handleValueChange({Rx<Word>? doc, String? name}) async {
    if (name == '图片') {
      doc!.update((val) async {
        final file = uploadedFile.value!;
        final path = '${doc.value!.documentPath}/${EnumToString.convertToString(WordKey.pic)}';
        final storageRecord = StorageRecord(
            path: path, data: file.bytes, filename: '${doc.value!.id}.${file.extension}');
        registerCacheUpdateRecord(doc: doc, name: name!, updateRecords: [storageRecord]);
        try {
          if (!tryLock()) return;
          var image = img.decodeImage(file.bytes!)!;
          final picHash = BlurHash.encode(image, numCompX: 9, numCompY: 9).hash;
          val!.picHash = picHash;
        } on BlurHashEncodeException catch (e) {
          logger.e(e.message);
        } finally {
          unlock();
        }
      });
      return;
    }
    if (name == '例句') {
      final examples = form.value!.controls['例句-中文']!.value.split('\n');
      final pinyins = form.value!.controls['例句-拼音']!.value.split('\n');
      final meanings = form.value!.controls['例句-日语']!.value.split('\n');
      doc!.update((val) {
        val!.wordMeanings!.assignAll([
          val.wordMeanings!.single
              .copyWith(examples: examples, examplePinyins: pinyins, exampleMeanings: meanings)
        ]);
      });
      return;
    }
    final updated = form.value!.controls[name!]!.value;
    if (name == 'id') {
      moveRow(doc!, updated);
      return;
    }
    doc!.update((val) {
      switch (name) {
        case '单词':
          val!.word!.assignAll((updated as String).split(''));
          break;
        case '拼音':
          val!.pinyin!.assignAll((updated as String).split('-'));
          break;
        case '词性':
          val!.partOfSentence = updated;
          break;
        case '日语意思':
          val!.wordMeanings!.single.meaning = updated;
          break;
        case '提示':
          val!.hint = updated;
          break;
        case '解释':
          val!.explanation = updated;
          break;
        case '其他意思ID':
          val!.otherMeaningIds = (updated as String).split('/');
          break;
        case '关联单词ID':
          val!.relatedWordIDs = (updated as String).split('/');
          break;
        case 'tags':
          val!.tags!.assignAll(updated.split('/'));
          break;
        default:
          return;
      }
    });
  }

  @override
  void updateStorageFile({required Rx<Word> doc, String? name, List<StorageFile>? storageFiles}) {
    doc.update((val) {
      switch (name) {
        case '图片':
          val!.pic = storageFiles!.single;
          break;
        case '单词音频': // Male then female
          assert(storageFiles!.length == 2);
          val!.wordAudioMale = storageFiles!.first;
          val.wordAudioFemale = storageFiles.last;
          break;
      }
    });
  }
}
