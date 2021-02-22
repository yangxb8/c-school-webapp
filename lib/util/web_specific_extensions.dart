import 'dart:typed_data';

import 'package:flamingo/flamingo.dart';


extension StorageExtension on Storage {
  Future<StorageFile> saveFromBytes(
    String folderPath,
    Uint8List data, {
    String filename,
    String mimeType = mimeTypeApplicationOctetStream,
    Map<String, String> metadata = const <String, String>{},
    Map<String, dynamic> additionalData = const <String, dynamic>{},
  }) async {
    final refFilename = filename ?? Storage.fileName();
    final refMimeType = mimeType ?? '';
    final path = '$folderPath/$refFilename';
    final ref = storage.ref().child(path);
    final settableMetadata = SettableMetadata(contentType: refMimeType, customMetadata: metadata);
    UploadTask uploadTask;
    uploadTask = ref.putData(data, settableMetadata);
    final snapshot = await uploadTask.whenComplete(() => null);
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return StorageFile(
      name: refFilename,
      url: downloadUrl,
      path: path,
      mimeType: refMimeType,
      metadata: metadata,
      additionalData: additionalData,
    );
  }
}

extension StorageFileExtension on StorageFile {
  String get dirPath => path.replaceFirst('/$name', '');

  StorageFile copy() {
    return StorageFile(
        name: name,
        path: dirPath,
        url: url,
        mimeType: mimeType,
        metadata: metadata,
        additionalData: additionalData);
  }
}

extension BatchExtension on Batch {
  Map<String, Function> get actions => {'save': save, 'update': update, 'delete': delete};
}
