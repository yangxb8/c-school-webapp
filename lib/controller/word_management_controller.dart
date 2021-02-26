import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:blurhash_dart/src/exception.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:image/image.dart' as img;
import 'package:supercharged/supercharged.dart';
import 'package:cschool_webapp/model/updatable.dart';
import 'package:cschool_webapp/model/word.dart';
import 'package:file_picker/src/platform_file.dart';
import 'package:flamingo/src/model/storage_file.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

class WordManagementController extends DocumentUpdateController<Word> {
  final String lectureId = Get.arguments;
  RxList<Rx<Word>> _docs;

  @override
  RxList<Rx<Word>> get docs {
    _docs ??= lectureService.findLectureById(lectureId).words.map((w) => w.obs).toList().obs;
    return _docs;
  }

  @override
  Word generateDocument([String id]) => Word(id: id??'$lectureId-001');

  @override
  Future<void> handleUpload(PlatformFile uploadedFile) {
    // TODO: implement handleUpload
    throw UnimplementedError();
  }

  @override
  Future<void> handleValueChange({Rx<Word> doc, String name, dynamic updated}) async {
    if (name == 'id') {
      moveRow(doc, updated);
      return;
    }
    await doc.update((val) async {
      switch (name) {
        case '单词':
          val.word.assignAll((updated as String).split(''));
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
        case '图片':
          final file = updated as PlatformFile;
          final path = '${doc.value.documentPath}/${EnumToString.convertToString(WordKey.pic)}';
          final storageRecord = StorageRecord(
              path: path, data: file.bytes, filename: '${doc.value.id}.${file.extension}');
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

  @override
  void updateStorageFile({Rx<Word> doc, String name, List<StorageFile> storageFiles}) {
    doc.update((val)  {
      switch(name){
        case '图片':
          val.pic = storageFiles.single;
          break;
        case '单词音频': // Male then female
          assert(storageFiles.length==2);
          val.wordAudioMale=storageFiles.first;
          val.wordAudioFemale=storageFiles.last;
          break;
        case '例句音频': // Male then female for every example
          final singleMeaning = val.wordMeanings.single;
          assert(storageFiles.length==singleMeaning.examples.length*2);
          final maleAudio = <StorageFile>[];
          final femaleAudio = <StorageFile>[];
          storageFiles.forEachIndexed((index, file) {
            if(index%2==0){
              maleAudio.add(file);
            } else{
              femaleAudio.add(file);
            }
          });
          singleMeaning.exampleMaleAudios.assignAll(maleAudio);
          singleMeaning.exampleFemaleAudios.assignAll(femaleAudio);
          break;
      }
    });
  }
}
