// 🐦 Flutter imports:

// 📦 Package imports:
import 'package:flamingo/flamingo.dart';
import 'package:flamingo_annotation/flamingo_annotation.dart';

part 'user_memo.flamingo.dart';

class UserMemo extends Model {
  UserMemo({
    this.title,
    this.content,
    this.relatedClassId,
    this.timestamp,
    Map<String, dynamic>? values,
  }) : super(values: values);

  @Field()
  String? title;
  @Field()
  String? content;
  @Field()
  String? relatedClassId;

  @Field()
  Timestamp? timestamp;

  @override
  Map<String, dynamic> toData() => _$toData(this);

  @override
  void fromData(Map<String, dynamic> data) => _$fromData(this, data);
}
