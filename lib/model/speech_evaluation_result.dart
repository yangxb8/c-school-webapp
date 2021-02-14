// 📦 Package imports:
import 'package:json_annotation/json_annotation.dart';

part 'speech_evaluation_result.g.dart';

/// This class will be persisted into cloud storage once created. It's NOT
/// be intended to retrieved from cloud storage in App. Instead, the data
/// might be directly extracted from cloud storage for analysis in the future.
@JsonSerializable()
class SpeechEvaluationResult {
  final String userId;
  final String examId;
  final String speechDataPath;
  final SentenceInfo sentenceInfo;

  SpeechEvaluationResult(
      {this.userId, this.examId, this.speechDataPath, this.sentenceInfo});
  factory SpeechEvaluationResult.fromJson(Map<String, dynamic> json) =>
      _$SpeechEvaluationResultFromJson(json);
  Map<String, dynamic> toJson() => _$SpeechEvaluationResultToJson(this);
}

@JsonSerializable()
class SentenceInfo {
  final double suggestedScore;
  final double pronAccuracy;
  final double pronFluency;
  final double pronCompletion;
  final List<WordInfo> words;

  SentenceInfo(
      {this.suggestedScore,
      this.pronAccuracy,
      this.pronFluency,
      this.pronCompletion,
      this.words});
  factory SentenceInfo.fromJson(Map<String, dynamic> json) =>
      _$SentenceInfoFromJson(json);
  Map<String, dynamic> toJson() => _$SentenceInfoToJson(this);
}

@JsonSerializable()
class WordInfo {
  final int beginTime;
  final int endTime;
  final double pronAccuracy;
  final double pronFluency;
  final String word;
  @JsonKey(fromJson: MatchResultUtil.fromInt, toJson: MatchResultUtil.toInt)
  final MatchResult matchTag;
  final List<PhoneInfo> phoneInfos;
  final String referenceWord;

  WordInfo(
      {this.beginTime,
      this.endTime,
      this.referenceWord,
      this.pronAccuracy,
      this.pronFluency,
      this.word,
      this.matchTag,
      this.phoneInfos});
  factory WordInfo.fromJson(Map<String, dynamic> json) =>
      _$WordInfoFromJson(json);
  Map<String, dynamic> toJson() => _$WordInfoToJson(this);
}

@JsonSerializable()
class PhoneInfo {
  final int beginTime;
  final int endTime;
  final double pronAccuracy;
  final bool detectedStress;
  @JsonKey(name: 'stress')
  final bool referenceStress;
  @JsonKey(name: 'phone')
  final String detectedPhone;
  final String referencePhone;

  PhoneInfo(
      {this.beginTime,
      this.endTime,
      this.referenceStress,
      this.referencePhone,
      this.pronAccuracy,
      this.detectedStress,
      this.detectedPhone});
  factory PhoneInfo.fromJson(Map<String, dynamic> json) =>
      _$PhoneInfoFromJson(json);
  Map<String, dynamic> toJson() => _$PhoneInfoToJson(this);
}

enum MatchResult { MATCH, ADDED, LACKED, WRONG, UNDETECTED }

extension MatchResultUtil on MatchResult {
  static MatchResult fromInt(int matchResultInt) {
    return matchResultInt == null ? null : MatchResult.values[matchResultInt];
  }

  static int toInt(MatchResult matchResult) {
    if (matchResult == null) return null;
    for (var i = 0; i < MatchResult.values.length; i++) {
      if (MatchResult.values[i] == matchResult) {
        return i;
      }
    }
    // impossible
    return 0;
  }
}
