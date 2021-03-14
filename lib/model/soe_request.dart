// 🎯 Dart imports:
import 'dart:convert';

// 📦 Package imports:
import 'package:json_annotation/json_annotation.dart';

part 'soe_request.g.dart';

@JsonSerializable()
class SoeRequest {
  /// 流式数据包的序号，从1开始，当IsEnd字段为1后后续序号无意义，
  /// 当IsLongLifeSession不为1且为非流式模式时无意义。
  final SeqId;

  /// 是否传输完毕标志，若为0表示未完毕，若为1则传输完毕开始评估，非流式模式下无意义。
  final IsEnd;

  /// 语音文件类型 1: raw, 2: wav, 3: mp3, 4: speex
  final VoiceFileType;

  /// 语音编码类型 1:pcm
  final VoiceEncodeType;

  /// 语音输入模式，0：流式分片，1：非流式一次性评估
  final WorkMode;

  /// 音频存储模式，0：不存储，1：存储到公共对象存储
  final StorageMode;

  /// 输出断句中间结果标识，0：不输出，1：输出，通过设置该参数，
  /// 可以在评估过程中的分片传输请求中，返回已经评估断句的中间结果，中间结果可用于客户端 UI 更新
  final SentenceInfoEnabled;

  /// 评估语言，0：英文，1：中文
  final ServerType;

  /// 异步模式标识，0：同步模式，1：异步模式
  final IsAsync;

  /// 编码格式要求为BASE64
  final String UserVoiceData;

  /// 被评估语音对应的文本，句子模式下不超过个 20 单词或者中文文字，段落模式不超过 120 单词或者中文文字
  final String? RefText;

  /// 语音段唯一标识，一个完整语音一个SessionId
  final String SessionId;

  /// 评估模式，0：词模式（中文评测模式下为文字模式），1：句子模式，2：段落模式
  /// 3：自由说模式，当为词模式评估时，能够提供每个音节的评估信息，当为句子模式时，能够提供完整度和流利度信息，
  /// 4：单词纠错模式：能够对单词和句子中的读错读音进行纠正，给出参考正确读音。
  final int EvalMode;

  /// 评价苛刻指数，取值为[1.0 - 4.0]范围内的浮点数，用于平滑不同年龄段的分数，1.0为小年龄段，4.0为最高年龄段
  final double ScoreCoeff;

  SoeRequest(
      {this.SeqId = 1,
      this.IsEnd = 1,
      this.VoiceFileType = 2,
      this.VoiceEncodeType = 1,
      required this.UserVoiceData,
      required this.SessionId,
      required this.RefText,
      this.WorkMode = 1,
      this.EvalMode = 1,
      required this.ScoreCoeff,
      this.StorageMode = 0,
      this.SentenceInfoEnabled = 0,
      this.ServerType = 1,
      this.IsAsync = 0});
  factory SoeRequest.fromJson(Map<String, dynamic> json) => _$SoeRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SoeRequestToJson(this);

  /// String representation of this json object
  @override
  String toString() => jsonEncode(toJson());
}
