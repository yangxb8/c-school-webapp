// 🐦 Flutter imports:
import 'dart:typed_data';

import '../model/show_properties.dart';
import 'package:cschool_webapp/service/api_service.dart';
import 'package:cschool_webapp/service/logger_service.dart';
import 'package:dio/dio.dart';
import 'package:flamingo/flamingo.dart';
import 'package:flutter/material.dart';

// 📦 Package imports:
import 'package:after_layout/after_layout.dart';
import 'package:get/get.dart';

/// Wrapper for stateful functionality to provide onInit calls in stateles widget
class StatefulWrapper extends StatefulWidget {
  final Function onInit;
  final Function didUpdateWidget;
  final Function deactivate;
  final Function dispose;
  final Function afterFirstLayout;
  final Widget child;
  const StatefulWrapper(
      {this.onInit,
      this.afterFirstLayout,
      @required this.child,
      this.didUpdateWidget,
      this.deactivate,
      this.dispose});
  @override
  _StatefulWrapperState createState() => _StatefulWrapperState();
}

class _StatefulWrapperState extends State<StatefulWrapper> with AfterLayoutMixin<StatefulWrapper> {
  @override
  void initState() {
    if (widget.onInit != null) {
      widget.onInit();
    }
    super.initState();
  }

  @override
  void afterFirstLayout(BuildContext context) {
    if (widget.afterFirstLayout != null) {
      widget.afterFirstLayout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void didUpdateWidget(Widget oldWidget) {
    if (widget.didUpdateWidget != null) {
      widget.didUpdateWidget(oldWidget);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void deactivate() {
    if (widget.deactivate != null) {
      widget.deactivate();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    if (widget.dispose != null) {
      widget.dispose();
    }
    super.dispose();
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
      : path = storageFile.path.replaceAll('/${storageFile.name}', ''),
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
    instance.data = (await Dio().get<Uint8List>(
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
    return await Get.find<ApiService>().firestoreApi.uploadFile(
        path: _updateRecord.path,
        data: data,
        filename: _updateRecord.filename,
        mimeType: _updateRecord.mimeType,
        metadata: _updateRecord.metadata);
  }

  /// Register a StorageRecord. This will refresh the data. The refresh is observable.
  void registerUpdateRecord(StorageRecord updateRecord) {
    _updateRecord = updateRecord;
    data = updateRecord.data;
    _observableRef.refresh();
  }

  StorageRecord get updateRecord => _updateRecord;
}

class UpdatableStorageManager<T extends ShowProperties> {
  final cachedStorageFile = <Rx<T>, Map<String, Rx<UpdatableStorageFile>>>{}.obs;
  final RxList<Rx<T>> docs;

  UpdatableStorageManager(this.docs);

  /// Refresh cache for all lectures
  Future<void> refreshCachedStorageFile() async {
    cachedStorageFile.clear();
    await Future.forEach(docs, (Rx<T> doc) async {
      final map = <String, Rx<UpdatableStorageFile>>{};
      for (final entry in doc.value.properties.entries) {
        if (entry.value is StorageFile) {
          map[entry.key] = await UpdatableStorageFile.cacheFileAndObserve(entry.value);
        }
      }
      if (map.isNotEmpty) {
        cachedStorageFile[doc] = map;
      }
    });
  }

  Uint8List getCachedData(Rx<T> doc, String name) => cachedStorageFile[doc][name].value?.data;

  /// Reassign UpdatableStorageFile to new Rx<T> instance
  void reassignCache({@required Rx<T> originRef, @required Rx<T> newRef}) {
    cachedStorageFile[newRef] = cachedStorageFile[originRef];
    cachedStorageFile.remove(originRef);
  }

  void registerUpdateRecord(
          {@required Rx<T> doc, @required String name, @required StorageRecord updateRecord}) =>
      cachedStorageFile[doc][name].value.registerUpdateRecord(updateRecord);

  /// Commit all cache to Storage and update StorageFile accordingly
  Future<void> commit() async {
    for(final entry in cachedStorageFile.entries){
      final doc = entry.key;
      for(final field in entry.value.entries){
        final fieldName = field.key;
        final updatableStorageFile = field.value.value;
        doc.value.properties[fieldName] = await updatableStorageFile.update();
      }
      doc.refresh();
    }
  }
}
