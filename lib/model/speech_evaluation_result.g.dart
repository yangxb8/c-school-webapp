// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'speech_evaluation_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpeechEvaluationResult _$SpeechEvaluationResultFromJson(
    Map<String, dynamic> json) {
  return SpeechEvaluationResult(
    userId: json['userId'] as String,
    examId: json['examId'] as String,
    speechDataPath: json['speechDataPath'] as String,
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
    suggestedScore: (json['suggestedScore'] as num)?.toDouble(),
    pronAccuracy: (json['pronAccuracy'] as num)?.toDouble(),
    pronFluency: (json['pronFluency'] as num)?.toDouble(),
    pronCompletion: (json['pronCompletion'] as num)?.toDouble(),
    words: (json['words'] as List)
        ?.map((e) =>
            e == null ? null : WordInfo.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$SentenceInfoToJson(SentenceInfo instance) =>
    <String, dynamic>{
      'suggestedScore': instance.suggestedScore,
      'pronAccuracy': instance.pronAccuracy,
      'pronFluency': instance.pronFluency,
      'pronCompletion': instance.pronCompletion,
      'words': instance.words,
    };

WordInfo _$WordInfoFromJson(Map<String, dynamic> json) {
  return WordInfo(
    beginTime: json['beginTime'] as int,
    endTime: json['endTime'] as int,
    referenceWord: json['referenceWord'] as String,
    pronAccuracy: (json['pronAccuracy'] as num)?.toDouble(),
    pronFluency: (json['pronFluency'] as num)?.toDouble(),
    word: json['word'] as String,
    matchTag: MatchResultUtil.fromInt(json['matchTag'] as int),
    phoneInfos: (json['phoneInfos'] as List)
        ?.map((e) =>
            e == null ? null : PhoneInfo.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$WordInfoToJson(WordInfo instance) => <String, dynamic>{
      'beginTime': instance.beginTime,
      'endTime': instance.endTime,
      'pronAccuracy': instance.pronAccuracy,
      'pronFluency': instance.pronFluency,
      'word': instance.word,
      'matchTag': MatchResultUtil.toInt(instance.matchTag),
      'phoneInfos': instance.phoneInfos,
      'referenceWord': instance.referenceWord,
    };

PhoneInfo _$PhoneInfoFromJson(Map<String, dynamic> json) {
  return PhoneInfo(
    beginTime: json['beginTime'] as int,
    endTime: json['endTime'] as int,
    referenceStress: json['stress'] as bool,
    referencePhone: json['referencePhone'] as String,
    pronAccuracy: (json['pronAccuracy'] as num)?.toDouble(),
    detectedStress: json['detectedStress'] as bool,
    detectedPhone: json['phone'] as String,
  );
}

Map<String, dynamic> _$PhoneInfoToJson(PhoneInfo instance) => <String, dynamic>{
      'beginTime': instance.beginTime,
      'endTime': instance.endTime,
      'pronAccuracy': instance.pronAccuracy,
      'detectedStress': instance.detectedStress,
      'stress': instance.referenceStress,
      'phone': instance.detectedPhone,
      'referencePhone': instance.referencePhone,
    };
