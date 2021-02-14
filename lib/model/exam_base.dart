// 📦 Package imports:
import 'package:flamingo/flamingo.dart';
import 'package:flamingo_annotation/flamingo_annotation.dart';

// 🌎 Project imports:
import 'speech_exam.dart';

part 'exam_base.flamingo.dart';

/// Exam base, extends this class to make different exam
class Exam<T> extends Document<Exam<T>> {
  /// Hold information about exam extends this class, need to be updated by hand
  static final Map<String, Object Function(DocumentSnapshot snapshot)>
      _factories = {'SpeechExam': (snapshot) => SpeechExam(snapshot: snapshot)};

  Exam({
    String id,
    DocumentSnapshot snapshot,
    Map<String, dynamic> values,
  })  : examId = id,
        tags = id == null ? [] : [id.split('-').first],
        _examType = T.toString(), // Assign lectureId to tags
        super(id: id, snapshot: snapshot, values: values);

  /// Create instance of subclass by snapshot
  factory Exam.fromSnapshot(DocumentSnapshot snapshot) {
    if (snapshot.exists) {
      return _factories[snapshot.data()['_examType']](snapshot);
    }
    return null;
  }

  @Field()
  String examId;
  @Field()
  String title;
  @Field()
  String question;
  @Field()
  List<String> tags;
  @Field()
  String _examType;

  String get lectureId => examId.split('-').first;

  @override
  Map<String, dynamic> toData() => _$toData(this);

  @override
  void fromData(Map<String, dynamic> data) => _$fromData(this, data);
}
