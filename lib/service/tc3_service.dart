// 🎯 Dart imports:
import 'dart:convert';
import 'dart:typed_data';

// 📦 Package imports:
import 'package:crypto/crypto.dart';
import 'package:cschool_webapp/model/soe_request.dart';
import 'package:cschool_webapp/model/speech_evaluation_result.dart';
import 'package:cschool_webapp/model/tts_request.dart';
import 'package:get/get.dart';

// 🌎 Project imports:
import '../util/utility.dart';

class TcService extends GetConnect{
  static const SECRET_ID = 'AKIDorfD1yrBxYu3w2zWGj0aAXpzqPib3yKP';
  static const SECRET_KEY = 'rSqCKqlO6cz5wRWKGdoNaY6SaR0PhtgF';

  Future<SentenceInfo> sendSoeRequest(SoeRequest request) async{
    const action = 'TransmitOralProcessWithInit';
    const version = '2018-07-24';
    const endpoint = 'soe.tencentcloudapi.com';
    const service = 'soe';
    final now = DateTime.now();
    final timestamp = (now.millisecondsSinceEpoch / 1000).floor().toString();
    final payload = request.toString();
    final sign = _generateAuth(endpoint:endpoint, service: service, payload:payload,now: now);
    final response = await post('https://$endpoint', payload, headers: {
      'Host': endpoint,
      'X-TC-Action': action,
      'X-TC-RequestClient': GetPlatform.isIOS ? 'cschool_ios' : 'cschool_android',
      'X-TC-Timestamp': timestamp,
      'X-TC-Version': version,
      'X-TC-Language': 'zh-CN',
      'Content-Type': 'application/json',
      'Authorization': sign,
    });
    // This is stupid but GetConnect doesn't allow to change default charset [latin1]
    final content = utf8.decode(latin1.encode(response.bodyString!));
    return SentenceInfo.fromJson(jsonDecode(content)['Response']);
  }

  Future<Uint8List> sendTtsRequest(TtsRequest request) async{
    const region = 'ap-shanghai';
    const action = 'TextToVoice';
    const version = '2019-08-23';
    const endpoint = 'tts.tencentcloudapi.com';
    const service = 'tts';
    final now = DateTime.now();
    final timestamp = (now.millisecondsSinceEpoch / 1000).floor().toString();
    final payload = request.toString();
    final sign = _generateAuth(endpoint:endpoint, service:service,payload: payload,now: now);
    final response = await post('https://$endpoint', payload, headers: {
      'Host': endpoint,
      'X-TC-Region': region,
      'X-TC-Action': action,
      'X-TC-RequestClient': GetPlatform.isIOS ? 'cschool_ios' : 'cschool_android',
      'X-TC-Timestamp': timestamp,
      'X-TC-Version': version,
      'X-TC-Language': 'zh-CN',
      'Content-Type': 'application/json',
      'Authorization': sign,
    });
    return base64Decode(response.body['Response']['Audio']);
  }


  String _generateAuth({required String endpoint, required String service, required String payload, required DateTime now}) {
    // 时间处理, 获取世界时间日期
    final utc = now.toUtc();
    final timestamp = (now.millisecondsSinceEpoch / 1000).floor().toString();
    final date = utc.yyyy_MM_dd;
    // ************* 步骤 1：拼接规范请求串 *************
    final signedHeaders = 'content-type;host';

    final hashedRequestPayload = sha256.convert(utf8.encode(payload)).toString();
    final httpRequestMethod = 'POST';
    final canonicalUri = '/';
    final canonicalQueryString = '';
    final canonicalHeaders = 'content-type:application/json\n' 'host:' + endpoint + '\n';

    final canonicalRequest = httpRequestMethod +
        '\n' +
        canonicalUri +
        '\n' +
        canonicalQueryString +
        '\n' +
        canonicalHeaders +
        '\n' +
        signedHeaders +
        '\n' +
        hashedRequestPayload;
    // ************* 步骤 2：拼接待签名字符串 *************
    final algorithm = 'TC3-HMAC-SHA256';
    final hashedCanonicalRequest = sha256.convert(utf8.encode(canonicalRequest)).toString();
    final credentialScope = date + '/' + service + '/' + 'tc3_request';
    final stringToSign =
        algorithm + '\n' + timestamp + '\n' + credentialScope + '\n' + hashedCanonicalRequest;
    // ************* 步骤 3：计算签名 *************
    final kDate = _hmac256(date, 'TC3' + SECRET_KEY).bytes;
    final kService = _hmac256(service, kDate).bytes;
    final kSigning = _hmac256('tc3_request', kService).bytes;
    final signature = _hmac256(stringToSign, kSigning).toString();
    // ************* 步骤 4：拼接 Authorization *************
    final sign = algorithm +
        ' ' +
        'Credential=' +
        SECRET_ID +
        '/' +
        credentialScope +
        ', ' +
        'SignedHeaders=' +
        signedHeaders +
        ', ' +
        'Signature=' +
        signature;
    return sign;
  }

  Digest _hmac256(String message, dynamic secret) {
    final List<int> key = (secret is String) ? utf8.encode(secret) : secret;
    return Hmac(sha256, key).convert(utf8.encode(message));
  }
}
