// Package imports:
import 'package:get/get.dart';
import 'package:supercharged/supercharged.dart';

// Project imports:
import '../model/exam_base.dart';
import '../model/lecture.dart';
import '../model/word.dart';
import 'api_service.dart';

/*
* This class provide service related to Class, like fetching class,
* words, etc.
*/
class LectureService extends GetxService {
  static LectureService? _instance;
  static final ApiService _apiService = Get.find();

  /// All classes available
  static final allLecturesObx = <Rx<Lecture>>[].obs;

  /// All words available
  static final allWordsObx = <Rx<Word>>[].obs;

  /// All exams available
  static final allExamsObx = <Rx<Exam>>[].obs;

  static Future<LectureService?> getInstance() async {
    if (_instance == null) {
      _instance = LectureService();
      await refresh();
    }
    return _instance;
  }

  static Future<void> refresh() async {
    /// All available Lectures
    allLecturesObx.assignAll((await _apiService.firestoreApi.fetchLectures())
        .map((e) => e.obs)
        .toList()
        .obs);

    /// All available words
    allWordsObx.assignAll((await _apiService.firestoreApi.fetchWords())
        .map((e) => e.obs)
        .toList()
        .obs);

    /// All available exams
    allExamsObx.assignAll((await _apiService.firestoreApi.fetchExams())
        .map((e) => e.obs)
        .toList()
        .obs);
  }

  List<Word> findWordsByIds(List<String> ids) {
    if (ids.isBlank!) {
      return [];
    } else {
      return allWordsObx
          .filter((word) => ids.contains(word.value!.wordId))
          .map((e) => e.value)
          .toList() as List<Word>;
    }
  }

  List<Word> findWordsByTags(List<String?> tags) {
    if (tags.isBlank!) {
      return [];
    } else {
      return allWordsObx
          .filter((word) => tags.every((tag) => word.value!.tags!.contains(tag)))
          .map((e) => e.value)
          .toList() as List<Word>;
    }
  }

  List<Exam> findExamsByTags(List<String?> tags) {
    if (tags.isBlank!) {
      return [];
    } else {
      return allExamsObx
          .filter((exam) => tags.every((tag) => exam.value!.tags!.contains(tag)))
          .map((e) => e.value)
          .toList() as List<Exam<dynamic>>;
    }
  }

  Exam? findExamById(String id) {
    if (id.isBlank!) {
      return null;
    } else {
      return allExamsObx
          .filter((exam) => id == exam.value!.examId)
          .map((e) => e.value)
          .single;
    }
  }

  Lecture? findLectureById(String id) {
    if (id.isBlank!) {
      return null;
    } else {
      return allLecturesObx
          .filter((lecture) => id == lecture.value!.lectureId)
          .map((e) => e.value)
          .single;
    }
  }

  List<Lecture> findLecturesByTags(List<String> tags) {
    if (tags.isBlank!) {
      return [];
    } else {
      return allLecturesObx
          .filter((lecture) =>
              tags.every((tag) => lecture.value!.tags!.contains(tag)))
          .map((e) => e.value)
          .toList() as List<Lecture>;
    }
  }
}
