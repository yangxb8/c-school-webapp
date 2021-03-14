// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'soe_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SoeRequest _$SoeRequestFromJson(Map<String, dynamic> json) {
  return SoeRequest(
    SeqId: json['SeqId'],
    IsEnd: json['IsEnd'],
    VoiceFileType: json['VoiceFileType'],
    VoiceEncodeType: json['VoiceEncodeType'],
    UserVoiceData: json['UserVoiceData'] as String,
    SessionId: json['SessionId'] as String,
    RefText: json['RefText'] as String?,
    WorkMode: json['WorkMode'],
    EvalMode: json['EvalMode'] as int,
    ScoreCoeff: (json['ScoreCoeff'] as num).toDouble(),
    StorageMode: json['StorageMode'],
    SentenceInfoEnabled: json['SentenceInfoEnabled'],
    ServerType: json['ServerType'],
    IsAsync: json['IsAsync'],
  );
}

Map<String, dynamic> _$SoeRequestToJson(SoeRequest instance) =>
    <String, dynamic>{
      'SeqId': instance.SeqId,
      'IsEnd': instance.IsEnd,
      'VoiceFileType': instance.VoiceFileType,
      'VoiceEncodeType': instance.VoiceEncodeType,
      'WorkMode': instance.WorkMode,
      'StorageMode': instance.StorageMode,
      'SentenceInfoEnabled': instance.SentenceInfoEnabled,
      'ServerType': instance.ServerType,
      'IsAsync': instance.IsAsync,
      'UserVoiceData': instance.UserVoiceData,
      'RefText': instance.RefText,
      'SessionId': instance.SessionId,
      'EvalMode': instance.EvalMode,
      'ScoreCoeff': instance.ScoreCoeff,
    };
