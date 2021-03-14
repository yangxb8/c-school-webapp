// 📦 Package imports:
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flamingo/flamingo.dart';
import 'package:flamingo_annotation/flamingo_annotation.dart';

// 🌎 Project imports:
import 'package:cschool_webapp/model/word.dart';

part 'user_word_history.flamingo.dart';

class WordHistory extends Model {
  WordHistory({
    this.wordId,
    WordMemoryStatus? wordMemoryStatus,
    this.timestamp,
    this.isLatest,
    Map<String, dynamic>? values,
  })  : _wordMemoryStatus =
            wordMemoryStatus == null ? null : EnumToString.convertToString(wordMemoryStatus),
        super(values: values);

  @Field()
  String? wordId;
  @Field()
  // ignore: prefer_final_fields
  String? _wordMemoryStatus;
  @Field()
  Timestamp? timestamp;
  @Field()
  bool? isLatest;

  WordMemoryStatus? get wordMemoryStatus => _wordMemoryStatus == null
      ? null
      : EnumToString.fromString(WordMemoryStatus.values, _wordMemoryStatus!);

  String get lectureId => wordId!.split('-').first;

  @override
  Map<String, dynamic> toData() => _$toData(this);

  @override
  void fromData(Map<String, dynamic> data) => _$fromData(this, data);
}
