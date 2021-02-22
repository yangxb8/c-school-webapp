import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flamingo/flamingo.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supercharged/supercharged.dart';

import '../util/utility.dart';
import '../service/api_service.dart';
import '../service/logger_service.dart';
import '../view/ui_view/password_require.dart';

/// MUST: also use [EquatableMixin] or this will break
mixin UpdatableDocument<T> on Document<T>{

  /// Increase Id of this doc
  String get increaseId => generateIdFromIndex(indexOfId);
  /// Decrease Id of this doc

  String get decreaseId {
    assert(indexOfId > 1);
    return generateIdFromIndex(indexOfId - 1);
  }

  /// Override Document method to be compatible with EquatableMixin
  @override
  String get modelName => toString().toLowerCase();

  /// Get properties of this instance. Example:
  /// 'wordMeanings/0/examples/0/audioMale' => wordMeanings[0].examples[0].audioMale
  Map<String, dynamic> get properties;

  /// Get index of id
  int get indexOfId;

  /// Convert index to id
  String generateIdFromIndex(int index);

  /// create Copy of the document, id MUST be updatable with this method
  T copyWith({String id});

}

abstract class DocumentUpdateDelegate<T extends UpdatableDocument<T>> extends GetxController {
  RxList<Rx<T>> get docs;

  /// Generate an instance of T
  T generateDocument(String id);

  /// Handler of value change of T
  Future<void> handleValueChange(
      {@required Rx<T> lecture, @required String name, @required dynamic updated});

  /// Handler upload of Docs
  Future<void> handleUpload(Uint8List uploadedFile);

  /// Get index of id
  int indexOfId(String id) => generateDocument(id).indexOfId;

  /// Convert index to id
  String generateIdFromIndex(int index) => generateDocument('').generateIdFromIndex(index);
}

mixin DocumentUpdateMixin<T extends UpdatableDocument<T>> on DocumentUpdateDelegate<T> {
  /// storageFile cache of documents. <Document, <FieldName, UpdatableStorageFile>>
  final _cachedStorageFile = <Rx<T>, Map<String, Rx<UpdatableStorageFile>>>{}.obs;

  /// Api Service
  final _apiService = Get.find<ApiService>();

  /// If async action in processing
  final processing = false.obs;

  /// A quick but not accurate indicator of uncommit update. This will be true after first
  /// modification and before cancel/save changes.
  /// For accurately state, call modifiedDocuments.isEmpty (heavy)
  final uncommitUpdateExist = false.obs;

  /// Copy of initial documents for cancel change
  List<T> _backup;

  /// Logger
  final _logger = LoggerService.logger;

  @override
  void onInit() {
    refreshCachedStorageFile();
    _backup = docs.map((element) => element.value.copyWith()).toList();
    _initializeWorkers();
    super.onInit();
  }

  /// Refresh cache for all docs
  Future<void> refreshCachedStorageFile() async {
    if (processing.isTrue) {
      _logger.e('Async action is called while processing last request');
      return;
    }
    processing.toggle();
    _cachedStorageFile.clear();
    await Future.forEach(docs, (Rx<T> doc) async {
      await registerCache(doc);
    });
    processing.toggle();
  }

  /// Get binary data from cache, cache will be updated by upload.
  /// When commit this data is set to StorageFile
  Uint8List getCachedData(Rx<T> doc, String name) {
    if (_cachedStorageFile.containsKey(doc) && _cachedStorageFile[doc].containsKey(name)) {
      return _cachedStorageFile[doc][name]?.value?.data;
    }
    return null;
  }

  /// Add a new doc to docs, this will change all docs below insertion point
  void addRow({@required int index, @required List<String> nullableFields}) {
    // docId start from 1, so index+1
    final newDocId = docs[index + 1].value.id;
    for (var i = 0; i < docs.length; i++) {
      if (i < index) continue;
      final doc = docs[i];
      final movedDoc = doc.value.copyWith(id: doc.value.increaseId).obs;
      docs[i] = movedDoc;
      reassignCache(originRef: doc, newRef: movedDoc);
    }
    final newDoc = generateDocument(newDocId).obs;
    docs.insert(index, newDoc);
    // Pic is null because it's a new row
    registerCache(newDoc, nullableFields: ['pic']);
  }

  /// Delete a doc from docs, this will change all docs below deletion point
  void deleteRow(int index) {
    final target = docs.removeAt(index);
    for (var i = 0; i < docs.length; i++) {
      if (i < index) continue;
      final doc = docs[i];
      final movedDoc = doc.value.copyWith(id: doc.value.decreaseId).obs;
      docs[i] = movedDoc;
      reassignCache(originRef: doc, newRef: movedDoc);
    }
    removeCache(target);
  }

  /// When id is changed, doc will be moved to new id. This will cause all docs between
  /// fromId and toId to change. If doc is inserted above, all docs before should descend.
  /// If doc is inserted below, all docs after should ascend.
  void moveRow(Rx<T> fromDoc, String toId) {
    final fromIndex = fromDoc.value.indexOfId - 1; // doc id start from 1
    final toIndex = indexOfId(toId) - 1; // doc id start from 1
    final length = toIndex - fromIndex;
    final delta = length>0? -1:1;
    final range = length.rangeTo(0).sortedByNum((e) => e.abs())..remove(0);
    // Move rows between fromIndex and toIndex
    range.forEach((i) {
      // 0 is the target document, we will deal with it later
      final beforeMoveDoc = docs[fromIndex + i];
      final afterMoveDoc = beforeMoveDoc.value
          .copyWith(id: generateIdFromIndex(beforeMoveDoc.value.indexOfId+delta))
          .obs;
      docs[fromIndex + i + delta] = afterMoveDoc;
      reassignCache(originRef: beforeMoveDoc, newRef: afterMoveDoc);
    });
    // Move target row
    final targetToDoc = fromDoc.value.copyWith(id: toId).obs;
    docs[toIndex] = targetToDoc;
    reassignCache(originRef: fromDoc, newRef: targetToDoc);
    docs.refresh(); // reassign is not observable so we refresh it manually
  }

  /// Add cache to _cachedStorageFile, this is used when new data inserted
  /// Passing filed names as nullableFields to register null value for field
  /// This could be useful when new record is inserted and StorageFile been null
  void registerCache(Rx<T> doc, {List<String> nullableFields = const []}) async {
    final map = <String, Rx<UpdatableStorageFile>>{};
    for (final entry in doc.value.properties.entries) {
      if (entry.value is StorageFile) {
        map[entry.key] = await UpdatableStorageFile.cacheFileAndObserve(entry.value);
      }
    }
    for (final field in nullableFields) {
      if (!map.containsKey(field)) {
        map[field] = await UpdatableStorageFile.cacheFileAndObserve(null);
      }
    }
    if (map.isNotEmpty) {
      _cachedStorageFile[doc] = map;
    }
  }

  /// Remove associated cache, used in delete row action
  void removeCache(Rx<T> doc) => _cachedStorageFile.remove(doc);

  /// Reassign UpdatableStorageFile to new Rx<T> instance, used in add/delete/move row action
  void reassignCache({@required Rx<T> originRef, @required Rx<T> newRef}) {
    _cachedStorageFile[newRef] = _cachedStorageFile[originRef];
    _cachedStorageFile.remove(originRef);
  }

  /// Add updateRecord to cache. This will also update cache date to update view
  void registerCacheUpdateRecord(
          {@required Rx<T> doc, @required String name, @required StorageRecord updateRecord}) =>
      _cachedStorageFile[doc][name].value.updateRecord = updateRecord;

  /// Cancel all changed made and restore _backup
  void cancelChange() {
    docs.assignAll(_backup.map((e) => e.copyWith().obs));
    _initializeWorkers();
    refreshCachedStorageFile();
    uncommitUpdateExist.value = false;
  }

  /// Save change to remote
  void saveChange() {
    processing.toggle();
    showPasswordRequireDialog(() async {
      await _commitStorage();
      await _apiService.firestoreApi.commitBatch(modifiedDocuments);
      processing.toggle();
      uncommitUpdateExist.value = false;
    });
  }

  Map<T, String> get modifiedDocuments {
    final modifiedDocuments = <T, String>{};
    final cacheEntries = _cachedStorageFile.entries.toList();
    final cacheLength = _cachedStorageFile.length;
    final backupLength = _backup.length;
    // Add row or Delete row will cause length difference
    for (var i = 0; i < max(cacheLength, backupLength); i++) {
      // When cache shorter than backup, delete those records in backup.
      // Even if deletion happened before this point, we should have move doc up so it's safe.
      if (i >= cacheLength) {
        modifiedDocuments[_backup[i]] = 'delete';
        // When cache longer than backup, save those records in cache.
        // Even if Insertion happened before this point, we should have move doc down.
      } else if (i >= backupLength) {
        modifiedDocuments[cacheEntries[i].key.value] = 'save';
        // Document without createdAt timestamp is newly created
      } else if (cacheEntries[i].key.value.createdAt == null) {
        modifiedDocuments[cacheEntries[i].key.value] = 'save';
        // Document with createdAt timestamp and different content is updated
      } else if(cacheEntries[i].key.value != _backup[i]) {
        modifiedDocuments[cacheEntries[i].key.value] = 'update';
      }
    }
    return modifiedDocuments;
  }

  /// Commit all cache to Storage and update StorageFile accordingly
  Future<void> _commitStorage() async {
    processing.toggle();
    if (processing.isTrue) {
      _logger.e('Async action is called while processing last request');
      return;
    }
    for (final entry in _cachedStorageFile.entries) {
      final doc = entry.key;
      for (final field in entry.value.entries) {
        final fieldName = field.key;
        final updatableStorageFile = field.value.value;
        doc.value.properties[fieldName] = await updatableStorageFile.update();
      }
      doc.refresh();
    }
    processing.toggle();
  }

  /// Worker to monitor each doc change.
  void _initializeWorkers() {
    ever(docs, (_) => uncommitUpdateExist.value = true);
    docs.forEach((doc) => ever<T>(doc, (val) {
          uncommitUpdateExist.value = true;
          _logger.d('$doc is updated to ${val.properties}');
        }));
  }
}

class StorageRecord {
  final String path;
  final Uint8List data;
  final String filename;
  final String mimeType;
  final Map<String, String> metadata;

  StorageRecord(this.path, this.data, this.filename, this.mimeType, this.metadata);

  StorageRecord.fromStorageFile({@required StorageFile storageFile, @required this.data})
      : assert(storageFile != null),
        path = storageFile.dirPath,
        filename = storageFile.name,
        mimeType = storageFile.mimeType,
        metadata = storageFile.metadata;
}

class UpdatableStorageFile {
  StorageRecord _updateRecord;

  /// If updatedRecord is set. Data will represent the data in record(updated data)
  /// Otherwise, data is storageFile data(origin data)
  Uint8List data;

  /// A reference to Rx<UpdatableStorageFile> of self;
  Rx<UpdatableStorageFile> _observableRef;

  UpdatableStorageFile._internal();

  bool get hasRecord => _updateRecord != null;

  static Future<Rx<UpdatableStorageFile>> cacheFileAndObserve(StorageFile storageFile) async {
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

  Future<StorageFile> update() async {
    if (!hasRecord) {
      LoggerService.logger.i('No record found for this StorageFile! Return null');
      return null;
    }
    final result = await Get.find<ApiService>().firestoreApi.uploadFile(
        path: _updateRecord.path,
        data: data,
        filename: _updateRecord.filename,
        mimeType: _updateRecord.mimeType,
        metadata: _updateRecord.metadata);
    // After upload file, clear the record
    _updateRecord = null;
    _observableRef.refresh();
    return result;
  }

  set updateRecord(StorageRecord updateRecord) {
    _updateRecord = updateRecord;
    data = updateRecord.data;
    _observableRef.refresh();
  }

  StorageRecord get updateRecord => _updateRecord;
}