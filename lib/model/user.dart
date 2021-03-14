// 📦 Package imports:
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flamingo/flamingo.dart';
import 'package:flamingo_annotation/flamingo_annotation.dart';

// 🌎 Project imports:
import 'package:cschool_webapp/model/user_lecture_history.dart';
import 'package:cschool_webapp/model/user_memo.dart';
import 'package:cschool_webapp/model/user_rank.dart';
import 'package:cschool_webapp/model/user_word_history.dart';

part 'user.flamingo.dart';

/*
* User info
 */
class AppUser extends Document<AppUser> {
  AppUser({
    String? id,
    DocumentSnapshot? snapshot,
    Map<String, dynamic>? values,
  }) : super(id: id, snapshot: snapshot, values: values);

  @Field()
  String nickName = '';
  @Field()
  List<String>? _membershipTypes = [];
  @Field()
  Timestamp? membershipEndAt = Timestamp.fromDate(DateTime.now());
  @ModelField()
  List<UserRank>? rankHistory = [];
  @ModelField()
  List<LectureHistory>? reviewedClassHistory = [];
  @ModelField()
  List<WordHistory>? reviewedWordHistory = [];
  @Field()
  List<String>? likedLectures = [];
  @Field()
  List<String>? likedWords = [];
  @ModelField()
  List<UserMemo>? userMemos = [];

  User? firebaseUser;

  set membershipTypes(List<MembershipType> types) =>
      _membershipTypes = EnumToString.toList(types);

  List<MembershipType> get membershipTypes =>
      EnumToString.fromList(MembershipType.values, _membershipTypes!) as List<MembershipType>;

  bool isLogin() {
    return firebaseUser != null;
  }

  String get userId => firebaseUser?.uid ?? 'NO_FIREBASE_USER';
  int get userRankNow {
    if(rankHistory!.isEmpty){
      return 1;
    }
    return rankHistory!.last.rank!;
  }
  //TODO: get userScoreCoeff(For speech evaluation) properly
  double get userScoreCoeff => userRankNow.toDouble();

  @override
  Map<String, dynamic> toData() => _$toData(this);

  @override
  void fromData(Map<String, dynamic> data) => _$fromData(this, data);
}

enum MembershipType {
  FREE,
  TRIAL,
  SUBSCRIBE, // monthly, yearly etc.
  PACKAGE_BEGINNER // paid for beginner particular package
}
