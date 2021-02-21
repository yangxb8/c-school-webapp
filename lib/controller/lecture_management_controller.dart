import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:cschool_webapp/model/lecture.dart';
import 'package:cschool_webapp/service/api_service.dart';
import 'package:supercharged/supercharged.dart';
import 'package:cschool_webapp/service/audio_service.dart';
import 'package:cschool_webapp/service/lecture_service.dart';
import 'package:flamingo/flamingo.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../model/lecture.dart';
import '../util/utility.dart';

class LectureManagementController extends GetxController {
  final LectureService lectureService = Get.find();
  final AudioService audioService = Get.find();
  final ApiService apiService = Get.find();
  final storage = Storage()..fetch();
  final loading = true.obs;

  /// A set to store changed made to list
  final RxSet<Map<String, Rx<Lecture>>> batchSet = <Map<String, Rx<Lecture>>>{}.obs;
  RxList<Rx<Lecture>> allLecturesObx;

  UpdatableStorageManager<Lecture> storageManager;

  /// backup for restore data
  List<Lecture> _backup;

  @override
  void onInit() {
    allLecturesObx = LectureService.allLecturesObx;
    storageManager = UpdatableStorageManager(allLecturesObx);
    _refreshCachedStorageFile();
    // A backup of initial state for restore changes
    _backup = allLecturesObx.map((element) => element.value.copyWith()).toList();
    _initializeWorkers();
    super.onInit();
  }

  Uint8List getCachedData(Rx<Lecture> doc, String name) => storageManager.getCachedData(doc, name);

  void addRow(int index) {
    allLecturesObx.forEachIndexed((idx, lecture) {
      if (idx < index) return;
      lecture.update((val) => val.lectureId = increaseLectureId(val.lectureId));
    });
    // lectureId start from 1, so index+1
    final newLecture = Lecture(id: generateLectureIdFromIndex(index + 1)).obs;
    allLecturesObx.insert(index, newLecture);
    // Manually add newLecture to batchSet
    batchSet.add({'save': newLecture});
  }

  void deleteRow(int index) {
    final target = allLecturesObx.removeAt(index);
    allLecturesObx.forEachIndexed((idx, lecture) {
      if (idx < index) return;
      lecture.update((val) => val.lectureId = decreaseLectureId(val.lectureId));
    });
    batchSet.add({'delete': target});
  }

  void moveRow(String fromId, String toId) {
    final toIndex = getIndexOfWordId(toId);
    final target = allLecturesObx.removeAt(getIndexOfWordId(fromId) - 1);
    target.update((val) => val.lectureId = toId);
    allLecturesObx.forEachIndexed((index, lecture) {
      if (index + 1 < toIndex) return;
      lecture.update((val) => val.lectureId = increaseLectureId(val.lectureId));
    });
    allLecturesObx.insert(toIndex - 1, target);
  }

  Future<void> handlerValueChange(
      {@required Rx<Lecture> lecture, @required String name, @required dynamic updated}) async {
    // If lectureId is changed, move the row
    if (name == 'lectureId' && updated is String) {
      moveRow(lecture.value.lectureId, updated);
      return;
    }
    var origin = lecture.value.properties[name];
    if (origin is String && updated is String) {
      _updateProperties(lecture: lecture, property: name, newVal: updated);
    } else if (origin is List<String> && updated is String) {
      // tags
      _updateProperties(lecture: lecture, property: name, newVal: updated.split('/'));
    } else if (origin is int && updated is String) {
      _updateProperties(lecture: lecture, property: name, newVal: int.parse(updated));
    } else if (origin is StorageFile && updated is Uint8List) {
      storageManager.registerUpdateRecord(
          doc: lecture,
          name: name,
          updateRecord: StorageRecord.fromStorageFile(
              storageFile: lecture.value.properties[name], data: updated));
      final picHash = await encodeBlurHash(updated, 9, 9);
      _updateProperties(lecture: lecture, property: 'picHash', newVal: picHash);
    }
  }

  /// Upload lectures with zip file
  Future<void> handleLectureUpload(Uint8List uploadedFile) async {
    String csvContent;
    Map<String, Uint8List> assets;
    final archive = ZipDecoder().decodeBytes(uploadedFile);
    // Extract the contents of the Zip archive
    for (final file in archive) {
      final filename = file.name;
      if (filename.endsWith('csv')) {
        csvContent = Utf8Decoder().convert(file.content as Uint8List);
      } else if (filename.endsWith('jpg') || filename.endsWith('png')) {
        assets[filename] = file.content as Uint8List;
      }
    }
    await apiService.firestoreApi.uploadLecturesByCsv(csv: csvContent, assets: assets);
  }

  void _updateProperties(
      {@required Rx<Lecture> lecture, @required String property, @required dynamic newVal}) {
    lecture.update((val) {
      switch (property) {
        case 'lectureId':
          val.lectureId = newVal;
          break;
        case 'title':
          val.title = newVal;
          break;
        case 'description':
          val.description = newVal;
          break;
        case 'level':
          val.level = newVal;
          break;
        case 'tags':
          val.tags.assignAll(newVal);
          break;
        case 'pic':
          val.pic = newVal;
          break;
        case 'picHash':
          val.picHash = newVal;
          break;
      }
    });
  }

  void saveChange() async {
    await storageManager.commit();
    await apiService.firestoreApi.commitBatch(batchSet);
  }

  void cancelChange() {
    loading.toggle();
    allLecturesObx.assignAll(_backup.map((e) => e.copyWith().obs));
    _initializeWorkers();
    _refreshCachedStorageFile();
    batchSet.clear();
  }

  /// Worker to monitor each lecture change. This only works for existed
  /// Lecture, so if you add a new lecture and modify it, it will not be
  /// handled by worker, manually add it to the set.
  void _initializeWorkers() => allLecturesObx.forEach((lecture) => ever<Lecture>(lecture, (val) {
        logger.d('$lecture is updated to ${val.properties}');
        batchSet.add({'update': lecture});
      }));

  /// Refresh cache for all lectures
  Future<void> _refreshCachedStorageFile() async {
    await storageManager.refreshCachedStorageFile();
    loading.toggle();
  }

  bool isPropertyChanged(Rx<Lecture> lecture, String name) => throw UnimplementedError();
}
