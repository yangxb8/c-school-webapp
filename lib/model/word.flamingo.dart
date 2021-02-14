// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word.dart';

// **************************************************************************
// FieldValueGenerator
// **************************************************************************

/// Field value key
enum WordKey {
  wordId,
  word,
  pinyin,
  explanation,
  partOfSentence,
  hint,
  _relatedWordIds,
  _otherMeaningIds,
  breakdowns,
  tags,
  picHash,
  wordMeanings,
  pic,
  wordAudioMale,
  wordAudioFemale,
}

extension WordKeyExtension on WordKey {
  String get value {
    switch (this) {
      case WordKey.wordId:
        return 'wordId';
      case WordKey.word:
        return 'word';
      case WordKey.pinyin:
        return 'pinyin';
      case WordKey.explanation:
        return 'explanation';
      case WordKey.partOfSentence:
        return 'partOfSentence';
      case WordKey.hint:
        return 'hint';
      case WordKey._relatedWordIds:
        return '_relatedWordIds';
      case WordKey._otherMeaningIds:
        return '_otherMeaningIds';
      case WordKey.breakdowns:
        return 'breakdowns';
      case WordKey.tags:
        return 'tags';
      case WordKey.picHash:
        return 'picHash';
      case WordKey.wordMeanings:
        return 'wordMeanings';
      case WordKey.pic:
        return 'pic';
      case WordKey.wordAudioMale:
        return 'wordAudioMale';
      case WordKey.wordAudioFemale:
        return 'wordAudioFemale';
      default:
        return null;
    }
  }
}

/// For save data
Map<String, dynamic> _$toData(Word doc) {
  final data = <String, dynamic>{};
  Helper.writeNotNull(data, 'wordId', doc.wordId);
  Helper.writeNotNull(data, 'word', doc.word);
  Helper.writeNotNull(data, 'pinyin', doc.pinyin);
  Helper.writeNotNull(data, 'explanation', doc.explanation);
  Helper.writeNotNull(data, 'partOfSentence', doc.partOfSentence);
  Helper.writeNotNull(data, 'hint', doc.hint);
  Helper.writeNotNull(data, '_relatedWordIds', doc._relatedWordIds);
  Helper.writeNotNull(data, '_otherMeaningIds', doc._otherMeaningIds);
  Helper.writeNotNull(data, 'breakdowns', doc.breakdowns);
  Helper.writeNotNull(data, 'tags', doc.tags);
  Helper.writeNotNull(data, 'picHash', doc.picHash);

  Helper.writeModelListNotNull(data, 'wordMeanings', doc.wordMeanings);

  Helper.writeStorageNotNull(data, 'pic', doc.pic, isSetNull: true);
  Helper.writeStorageNotNull(data, 'wordAudioMale', doc.wordAudioMale,
      isSetNull: true);
  Helper.writeStorageNotNull(data, 'wordAudioFemale', doc.wordAudioFemale,
      isSetNull: true);

  return data;
}

/// For load data
void _$fromData(Word doc, Map<String, dynamic> data) {
  doc.wordId = Helper.valueFromKey<String>(data, 'wordId');
  doc.word = Helper.valueListFromKey<String>(data, 'word');
  doc.pinyin = Helper.valueListFromKey<String>(data, 'pinyin');
  doc.explanation = Helper.valueFromKey<String>(data, 'explanation');
  doc.partOfSentence = Helper.valueFromKey<String>(data, 'partOfSentence');
  doc.hint = Helper.valueFromKey<String>(data, 'hint');
  doc._relatedWordIds =
      Helper.valueListFromKey<String>(data, '_relatedWordIds');
  doc._otherMeaningIds =
      Helper.valueListFromKey<String>(data, '_otherMeaningIds');
  doc.breakdowns = Helper.valueListFromKey<String>(data, 'breakdowns');
  doc.tags = Helper.valueListFromKey<String>(data, 'tags');
  doc.picHash = Helper.valueFromKey<String>(data, 'picHash');

  final _wordMeanings =
      Helper.valueMapListFromKey<String, dynamic>(data, 'wordMeanings');
  if (_wordMeanings != null) {
    doc.wordMeanings = _wordMeanings
        .where((d) => d != null)
        .map((d) => WordMeaning(values: d))
        .toList();
  } else {
    doc.wordMeanings = null;
  }

  doc.pic = Helper.storageFile(data, 'pic');
  doc.wordAudioMale = Helper.storageFile(data, 'wordAudioMale');
  doc.wordAudioFemale = Helper.storageFile(data, 'wordAudioFemale');
}
