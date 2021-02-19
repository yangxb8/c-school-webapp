import 'dart:typed_data';

import 'package:flamingo/flamingo.dart';

import '../model/lecture.dart';

extension LectureExtension on Lecture {
  Map<String, dynamic> get properties => {
        'title': title,
        'lectureId': lectureId,
        'description': description,
        'level': level,
        'tags': tags,
        'pic': pic,
        'picHash': picHash
      };
  Lecture copyWith({String id, int level, String title, String description, List<String> tags}) {
    return Lecture(id: id ?? this.id, level: level ?? this.level)
      ..title = title ?? this.title
      ..description = description ?? this.description
      ..tags = tags ?? this.tags
      ..pic = pic
      ..picHash = picHash;
  }
}

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

extension BatchExtension on Batch {
  Map<String, Function> get actions => {'save': save, 'update': update, 'delete': delete};
}
