// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'speech_exam.dart';

// **************************************************************************
// FieldValueGenerator
// **************************************************************************

/// Field value key
enum SpeechExamKey {
  refText,
  _mode,

  refAudio,
}

extension SpeechExamKeyExtension on SpeechExamKey {
  String get value {
    switch (this) {
      case SpeechExamKey.refText:
        return 'refText';
      case SpeechExamKey._mode:
        return '_mode';
      case SpeechExamKey.refAudio:
        return 'refAudio';
      default:
        return null;
    }
  }
}

/// For save data
Map<String, dynamic> _$toData(SpeechExam doc) {
  final data = <String, dynamic>{};
  Helper.writeNotNull(data, 'refText', doc.refText);
  Helper.writeNotNull(data, '_mode', doc._mode);

  Helper.writeStorageNotNull(data, 'refAudio', doc.refAudio, isSetNull: true);

  return data;
}

/// For load data
void _$fromData(SpeechExam doc, Map<String, dynamic> data) {
  doc.refText = Helper.valueFromKey<String>(data, 'refText');
  doc._mode = Helper.valueFromKey<String>(data, '_mode');

  doc.refAudio = Helper.storageFile(data, 'refAudio');
}
