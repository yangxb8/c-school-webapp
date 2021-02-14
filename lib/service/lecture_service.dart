// 🐦 Flutter imports:
import 'package:get/get.dart';
import 'package:supercharged/supercharged.dart';

// 🌎 Project imports:
import '../model/exam_base.dart';
import '../model/lecture.dart';
import '../model/word.dart';
import 'api_service.dart';
import 'user_service.dart';

/*
* This class provide service related to Class, like fetching class,
* words, etc.
*/
class LectureService extends GetxService {
  static LectureService _instance;
  static final ApiService _apiService = Get.find();

  /// All classes available
  static RxList<Rx<Lecture>> allLecturesObx;

  /// All words available
  static RxList<Rx<Word>> allWordsObx;

  /// All exams available
  static RxList<Rx<Exam>> allExamsObx;

  static Future<LectureService> getInstance() async {
    if (_instance == null) {
      _instance = LectureService();

      /// All available Lectures
      allLecturesObx =
          (await _apiService.firestoreApi.fetchLectures()).map((e) => e.obs).toList().obs;

      /// All available words
      allWordsObx = (await _apiService.firestoreApi.fetchWords()).map((e) => e.obs).toList().obs;

      /// All available exams
      allExamsObx = (await _apiService.firestoreApi.fetchExams()).map((e) => e.obs).toList().obs;
    }

    return _instance;
  }

  List<Word> findWordsByConditions({WordMemoryStatus wordMemoryStatus, String lectureId}) {
    if (wordMemoryStatus == null && lectureId == null) {
      return [];
    }
    var latestReviewHistory =
        UserService.user.reviewedWordHistory.filter((record) => record.isLatest);
    var filteredHistory = latestReviewHistory.filter((record) {
      if (wordMemoryStatus != null && wordMemoryStatus != record.wordMemoryStatus) {
        return false;
      }
      if (lectureId != null && lectureId != record.lectureId) {
        return false;
      }
      return true;
    });
    var wordIdsOfMemoryStatus = filteredHistory.map((e) => e.wordId);
    return findWordsByIds(wordIdsOfMemoryStatus.toList());
  }

  List<Word> findWordsByIds(List<String> ids) {
    if (ids.isBlank) {
      return [];
    } else {
      return allWordsObx
          .filter((word) => ids.contains(word.value.wordId))
          .map((e) => e.value)
          .toList();
    }
  }

  List<Word> findWordsByTags(List<String> tags) {
    if (tags.isBlank) {
      return [];
    } else {
      return allWordsObx
          .filter((word) => tags.every((tag) => word.value.tags.contains(tag)))
          .map((e) => e.value)
          .toList();
    }
  }

  List<Exam> findExamsByTags(List<String> tags) {
    if (tags.isBlank) {
      return [];
    } else {
      return allExamsObx
          .filter((exam) => tags.every((tag) => exam.value.tags.contains(tag)))
          .map((e) => e.value)
          .toList();
    }
  }

  Exam findExamById(String id) {
    if (id.isBlank) {
      return null;
    } else {
      return allExamsObx.filter((exam) => id == exam.value.examId).map((e) => e.value).single;
    }
  }

  Lecture findLectureById(String id) {
    if (id.isBlank) {
      return null;
    } else {
      return allLecturesObx
          .filter((lecture) => id == lecture.value.lectureId)
          .map((e) => e.value)
          .single;
    }
  }

  List<Lecture> findLecturesByTags(List<String> tags) {
    if (tags.isBlank) {
      return [];
    } else {
      return allLecturesObx
          .filter((lecture) => tags.every((tag) => lecture.value.tags.contains(tag)))
          .map((e) => e.value)
          .toList();
    }
  }
}
