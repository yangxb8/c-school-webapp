// 📦 Package imports:
import 'package:enum_to_string/enum_to_string.dart';
import 'package:json_annotation/json_annotation.dart';

part 'speech_evaluation_result.g.dart';

/// This class will be persisted into cloud storage once created. It's NOT
/// be intended to retrieved from cloud storage in App. Instead, the data
/// might be directly extracted from cloud storage for analysis in the future.
@JsonSerializable()
class SpeechEvaluationResult {
  final String? userId;
  final String? examId;
  final String? speechDataPath;
  final SentenceInfo? sentenceInfo;

  SpeechEvaluationResult({this.userId, this.examId, this.speechDataPath, this.sentenceInfo});
  factory SpeechEvaluationResult.fromJson(Map<String, dynamic> json) =>
      _$SpeechEvaluationResultFromJson(json);
  Map<String, dynamic> toJson() => _$SpeechEvaluationResultToJson(this);
}

@JsonSerializable()
class SentenceInfo {
  @JsonKey(name: 'SuggestedScore')
  final double? suggestedScore;
  @JsonKey(name: 'PronAccuracy')
  final double? pronAccuracy;
  @JsonKey(name: 'PronFluency')
  final double? pronFluency;
  @JsonKey(name: 'PronCompletion')
  final double? pronCompletion;
  @JsonKey(name: 'Words')
  final List<WordInfo>? words;

  SentenceInfo(
      {this.suggestedScore, this.pronAccuracy, this.pronFluency, this.pronCompletion, this.words});

  double get displaySuggestedScore => suggestedScore ?? -1.0;
  double get displayPronAccuracy => pronAccuracy ?? -1.0;
  double get displayPronFluency => pronFluency == null ? -1.0 : pronFluency! * 100;
  double get displayPronCompletion => pronCompletion == null ? -1.0 : pronCompletion! * 100;

  factory SentenceInfo.fromJson(Map<String, dynamic> json) => _$SentenceInfoFromJson(json);
  Map<String, dynamic> toJson() => _$SentenceInfoToJson(this);
}

@JsonSerializable()
class WordInfo {
  @JsonKey(name: 'MemBeginTime')
  final int? beginTime;
  @JsonKey(name: 'MemEndTime')
  final int? endTime;
  @JsonKey(name: 'PronAccuracy')
  final double? pronAccuracy;
  @JsonKey(name: 'PronFluency')
  final double? pronFluency;
  @JsonKey(name: 'Word')
  final String? word;
  @JsonKey(
      name: 'MatchTag', fromJson: MatchResultUtil.fromInt, toJson: EnumToString.convertToString)
  final MatchResult? matchTag;
  @JsonKey(name: 'PhoneInfos')
  final List<PhoneInfo>? phoneInfos;
  @JsonKey(name: 'ReferenceWord')
  final String? referenceWord;

  WordInfo(
      {this.beginTime,
      this.endTime,
      this.referenceWord,
      this.pronAccuracy,
      this.pronFluency,
      this.word,
      this.matchTag,
      this.phoneInfos});

  double get displayPronAccuracy => pronAccuracy ?? -1.0;
  double get displayPronFluency => pronFluency == null ? -1.0 : pronFluency! * 100;

  factory WordInfo.fromJson(Map<String, dynamic> json) => _$WordInfoFromJson(json);
  Map<String, dynamic> toJson() => _$WordInfoToJson(this);
}

@JsonSerializable()
class PhoneInfo {
  @JsonKey(name: 'MemBeginTime')
  final int? beginTime;
  @JsonKey(name: 'MemEndTime')
  final int? endTime;
  @JsonKey(name: 'PronAccuracy')
  final double? pronAccuracy;
  @JsonKey(name: 'DetectedStress')
  final bool? detectedStress;
  @JsonKey(name: 'Stress')
  final bool? referenceStress;
  @JsonKey(name: 'Phone')
  final String? detectedPhone;
  @JsonKey(name: 'ReferencePhone')
  final String? referencePhone;
  @JsonKey(
      name: 'MatchTag', fromJson: MatchResultUtil.fromInt, toJson: EnumToString.convertToString)
  final MatchResult? matchTag;

  PhoneInfo(
      {this.beginTime,
      this.endTime,
      this.referenceStress,
      this.referencePhone,
      this.pronAccuracy,
      this.detectedStress,
      this.detectedPhone,
      this.matchTag});

  double get displayPronAccuracy => pronAccuracy ?? -1.0;

  factory PhoneInfo.fromJson(Map<String, dynamic> json) => _$PhoneInfoFromJson(json);
  Map<String, dynamic> toJson() => _$PhoneInfoToJson(this);
}

enum MatchResult { match, added, lacked, wrong, undetected }

extension MatchResultUtil on MatchResult {
  static MatchResult? fromInt(int? matchResultInt) {
    return matchResultInt == null ? null : MatchResult.values[matchResultInt];
  }
}
