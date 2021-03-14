// 🐦 Flutter imports:

// 📦 Package imports:
import 'package:flamingo/flamingo.dart';
import 'package:flamingo_annotation/flamingo_annotation.dart';

part 'user_lecture_history.flamingo.dart';

class LectureHistory extends Model {
  LectureHistory({
    this.lectureId,
    this.timestamp,
    this.isLatest,
    Map<String, dynamic>? values,
  }) : super(values: values);

  @Field()
  String? lectureId;
  @Field()
  Timestamp? timestamp;
  @Field()
  bool? isLatest;

  @override
  Map<String, dynamic> toData() => _$toData(this);

  @override
  void fromData(Map<String, dynamic> data) => _$fromData(this, data);
}
