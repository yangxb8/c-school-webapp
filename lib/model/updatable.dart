// Dart imports:
import 'dart:math';
import 'dart:typed_data';

// Package imports:
import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flamingo/flamingo.dart';
import 'package:get/get.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:supercharged/supercharged.dart';

// Project imports:
import 'package:cschool_webapp/service/lecture_service.dart';
import '../service/api_service.dart';
import '../service/logger_service.dart';
import '../view/ui_view/password_require.dart';

/// MUST: All field must have initial value not null EXCEPT for StorageFile
mixin UpdatableDocument<T> on Document<T> {
  /// Increase Id of this doc
  String get increaseId => generateIdFromIndex(indexOfId + 1);

  /// Decrease Id of this doc
  String get decreaseId {
    assert(indexOfId > 1);
    return generateIdFromIndex(indexOfId - 1);
  }

  /// Similar to copyWith but return Rx<T>
  Rx<T> copyWithObservable({String? id}) => Rx<T>(copyWith(id: id));

  /// Get properties of this instance. Example:
  /// 'wordMeanings/0/examples/0/audioMale' => wordMeanings[0].examples[0].audioMale
  Map<String, dynamic> get properties;

  /// Get index of id
  int get indexOfId;

  /// Convert index to id
  String generateIdFromIndex(int index);

  /// create Copy of the document, id MUST be updatable with this method
  T copyWith({String? id});

  /// Don't add StorageFile here. Those will be handled by DocumentUpdateController
  bool equalsTo(dynamic other) {
    if (other !is T) {
      return false;
    }
    for (final field in properties.entries) {
      // Don't compare storageFile
      if (field.value is StorageFile || field.value is List<StorageFile>) {
        continue;
      }
      // If list of String
      if (field.value is List<String>) {
        ListEquality().equals(field.value, other!.properties[field.key]);
      }
      // String or Number
      if (field.value != other!.properties[field.key]) {
        return false;
      }
    }
    return true;
  }
}

/// Used for management of updatable documents
abstract class DocumentUpdateController<T extends UpdatableDocument<T>> extends GetxController {
  static const picExtensions = ['jpg', 'jpeg', 'png'];
  static const audioExtensions = ['mp3'];

  final ApiService apiService = Get.find();

  final lectureService = Get.find<LectureService>();

  final logger = LoggerService.logger;

  /// Nearest formGroup we have
  final form = FormGroup({}).obs;

  /// File been uploaded
  final uploadedFile = PlatformFile().obs;

  /// Get all docs
  RxList<Rx<T>> get docs;

  /// Id could be null. Generate an instance of T
  T generateDocument([String? id]);

  Future<void> handleValueChange({required Rx<T> doc, required String name});

  /// Used for updating storage file
  void updateStorageFile(
      {required Rx<T> doc, required String name, required List<StorageFile> storageFiles});

  /// Handler upload of Docs
  Future<void> handleUpload (PlatformFile uploadedFile);

  /// Get index of id
  int indexOfId(String id) => generateDocument(id).indexOfId;

  /// Convert index to id
  String generateIdFromIndex(int index) {
    if (docs.isNotEmpty) {
      return docs.first.value!.generateIdFromIndex(index);
    } else {
      return generateDocument().generateIdFromIndex(index);
    }
  }

  /// If file name(with extension) is image file
  bool isImageFileName(String filename) =>
      filename.endsWith('png') || filename.endsWith('jpg') || filename.endsWith('jpeg');

  /// storageFile cache of documents. <Document, <FieldName, UpdatableStorageFile>>
  final RxMap<Rx<T>, Map<String, RxList<Rx<UpdatableStorageFile>>>?> _cachedStorageFile = <Rx<T>, Map<String, RxList<Rx<UpdatableStorageFile>>>>{}.obs;

  /// Api Service
  final _apiService = Get.find<ApiService>();

  /// If async action in processing
  final processing = false.obs;

  /// A quick but not accurate indicator of uncommit update. This will be true after first
  /// modification and before cancel/save changes.
  /// For accurately state, call modifiedDocuments.isEmpty (heavy)
  final uncommitUpdateExist = false.obs;

  /// Copy of initial documents for cancel change
  late List<T> _backup;

  /// Logger
  final _logger = LoggerService.logger;

  @override
  void onInit() {
    refreshCachedStorageFile();
    _backup = docs.map((element) => element.value!.copyWith()).toList();
    _initializeWorkers();
    super.onInit();
  }

  /// Refresh cache for all docs
  void refreshCachedStorageFile() {
    // This might happen with empty word list
    if (docs.isEmpty) {
      return;
    }
    if (!tryLock()) return;
    // Unlock after all cache is registered
    _cachedStorageFile.clear();
    once(_cachedStorageFile, (dynamic _) => unlock(),
        condition: () => _cachedStorageFile.length == docs.length);
    for (final doc in docs) {
      _registerCache(doc);
    }
  }

  /// Validate form data. If there is no form, also return true
  bool get validateForm {
    if (form.value!.controls.isEmpty) {
      return true;
    }
    // Mark as touched to show validation message
    form.value!.controls.values.forEach((element) => element.markAsTouched());
    return form.value!.controls.values.every((element) => element.valid);
  }

  /// Get binary data from cache, cache will be updated by upload.
  /// When commit this data is set to StorageFile
  List<Uint8List>? getCachedData(Rx<T> doc, String name) {
    if (!_cachedStorageFile.containsKey(doc)) {
      return null;
    }
    return _cachedStorageFile[doc]![name]?.map((e) => e.value!.data).toList() as List<Uint8List>;
  }

  /// Add updateRecord to cache. This will also update cache date to update view
  void registerCacheUpdateRecord(
      {required Rx<T> doc, required String name, required List<StorageRecord> updateRecords}) {
    _logger.d('Cache $name will be updated for ${doc.value!.id}');
    _cachedStorageFile[doc]![name]!
        .assignAll(updateRecords.map((e) => UpdatableStorageFile.fromStorageRecord(e)));
  }

  /// Add a new doc to docs, this will change all docs below insertion point
  void addRow({required int index}) async {
    // docId start from 1, so index+1
    final newDocId = generateIdFromIndex(index + 1);
    for (var i = 0; i < docs.length; i++) {
      if (i < index) continue;
      final doc = docs[i];
      final movedDoc = doc.value!.copyWithObservable(id: doc.value!.increaseId);
      docs[i] = movedDoc;
      _reassignCache(originRef: doc, newRef: movedDoc);
    }
    final newDoc = Rx<T>(generateDocument(newDocId));
    docs.insert(index, newDoc);
    // Pic is null because it's a new row
    await _registerCache(newDoc);
  }

  /// Delete a doc from docs, this will change all docs below deletion point
  void deleteRow(int index) {
    for (var i = 0; i < docs.length; i++) {
      if (i <= index) continue;
      final doc = docs[i];
      final movedDoc = doc.value!.copyWithObservable(id: doc.value!.decreaseId);
      docs[i] = movedDoc;
      _reassignCache(originRef: doc, newRef: movedDoc);
    }
    _removeCache(docs.removeAt(index));
    // removeAt is not observed properly somehow, manually refresh it
    docs.refresh();
  }

  /// When id is changed, doc will be moved to new id. This will cause all docs between
  /// fromId and toId to change. If doc is inserted above, all docs before should descend.
  /// If doc is inserted below, all docs after should ascend.
  void moveRow(Rx<T> fromDoc, String toId) {
    final fromIndex = fromDoc.value!.indexOfId - 1; // doc id start from 1
    final toIndex = indexOfId(toId) - 1; // doc id start from 1
    final length = toIndex - fromIndex;
    final delta = length > 0 ? -1 : 1;
    final range = length.rangeTo(0).sortedBy<num>((e) => e.abs())..remove(0);
    // Move rows between fromIndex and toIndex
    range.forEach((i) {
      // 0 is the target document, we will deal with it later
      final beforeMoveDoc = docs[fromIndex + i];
      final afterMoveDoc = beforeMoveDoc.value!
          .copyWithObservable(id: generateIdFromIndex(beforeMoveDoc.value!.indexOfId + delta));
      docs[fromIndex + i + delta] = afterMoveDoc;
      _reassignCache(originRef: beforeMoveDoc, newRef: afterMoveDoc);
    });
    // Move target row
    final targetToDoc = fromDoc.value!.copyWithObservable(id: toId);
    docs[toIndex] = targetToDoc;
    _reassignCache(originRef: fromDoc, newRef: targetToDoc);
    docs.refresh(); // reassign is not observable so we refresh it manually
  }

  /// Cancel all changed made and restore _backup
  void cancelChange() {
    docs.assignAll(_backup.map((e) => e.copyWithObservable()));
    _initializeWorkers();
    refreshCachedStorageFile();
    uncommitUpdateExist.value = false;
  }

  /// Save change to remote
  void saveChange() {
    if (!tryLock()) return;
    showPasswordRequireDialog(
        success: () async {
          // Batch should be obtained before _commitStorage(), as StorageRecord will be
          // clear during _commitStorage() and no update will be detected
          final batch = modifiedDocuments;
          await _commitStorage();
          await _apiService.firestoreApi.commitBatch(batch);
          uncommitUpdateExist.value = false;
        },
        last: () => unlock());
  }

  /// Calculate modified documents by compare _backup with docs now.
  Map<Rx<T>, String> get modifiedDocuments {
    final modified = <Rx<T>, String>{};
    final cacheEntries = _cachedStorageFile.entries.toList();
    final cacheLength = _cachedStorageFile.length;
    final backupLength = _backup.length;
    // Add row or Delete row will cause length difference
    for (var i = 0; i < max(cacheLength, backupLength); i++) {
      // When cache shorter than backup, delete those records in backup.
      // Even if deletion happened before this point, we should have move doc up so it's safe.
      if (i >= cacheLength) {
        modified[Rx<T>(_backup[i])] = 'delete';
        continue;
        // When cache longer than backup, save those records in cache.
        // Even if Insertion happened before this point, we should have move doc down.
      } else if (i >= backupLength) {
        modified[cacheEntries[i].key] = 'save';
        continue;
      }
      final cache = cacheEntries[i].key;
      final backup = _backup[i];
      // Document without createdAt timestamp is newly created
      if (cache.value!.createdAt == null) {
        modified[cache] = 'save';
        // Document with createdAt timestamp and different content is updated
      } else if (!cache.value!.equalsTo(backup) ||
          _uncommitCachedStorageFileExits(cacheEntries[i].value!)) {
        modified[cache] = 'update';
      }
    }
    return modified;
  }

  /// WARN: Remember to call unlock or we are stuck
  /// Try lock processing for async action, return true if success
  bool tryLock() {
    if (processing.isTrue!) {
      _logger.e('Async action is called while processing last request');
      Get.snackbar('处理中...', '请稍后再试');
      return false;
    }
    processing.toggle();
    return true;
  }

  /// unlock processing, return true if success
  bool unlock() {
    if (processing.isFalse) {
      _logger.e('unlock is called while processing is false');
      return false;
    }
    processing.toggle();
    return true;
  }

  /// Csv file will be converted to UTF-8 String with name 'csv', binary file will be converted to Uint8List
  Map<String, Uint8List?> unArchive(PlatformFile uploadedFile) {
    final files = <String, Uint8List?>{};
    final archive = ZipDecoder().decodeBytes(uploadedFile.bytes!);
    // Extract the contents of the Zip archive
    for (final file in archive) {
      final filename = file.name;
      if (filename.startsWith('_')) {
        continue;
      }
      if (filename.endsWith('csv')) {
        files['csv'] = file.content as Uint8List?;
      } else if (isImageFileName(filename)) {
        files[filename] = file.content as Uint8List?;
      }
    }
    return files;
  }

  /// Name convention to calculate allowed extensions for file pick
  List<String> calculateAllowedExtensions(String field) {
    if (field.contains('pic')) return picExtensions;
    if (field.contains('audio')) return audioExtensions;
    return [];
  }

  /// Add cache to _cachedStorageFile, this is used when new data inserted
  /// Make sure only StorageFile can be null in UpdatableDocument!
  Future<void> _registerCache(Rx<T> doc) async {
    final map = <String, RxList<Rx<UpdatableStorageFile>>>{};
    for (final entry in doc.value!.properties.entries) {
      if (entry.value == null || entry.value is StorageFile) {
        map[entry.key] = [await UpdatableStorageFile.cacheFileAndObserve(entry.value)].obs;
      } else if (entry.value is List<StorageFile>) {
        var list = <Rx<UpdatableStorageFile>>[].obs;
        await Future.forEach(entry.value,
            (StorageFile element) async => await UpdatableStorageFile.cacheFileAndObserve(element));
        map[entry.key] = list;
      }
    }
    if (map.isNotEmpty) {
      _cachedStorageFile[doc] = map;
    }
  }

  /// Remove associated cache, used in delete row action
  void _removeCache(Rx<T> doc) => _cachedStorageFile.remove(doc);

  /// Reassign UpdatableStorageFile to new Rx<T> instance, used in add/delete/move row action
  void _reassignCache({required Rx<T> originRef, required Rx<T> newRef}) {
    _cachedStorageFile[newRef] = _cachedStorageFile[originRef];
    _cachedStorageFile.remove(originRef);
  }

  bool _uncommitCachedStorageFileExits(Map<String, RxList<Rx<UpdatableStorageFile>>> fields) =>
      fields.values.any((files) => files.any((file) => file.value!.hasRecord));

  /// Commit all cache to Storage and update StorageFile accordingly
  Future<void> _commitStorage() async {
    for (final entry in _cachedStorageFile.entries) {
      final doc = entry.key;
      for (final field in entry.value!.entries) {
        final fieldName = field.key;
        var updateList = <StorageFile>[];
        for (final f in field.value) {
          if (f.value!.hasRecord) {
            updateList.add((await f.value!.upload())!);
          }
        }
        if (updateList.isNotEmpty) {
          updateStorageFile(doc: doc, name: fieldName, storageFiles: updateList);
        }
      }
    }
  }

  /// Worker to monitor each doc change.
  void _initializeWorkers() {
    ever(docs, (dynamic val) {
      _resetInput();
      uncommitUpdateExist.value = true;
    });
    docs.forEach((doc) => ever<T?>(doc, (val) {
          uncommitUpdateExist.value = true;
          _resetInput();
          _logger.d('$doc is updated to ${val!.properties}');
        }));
  }

  void _resetInput() {
    uploadedFile(PlatformFile());
  }
}

/// A storagefile with it's memory cache as we can't use temp file to cache in browser.
/// TODO: When handling large amount of data, this might pump up memory usage
class UpdatableStorageFile {
  /// Update record of this storagefile
  StorageRecord? _updateRecord;

  /// If updatedRecord is set. Data will represent the data in record(updated data)
  /// Otherwise, data is storageFile data(origin data)
  Uint8List? data;

  /// A reference to Rx<UpdatableStorageFile> of self;
  late final Rx<UpdatableStorageFile> _observableRef;

  /// Private constructor
  UpdatableStorageFile._internal();

  /// If update record is registered with this storagefile
  bool get hasRecord => _updateRecord != null;

  static Rx<UpdatableStorageFile> fromStorageRecord(StorageRecord record) {
    final instance = UpdatableStorageFile._internal();
    instance._observableRef = instance.obs;
    instance.updateRecord = record;
    return instance._observableRef;
  }

  /// Download data of storagefile and cache it in memory. The instance is Rx and observable
  static Future<Rx<UpdatableStorageFile>> cacheFileAndObserve(StorageFile? storageFile) async {
    final instance = UpdatableStorageFile._internal();
    instance.data = storageFile == null
        ? null
        : (await Dio().get<Uint8List>(
            storageFile.url,
            options: Options(responseType: ResponseType.bytes),
          ))
            .data;
    instance._observableRef = instance.obs;
    return instance._observableRef;
  }

  /// Upload cache file to storage and delete the record.
  /// Return uploaded StorageFile
  Future<StorageFile?> upload() async {
    if (!hasRecord) {
      LoggerService.logger.i('No record found for this StorageFile! Return null');
      return null;
    }
    final result = await Get.find<ApiService>().firestoreApi.uploadFile(
        path: _updateRecord!.path,
        data: data!,
        filename: _updateRecord!.filename,
        mimeType: _updateRecord!.mimeType!,
        metadata: _updateRecord!.metadata);
    // After upload file, clear the record
    _updateRecord = null;
    _observableRef.refresh();
    return result;
  }

  /// When record(new data) is added, replace data with new data and register the record
  set updateRecord(StorageRecord updateRecord) {
    _updateRecord = updateRecord;
    data = updateRecord.data;
    _observableRef.refresh();
  }

  /// Getter
  StorageRecord get updateRecord => _updateRecord!;
}

/// Information needed for uploading file to storage
class StorageRecord {
  /// Storage path
  final String path;

  /// Binary data
  final Uint8List? data;

  /// Filename with extension
  final String filename;

  /// mimeType
  final String? mimeType;

  /// metaData
  final Map<String, String> metadata;

  StorageRecord(
      {required this.path,
      required this.data,
      required this.filename,
      this.metadata = const {'newPost': 'true'}})
      : mimeType = _guessMimeType(filename);

  static String? _guessMimeType(String filename) {
    if (filename.endsWith('png')) {
      return mimeTypePng;
    } else if (filename.endsWith('jpg') || filename.endsWith('jpeg')) {
      return mimeTypeJpeg;
    }
    if (filename.endsWith('mp3')) {
      return mimeTypeMpeg;
    }
    return null;
  }
}
