// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'speech_evaluation_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpeechEvaluationResult _$SpeechEvaluationResultFromJson(
    Map<String, dynamic> json) {
  return SpeechEvaluationResult(
    userId: json['userId'] as String?,
    examId: json['examId'] as String?,
    speechDataPath: json['speechDataPath'] as String?,
    sentenceInfo: json['sentenceInfo'] == null
        ? null
        : SentenceInfo.fromJson(json['sentenceInfo'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$SpeechEvaluationResultToJson(
        SpeechEvaluationResult instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'examId': instance.examId,
      'speechDataPath': instance.speechDataPath,
      'sentenceInfo': instance.sentenceInfo,
    };

SentenceInfo _$SentenceInfoFromJson(Map<String, dynamic> json) {
  return SentenceInfo(
    suggestedScore: (json['SuggestedScore'] as num?)?.toDouble(),
    pronAccuracy: (json['PronAccuracy'] as num?)?.toDouble(),
    pronFluency: (json['PronFluency'] as num?)?.toDouble(),
    pronCompletion: (json['PronCompletion'] as num?)?.toDouble(),
    words: (json['Words'] as List<dynamic>?)
        ?.map((e) => WordInfo.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$SentenceInfoToJson(SentenceInfo instance) =>
    <String, dynamic>{
      'SuggestedScore': instance.suggestedScore,
      'PronAccuracy': instance.pronAccuracy,
      'PronFluency': instance.pronFluency,
      'PronCompletion': instance.pronCompletion,
      'Words': instance.words,
    };

WordInfo _$WordInfoFromJson(Map<String, dynamic> json) {
  return WordInfo(
    beginTime: json['MemBeginTime'] as int?,
    endTime: json['MemEndTime'] as int?,
    referenceWord: json['ReferenceWord'] as String?,
    pronAccuracy: (json['PronAccuracy'] as num?)?.toDouble(),
    pronFluency: (json['PronFluency'] as num?)?.toDouble(),
    word: json['Word'] as String?,
    matchTag: MatchResultUtil.fromInt(json['MatchTag'] as int?),
    phoneInfos: (json['PhoneInfos'] as List<dynamic>?)
        ?.map((e) => PhoneInfo.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$WordInfoToJson(WordInfo instance) => <String, dynamic>{
      'MemBeginTime': instance.beginTime,
      'MemEndTime': instance.endTime,
      'PronAccuracy': instance.pronAccuracy,
      'PronFluency': instance.pronFluency,
      'Word': instance.word,
      'MatchTag': EnumToString.convertToString(instance.matchTag),
      'PhoneInfos': instance.phoneInfos,
      'ReferenceWord': instance.referenceWord,
    };

PhoneInfo _$PhoneInfoFromJson(Map<String, dynamic> json) {
  return PhoneInfo(
    beginTime: json['MemBeginTime'] as int?,
    endTime: json['MemEndTime'] as int?,
    referenceStress: json['Stress'] as bool?,
    referencePhone: json['ReferencePhone'] as String?,
    pronAccuracy: (json['PronAccuracy'] as num?)?.toDouble(),
    detectedStress: json['DetectedStress'] as bool?,
    detectedPhone: json['Phone'] as String?,
    matchTag: MatchResultUtil.fromInt(json['MatchTag'] as int?),
  );
}

Map<String, dynamic> _$PhoneInfoToJson(PhoneInfo instance) => <String, dynamic>{
      'MemBeginTime': instance.beginTime,
      'MemEndTime': instance.endTime,
      'PronAccuracy': instance.pronAccuracy,
      'DetectedStress': instance.detectedStress,
      'Stress': instance.referenceStress,
      'Phone': instance.detectedPhone,
      'ReferencePhone': instance.referencePhone,
      'MatchTag': EnumToString.convertToString(instance.matchTag),
    };
