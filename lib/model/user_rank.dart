// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:flamingo/flamingo.dart';
import 'package:flamingo_annotation/flamingo_annotation.dart';

part 'user_rank.flamingo.dart';

class UserRank extends Model {
  UserRank({
    @required this.rank,
    @required this.timestamp,
    Map<String, dynamic> values,
  }) : super(values: values);

  @Field()
  int rank;
  @Field()
  Timestamp timestamp;

  @override
  Map<String, dynamic> toData() => _$toData(this);

  @override
  void fromData(Map<String, dynamic> data) => _$fromData(this, data);
}
