// 🎯 Dart imports:
import 'dart:async';
import 'dart:typed_data';

// 📦 Package imports:
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flamingo/flamingo.dart';
// 🐦 Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import './logger_service.dart';
// 🌎 Project imports:
import '../model/exam_base.dart';
import '../model/lecture.dart';
import '../model/speech_exam.dart';
import '../model/user.dart';
import '../model/word.dart';
import '../model/word_meaning.dart';
import '../util/utility.dart';

final logger = LoggerService.logger;

class ApiService extends GetxService {
  static ApiService _instance;
  static bool _isFirebaseInitilized = false;
  static _FirebaseAuthApi _firebaseAuthApi;
  static _FirestoreApi _firestoreApi;

  static Future<ApiService> getInstance() async {
    _instance ??= ApiService();

    if (!_isFirebaseInitilized) {
      await Firebase.initializeApp();
      await Flamingo.initializeApp();
      _firebaseAuthApi = _FirebaseAuthApi.getInstance();
      _firestoreApi = _FirestoreApi.getInstance();
      _isFirebaseInitilized = true;
    }

    return _instance;
  }

  _FirebaseAuthApi get firebaseAuthApi => _firebaseAuthApi;
  _FirestoreApi get firestoreApi => _firestoreApi;
}

class _FirebaseAuthApi {
  static _FirebaseAuthApi _instance;
  static bool _isFirebaseAuthInitilized = false;
  static FirebaseAuth _firebaseAuth;

  static _FirebaseAuthApi getInstance() {
    _instance ??= _FirebaseAuthApi();

    if (!_isFirebaseAuthInitilized) {
      _firebaseAuth = FirebaseAuth.instance;
      _isFirebaseAuthInitilized = true;
    }

    return _instance;
  }

  User get currentUser => _firebaseAuth.currentUser;

  void listenToFirebaseAuth(Function func) {
    _firebaseAuth.authStateChanges().listen((_) async => await func());
  }

  // Already return fromm every conditions
  // ignore: missing_return
  Future<String> loginWithEmail(String email, String password) async {
    try {
      var userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      if (!userCredential.user.emailVerified) {
        return 'Please verify your email.';
      }
      return 'ok';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        return 'Wrong password provided for that user.';
      }
    } catch (e) {
      logger.e(e.toString());
      return 'Unexpected internal error occurs';
    }
  }
}

class _FirestoreApi {
  static const extension_audio = 'mp3';
  static const extension_image = 'jpg';
  static _FirestoreApi _instance;
  static FirebaseFirestore _firestore;
  static DocumentAccessor _documentAccessor;
  static Storage _storage;
  static Batch _batch;
  static User _currentUser;

  static _FirestoreApi getInstance() {
    if (_instance == null) {
      _instance = _FirestoreApi();
      _documentAccessor = DocumentAccessor();
      _firestore = FirebaseFirestore.instance;
      _storage = Storage()..fetch();
      _batch = Batch();
      // _setupEmulator(); //TODO: Uncomment this to use firestore simulator
      _currentUser = _FirebaseAuthApi().currentUser;
    }

    return _instance;
  }

  Future<AppUser> fetchAppUser({User firebaseUser}) async {
    firebaseUser ??= _currentUser;
    if (firebaseUser == null) {
      logger.e('fetchAppUser was called on null firebaseUser');
      return null;
    }
    var user = await _documentAccessor.load<AppUser>(AppUser(id: firebaseUser.uid));
    if (user == null) {
      logger.e('user ${firebaseUser.uid} not found in firestore, return empty user');
      return AppUser();
    } else {
      user.firebaseUser = firebaseUser;
      return user;
    }
  }

  /// Update App User using flamingo, appUserForUpdate should contain
  /// only updated values
  void updateAppUser(AppUser appUserForUpdate, Function refreshAppUser) {
    _documentAccessor.update(appUserForUpdate).then((_) => refreshAppUser());
  }

  /// Upload a single file and return the reference
  Future<StorageFile> uploadFile(
      {@required String path,
      @required Uint8List data,
      @required String filename,
      @required String mimeType,
      @required final Map<String, String> metadata}) async {
    return await _storage.saveFromBytes(path, data,
        filename: filename, mimeType: mimeType, metadata: metadata);
  }

  Future<StorageFile> uploadFileRecord({@required StorageRecord record}) async {
    return await uploadFile(
        path: record.path,
        data: record.data,
        filename: record.filename,
        mimeType: record.mimeType,
        metadata: record.metadata);
  }

  /// Upload words to firestore and cloud storage
  void uploadWordsByCsv() async {
    final COLUMN_WORD_PROCESS_STATUS = 0;
    final COLUMN_WORD_ID = 1;
    final COLUMN_WORD = COLUMN_WORD_ID + 1;
    final COLUMN_PART_OF_SENTENCE = COLUMN_WORD_ID + 2;
    final COLUMN_MEANING = COLUMN_WORD_ID + 3;
    final COLUMN_PINYIN = COLUMN_WORD_ID + 5;
    final COLUMN_OTHER_MEANING_ID = COLUMN_WORD_ID + 6;
    final COLUMN_DETAIL = COLUMN_WORD_ID + 7;
    final COLUMN_EXAMPLE = COLUMN_WORD_ID + 8;
    final COLUMN_EXAMPLE_MEANING = COLUMN_WORD_ID + 9;
    final COLUMN_EXAMPLE_PINYIN = COLUMN_WORD_ID + 10;
    final COLUMN_RELATED_WORD_ID = COLUMN_WORD_ID + 13;
    final COLUMN_PIC_HASH = COLUMN_WORD_ID + 17;
    final WORD_PROCESS_STATUS_UPLOAD = 2;
    final SEPARATOR = '/';
    final PINYIN_SEPARATOR = '-';

    // Build Word from csv
    var csv;
    try {
      csv = CsvToListConverter().convert(await rootBundle.loadString('assets/upload/words.csv'))
        ..removeWhere((w) =>
            WORD_PROCESS_STATUS_UPLOAD != w[COLUMN_WORD_PROCESS_STATUS] || w[COLUMN_WORD] == null);
    } catch (_) {
      print('No words.csv found, will skip!');
      return;
    }

    var words = csv
        .map((row) => Word(id: row[COLUMN_WORD_ID])
          ..word = row[COLUMN_WORD].trim().split('')
          ..pinyin = row[COLUMN_PINYIN].trim().split(PINYIN_SEPARATOR)
          ..partOfSentence = row[COLUMN_PART_OF_SENTENCE].trim()
          ..explanation = row[COLUMN_DETAIL].trim()
          ..picHash = row[COLUMN_PIC_HASH].trim()
          ..wordMeanings = [
            WordMeaning(
                meaning: row[COLUMN_MEANING].toString().trim().replaceAll(SEPARATOR, ','),
                examples: row[COLUMN_EXAMPLE].toString().trim() == ''
                    ? []
                    : row[COLUMN_EXAMPLE].toString().trim().split(SEPARATOR),
                exampleMeanings: row[COLUMN_EXAMPLE_MEANING].toString().trim() == ''
                    ? []
                    : row[COLUMN_EXAMPLE_MEANING].toString().trim().split(SEPARATOR),
                examplePinyins: row[COLUMN_EXAMPLE_PINYIN].trim() == ''
                    ? []
                    : row[COLUMN_EXAMPLE_PINYIN].trim().split(SEPARATOR).toList())
          ]
          ..relatedWordIDs = row[COLUMN_RELATED_WORD_ID].trim().split(SEPARATOR)
          ..otherMeaningIds = row[COLUMN_OTHER_MEANING_ID].trim().split(SEPARATOR))
        .toList();

    // Checking status
    _storage.uploader.listen((data) {
      print('total: ${data.totalBytes} transferred: ${data.bytesTransferred}');
    });
    // Upload file to cloud storage and save reference
    await words.forEach((word) async {
      // Word image
      final pathWordPic = '${word.documentPath}/${EnumToString.convertToString(WordKey.pic)}';
      try {
        final wordPic = await createFileFromAssets('upload/${word.wordId}.${extension_image}');
        word.pic = await _storage.save(pathWordPic, wordPic,
            filename: '${word.wordId}.${extension_image}',
            mimeType: mimeTypeJpeg,
            metadata: {'newPost': 'true'});
      } catch (e, _) {
        logger.i('Not image found for ${word.wordAsString}, will skip');
      }

      // Word Audio
      final pathWordAudioMale =
          '${word.documentPath}/${EnumToString.convertToString(WordKey.wordAudioMale)}';
      final pathWordAudioFemale =
          '${word.documentPath}/${EnumToString.convertToString(WordKey.wordAudioFemale)}';
      final wordAudioFileMale =
          await createFileFromAssets('upload/${word.wordId}-W-M.${extension_audio}');
      final wordAudioFileFemale =
          await createFileFromAssets('upload/${word.wordId}-W-F.${extension_audio}');
      word.wordAudioMale = await _storage.save(pathWordAudioMale, wordAudioFileMale,
          filename: '${word.wordId}-W-M.${extension_audio}',
          mimeType: mimeTypeMpeg,
          metadata: {'newPost': 'true'});
      word.wordAudioFemale = await _storage.save(pathWordAudioFemale, wordAudioFileFemale,
          filename: '${word.wordId}-W-F.${extension_audio}',
          mimeType: mimeTypeMpeg,
          metadata: {'newPost': 'true'});

      // Examples Audio
      // Each meaning
      await Future.forEach(word.wordMeanings, (meaning) async {
        var maleAudios = <StorageFile>[];
        var femaleAudios = <StorageFile>[];
        // Each example
        await Future.forEach(List.generate(meaning.exampleCount, (i) => i), (index) async {
          final pathExampleMaleAudio =
              '${word.documentPath}/${EnumToString.convertToString(WordMeaningKey.exampleMaleAudios)}';
          final pathExampleFemaleAudio =
              '${word.documentPath}/${EnumToString.convertToString(WordMeaningKey.exampleFemaleAudios)}';
          final exampleAudioFileMale =
              await createFileFromAssets('upload/${word.wordId}-E${index}-M.${extension_audio}');
          final exampleAudioFileFemale =
              await createFileFromAssets('upload/${word.wordId}-E${index}-F.${extension_audio}');
          final maleAudio = await _storage.save(pathExampleMaleAudio, exampleAudioFileMale,
              filename: '${word.wordId}-E${index}-M.${extension_audio}',
              mimeType: mimeTypeMpeg,
              metadata: {'newPost': 'true'});
          maleAudios.add(maleAudio);
          final femaleAudio = await _storage.save(pathExampleFemaleAudio, exampleAudioFileFemale,
              filename: '${word.wordId}-E${index}-F.${extension_audio}',
              mimeType: mimeTypeMpeg,
              metadata: {'newPost': 'true'});
          femaleAudios.add(femaleAudio);
        });
        meaning.exampleMaleAudios = maleAudios;
        meaning.exampleFemaleAudios = femaleAudios;
      });

      // Finally, save the word
      _batch.save(word);
    });
    await _batch.commit();

// Checking status
    _storage.uploader.listen((data) {
      print('total: ${data.totalBytes} transferred: ${data.bytesTransferred}');
    });

// Dispose uploader stream
    _storage.dispose();
  }

  Future<void> uploadLecturesByCsv(
      {@required String csv, @required Map<String, Uint8List> assets}) async {
    final columnId = 0;
    final columnLevel = 1;
    final columnTitle = 2;
    final columnDescription = 3;
    final columnProcessStatus = 5;
    final columnPicHash = 6;
    final processStatusNew = 0;
    final processStatusModified = 1;

    // Build Word from csv
    var csv;
    try {
      csv = CsvToListConverter().convert(csv)
        ..removeWhere((w) =>
            ![processStatusNew, processStatusModified].contains(w[columnProcessStatus]) ||
            w[columnTitle] == null);
    } catch (_) {
      print('No lectures.csv found, will skip!');
      return;
    }

    var lectures = csv.map((row) => Lecture(id: row[columnId], level: row[columnLevel])
      ..title = row[columnTitle].trim() // Title should not be null
      ..description = row[columnDescription]?.trim()
      ..picHash = row[columnPicHash]?.trim());

    // Upload file to cloud storage and save reference
    await lectures.forEach((lecture) async {
      // Word image
      final pathClassPic =
          '${lecture.documentPath}/${EnumToString.convertToString(LectureKey.pic)}';
      try {
        final lecturePic = assets['${lecture.lectureId}.$extension_image'];
        lecture.pic = await _storage.saveFromBytes(pathClassPic, lecturePic,
            filename: '${lecture.lectureId}.$extension_image',
            mimeType: mimeTypeJpeg,
            metadata: {'newPost': 'true'});
      } catch (e, _) {
        logger.i('Not image found for ${lecture.title}, will skip');
      }

      // Finally, save the word
      _batch.save(lecture);
    });
    await _batch.commit();

    // Dispose uploader stream
    _storage.dispose();
  }

  void uploadSpeechExamsByCsv() async {
    final column_id = 0;
    final column_title = 2;
    final column_question = 3;
    final column_ref_text = 4;
    final column_process_statue = 5;
    final process_status_new = 0;

    // Build Word from csv
    var csv;
    try {
      csv = CsvToListConverter()
          .convert(await rootBundle.loadString('assets/upload/speechExams.csv'))
            ..removeWhere(
                (w) => process_status_new != w[column_process_statue] || w[column_title] == null);
    } catch (_) {
      print('No speechExams.csv found, will skip!');
      return;
    }

    var exams = csv.map((row) => SpeechExam(id: row[column_id])
      ..title = row[column_title].trim() // Title should not be null
      ..question = row[column_question]?.trim()
      ..refText = row[column_ref_text]?.trim());

    // Checking status
    _storage.uploader.listen((data) {
      print('total: ${data.totalBytes} transferred: ${data.bytesTransferred}');
    });
    // Upload file to cloud storage and save reference
    await exams.forEach((exam) async {
      // Word image
      final pathRefAudio =
          '${exam.documentPath}/${EnumToString.convertToString(SpeechExamKey.refAudio)}';
      try {
        final refAudio = await createFileFromAssets('upload/${exam.id}.${extension_audio}');
        exam.pic = await _storage.save(pathRefAudio, refAudio,
            filename: '${exam.id}.${extension_audio}',
            mimeType: mimeTypeMpeg,
            metadata: {'newPost': 'true'});
      } catch (e, _) {
        logger.i('Not image found for ${exam.title}, will skip');
      }

      // Finally, save the word
      _batch.save(exam);
    });
    await _batch.commit();

// Dispose uploader stream
    _storage.dispose();
  }

  Future<List<Word>> fetchWords({List<String> tags}) async {
    final collectionPaging = CollectionPaging<Word>(
      query: Word().collectionRef.orderBy('wordId'),
      limit: 10000,
      decode: (snap) => Word(snapshot: snap),
    );
    return await collectionPaging.load();
  }

  /// Fetch all entities extends exam
  Future<List<Exam>> fetchExams({List<String> tags}) async {
    final collectionPaging = CollectionPaging<Exam>(
      query: Exam().collectionRef.orderBy('examId'),
      limit: 10000,
      decode: (snap) => Exam.fromSnapshot(snap), // don't use Exam()
    );
    return await collectionPaging.load();
  }

  Future<List<Lecture>> fetchLectures({List<String> tags}) async {
    final collectionPaging = CollectionPaging<Lecture>(
      query: Lecture().collectionRef.orderBy('lectureId'),
      limit: 10000,
      decode: (snap) => Lecture(snapshot: snap),
    );
    return await collectionPaging.load();
  }

  Future<void> commitBatch(Set<Map<String, Rx<Lecture>>> batchSet) async {
    batchSet.forEach((element) {
      final action = element.keys.single;
      final lecture = element.values.single.value;
      _batch.actions[action](lecture);
    });
    await _batch.commit();
  }
}
