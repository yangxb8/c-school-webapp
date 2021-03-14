// Dart imports:
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

// Flutter imports:
import 'package:cschool_webapp/model/soe_request.dart';
import 'package:cschool_webapp/model/tts_request.dart';
import 'package:cschool_webapp/service/tc3_service.dart';
import 'package:collection/collection.dart';

// Package imports:
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flamingo/flamingo.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

// Project imports:
import '../model/exam_base.dart';
import '../model/lecture.dart';
import '../model/speech_exam.dart';
import '../model/updatable.dart';
import '../model/user.dart';
import '../model/word.dart';
import '../model/word_meaning.dart';
import '../util/utility.dart';
import './logger_service.dart';

final logger = LoggerService.logger;

class ApiService extends GetxService {
  static ApiService? _instance;
  static bool _isFirebaseInitialized = false;
  static late final _FirebaseAuthApi _firebaseAuthApi;
  static late final _FirestoreApi _firestoreApi;

  static Future<ApiService> getInstance() async {
    _instance ??= ApiService();

    if (!_isFirebaseInitialized) {
      await Firebase.initializeApp();
      await Flamingo.initializeApp();
      _firebaseAuthApi = await _FirebaseAuthApi.getInstance();
      _firestoreApi = await _FirestoreApi.getInstance();
      _isFirebaseInitialized = true;
    }

    return _instance!;
  }

  _FirebaseAuthApi get firebaseAuthApi => _firebaseAuthApi;
  _FirestoreApi get firestoreApi => _firestoreApi;
}

class _FirebaseAuthApi {
  static _FirebaseAuthApi? _instance;
  static bool _isFirebaseAuthInitialized = false;
  static late final FirebaseAuth _firebaseAuth;

  static Future<_FirebaseAuthApi> getInstance() async {
    _instance ??= _FirebaseAuthApi();

    if (!_isFirebaseAuthInitialized) {
      _firebaseAuth = FirebaseAuth.instance;
      _isFirebaseAuthInitialized = true;
    }

    return _instance!;
  }

  Future<User?> getCurrentUser() async => await _firebaseAuth.authStateChanges().first;

  void listenToFirebaseAuth(Function func) {
    _firebaseAuth.authStateChanges().listen((_) async => await func());
  }

  // Already return fromm every conditions
  // ignore: missing_return
  Future<String> signUpWithEmail(String email, String password, String nickname) async {
    try {
      var userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      // Email verify by showing popup on provided context
      Get.find<ApiService>()
          .firestoreApi
          ._registerAppUser(firebaseUser: userCredential.user!, nickname: nickname);
      if (!userCredential.user!.emailVerified) {
        await sendVerifyEmail();
        return 'need email verify';
      }
      logger.d(email, 'User registered:');
      return 'ok';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'login.register.error.registeredEmail'.tr;
      }
    } catch (e) {
      logger.e(e);
      return 'error.unknown.content'.tr;
    } finally {
      return 'error.unknown.content'.tr;
    }
  }

  Future<void> sendVerifyEmail() async {
    await (await getCurrentUser())!.reload();
    await (await getCurrentUser())!.sendEmailVerification();
  }

  // Already return fromm every conditions
  // ignore: missing_return
  Future<String> loginWithEmail(String email, String password) async {
    try {
      var userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      if (!userCredential.user!.emailVerified) {
        return 'login.login.error.unverifiedEmail'.tr;
      }
      return 'ok';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'login.login.error.unregisteredEmail'.tr;
      } else if (e.code == 'wrong-password') {
        return 'login.login.error.wrongPassword'.tr;
      } else {
        return 'error.unknown.content'.tr;
      }
    } catch (e) {
      logger.e(e.toString());
      return 'error.unknown.content'.tr;
    }
  }

  Future<String> logout() async {
    await FirebaseAuth.instance.signOut();
    //TODO: Login out from 3rd party OAuth
    return 'ok';
  }
}

class _FirestoreApi {
  static const extension_audio = 'mp3';
  static const extension_image = ['jpg', 'jpeg', 'png'];
  static _FirestoreApi? _instance;
  static late final FirebaseFirestore _firestore;
  static late final DocumentAccessor _documentAccessor;
  static User? _currentUser;

  static Future<_FirestoreApi> getInstance() async {
    if (_instance == null) {
      _instance = _FirestoreApi();
      _firestore = FirebaseFirestore.instance;
      _documentAccessor = DocumentAccessor();
      // _setupEmulator(); //TODO: Uncomment this to use firestore simulator
      _currentUser = await _FirebaseAuthApi().getCurrentUser();
    }

    return _instance!;
  }

  void _registerAppUser({required User firebaseUser, required String nickname}) {
    if (firebaseUser.isAnonymous) return;
    var appUser = AppUser(id: firebaseUser.uid);
    appUser.nickName = nickname;
    _documentAccessor.save(appUser).catchError((e) => logger.e(e.printError()));
  }

  Future<AppUser?> fetchAppUser({User? firebaseUser}) async {
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

  /// Check if document is in firestore
  Future<bool> containsDoc(Document doc) async =>
      (await _firestore.doc(doc.documentPath).get()).exists;

  /// Upload a single file and return the reference
  Future<StorageFile> uploadFile(
      {required String path,
      required Uint8List data,
      required String filename,
      required String mimeType,
      required final Map<String, String> metadata}) async {
    final _storage = Storage()..fetch();
    final storageFile = await _storage.saveFromBytes(path, data,
        filename: filename, mimeType: mimeType, metadata: metadata);
    _storage.dispose();
    return storageFile;
  }

  Future<StorageFile> uploadFileRecord({required StorageRecord record}) async {
    return await uploadFile(
        path: record.path,
        data: record.data!,
        filename: record.filename,
        mimeType: record.mimeType!,
        metadata: record.metadata);
  }

  /// Upload words to firestore and cloud storage
  void uploadWordsByCsv({required String content, required Map<String, Uint8List?> assets}) async {
    final _storage = Storage()..fetch();
    final tc = TcService();
    final _batch = Batch();
    final COLUMN_WORD_ID = 0;
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
    final COLUMN_PIC_HASH = COLUMN_WORD_ID + 14;
    final SEPARATOR = '/';
    final PINYIN_SEPARATOR = '-';

    // Build Word from csv
    var csv = CsvToListConverter().convert(content)..removeWhere((w) => w[COLUMN_WORD] == null);

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

    // Upload file to cloud storage and save reference
    words.forEach((word) async {
      // Word image
      final pathWordPic = '${word.documentPath}/${EnumToString.convertToString(WordKey.pic)}';
      final picExtension =
          extension_image.where((e) => assets.containsKey('${word.id}.$e')).firstOrNull;
      if (picExtension != null) {
        final filename = '${word.id}.$picExtension';
        final mimeType = picExtension == 'png' ? mimeTypePng : mimeTypeJpeg;
        final wordPic = assets[filename]!;
        word.pic = await _storage.saveFromBytes(pathWordPic, wordPic,
            filename: filename, mimeType: mimeType, metadata: {'newPost': 'true'});
      }

      // Word Audio
      final pathWordAudioMale =
          '${word.documentPath}/${EnumToString.convertToString(WordKey.wordAudioMale)}';
      final pathWordAudioFemale =
          '${word.documentPath}/${EnumToString.convertToString(WordKey.wordAudioFemale)}';
      final wordAudioFileMale = assets['upload/${word.wordId}-W-M.$extension_audio']!;
      final wordAudioFileFemale = assets['upload/${word.wordId}-W-F.$extension_audio']!;
      word.wordAudioMale = await _storage.saveFromBytes(pathWordAudioMale, wordAudioFileMale,
          filename: '${word.wordId}-W-M.$extension_audio',
          mimeType: mimeTypeMpeg,
          metadata: {'newPost': 'true'});
      word.wordAudioFemale = await _storage.saveFromBytes(pathWordAudioFemale, wordAudioFileFemale,
          filename: '${word.wordId}-W-F.$extension_audio',
          mimeType: mimeTypeMpeg,
          metadata: {'newPost': 'true'});
      // Generate time series for word
      final wordAudioMaleEvaluation = await tc.sendSoeRequest(SoeRequest(
          UserVoiceData: base64Encode(wordAudioFileMale),
          SessionId: Uuid().v1(),
          RefText: word.wordAsString,
          ScoreCoeff: 4.0));
      word.wordAudioMaleTimeSeries =
          wordAudioMaleEvaluation.words!.map((w) => w.beginTime!).toList();
      final wordAudioFemaleEvaluation = await tc.sendSoeRequest(SoeRequest(
          UserVoiceData: base64Encode(wordAudioFileFemale),
          SessionId: Uuid().v1(),
          RefText: word.wordAsString,
          ScoreCoeff: 4.0));
      word.wordAudioFemaleTimeSeries =
          wordAudioFemaleEvaluation.words!.map((w) => w.beginTime!).toList();

      // Examples Audio
      // Each meaning
      await Future.forEach(word.wordMeanings!, (WordMeaning meaning) async {
        var maleAudios = <StorageFile>[];
        var femaleAudios = <StorageFile>[];
        var maleAudiosTimeSeries = <List<int>>[];
        var femaleAudiosTimeSeries = <List<int>>[];
        // Each example
        await Future.forEach(List.generate(meaning.exampleCount, (i) => i), (dynamic index) async {
          final pathExampleMaleAudio =
              '${word.documentPath}/${EnumToString.convertToString(WordMeaningKey.exampleMaleAudios)}';
          final pathExampleFemaleAudio =
              '${word.documentPath}/${EnumToString.convertToString(WordMeaningKey.exampleFemaleAudios)}';
          final exampleAudioFileMale = assets['upload/${word.wordId}-E$index-M.$extension_audio']!;
          final exampleAudioFileFemale =
              assets['upload/${word.wordId}-E$index-F.$extension_audio']!;
          final maleAudio = await _storage.saveFromBytes(pathExampleMaleAudio, exampleAudioFileMale,
              filename: '${word.wordId}-E$index-M.$extension_audio',
              mimeType: mimeTypeMpeg,
              metadata: {'newPost': 'true'});
          maleAudios.add(maleAudio);
          final femaleAudio = await _storage.saveFromBytes(
              pathExampleFemaleAudio, exampleAudioFileFemale,
              filename: '${word.wordId}-E$index-F.$extension_audio',
              mimeType: mimeTypeMpeg,
              metadata: {'newPost': 'true'});
          femaleAudios.add(femaleAudio);
          // Generate time series for example
          final exampleAudioFileMaleEvaluation = await tc.sendSoeRequest(SoeRequest(
              UserVoiceData: base64Encode(exampleAudioFileMale),
              SessionId: Uuid().v1(),
              RefText: meaning.examples[index].example,
              ScoreCoeff: 4.0));
          maleAudiosTimeSeries
              .add(exampleAudioFileMaleEvaluation.words!.map((w) => w.beginTime!).toList());

          final exampleAudioFileFemaleEvaluation = await tc.sendSoeRequest(SoeRequest(
              UserVoiceData: base64Encode(exampleAudioFileFemale),
              SessionId: Uuid().v1(),
              RefText: meaning.examples[index].example,
              ScoreCoeff: 4.0));
          femaleAudiosTimeSeries
              .add(exampleAudioFileFemaleEvaluation.words!.map((w) => w.beginTime!).toList());
        });
        meaning.exampleMaleAudios = maleAudios;
        meaning.exampleFemaleAudios = femaleAudios;
        meaning.exampleMaleAudioTimeSeries = maleAudiosTimeSeries;
        meaning.exampleFemaleAudioTimeSeries = femaleAudiosTimeSeries;
      });

      // Finally, save the word
      _batch.save(word);
    });
    await _batch.commit();

// Dispose uploader stream
    _storage.dispose();
  }

  Future<void> uploadLecturesByCsv(
      {required String content, required Map<String, Uint8List?> assets}) async {
    final _storage = Storage()..fetch();
    final _batch = Batch();
    final columnId = 0;
    final columnLevel = 1;
    final columnTitle = 2;
    final columnDescription = 3;
    final columnPicHash = 4;

    // Build Word from csv
    var csv = CsvToListConverter().convert(content)..removeWhere((w) => w[columnTitle] == null);

    var lectures = csv.map((row) => Lecture(id: row[columnId], level: row[columnLevel])
      ..title = row[columnTitle].trim() // Title should not be null
      ..description = row[columnDescription]?.trim()
      ..picHash = row[columnPicHash]?.trim());

    // Upload file to cloud storage and save reference
    await Future.forEach(lectures, (dynamic lecture) async {
      // Word image
      final pathClassPic =
          '${lecture.documentPath}/${EnumToString.convertToString(LectureKey.pic)}';
      final extension =
          extension_image.where((e) => assets.containsKey('${lecture.lectureId}.$e')).firstOrNull;
      if (extension == null) {
        return;
      }
      final mimeType = extension == 'png' ? mimeTypePng : mimeTypeJpeg;
      final filename = '${lecture.lectureId}.$extension';
      final lecturePic = assets[filename]!;
      lecture.pic = await _storage.saveFromBytes(pathClassPic, lecturePic,
          filename: filename, mimeType: mimeType, metadata: {'newPost': 'true'});

      // Finally, save the word
      _batch.save(lecture);
    });
    await _batch.commit();

    // Dispose uploader stream
    _storage.dispose();
  }

  void uploadSpeechExamsByCsv(
      {required String content, required Map<String, Uint8List?> assets}) async {
    final _storage = Storage()..fetch();
    final tc = TcService();
    final _batch = Batch();
    final column_id = 0;
    final column_title = 1;
    final column_question = 2;
    final column_ref_text = 3;

    // Build Word from csv
    var csv = CsvToListConverter().convert(content)..removeWhere((w) => w[column_title] == null);

    var exams = csv.map((row) => SpeechExam(id: row[column_id])
      ..title = row[column_title].trim() // Title should not be null
      ..question = row[column_question]?.trim()
      ..refText = row[column_ref_text]?.trim());

    // Checking status
    _storage.uploader.listen((data) {
      print('total: ${data.totalBytes} transferred: ${data.bytesTransferred}');
    });
    // Upload file to cloud storage and save reference
    exams.forEach((exam) async {
      final pathRefAudio =
          '${exam.documentPath}/${EnumToString.convertToString(SpeechExamKey.refAudio)}';
      final wordAudioFile =
          await tc.sendTtsRequest(TtsRequest(SessionId: Uuid().v1(), Text: exam.refText!));
      exam.refAudio = await _storage.saveFromBytes(pathRefAudio, wordAudioFile,
          filename: '${exam.id}.$extension_audio',
          mimeType: mimeTypeMpeg,
          metadata: {'newPost': 'true'});
      // Generate time series for word
      final refAudioEvaluation = await tc.sendSoeRequest(SoeRequest(
          UserVoiceData: base64Encode(wordAudioFile),
          SessionId: Uuid().v1(),
          RefText: exam.refText,
          ScoreCoeff: 4.0));
      exam.refAudioTimeSeries = refAudioEvaluation.words!.map((w) => w.beginTime!).toList();
      // Finally, save the word
      _batch.save(exam);
    });
    await _batch.commit();

// Dispose uploader stream
    _storage.dispose();
  }

  Future<List<Word>> fetchWords({List<String>? tags}) async {
    final collectionPaging = CollectionPaging<Word>(
      query: Word().collectionRef.orderBy('wordId'),
      limit: 10000,
      decode: (snap) => Word(snapshot: snap),
    );
    return await collectionPaging.load();
  }

  /// Fetch all entities extends exam
  Future<List<Exam>> fetchExams({List<String>? tags}) async {
    final collectionPaging = CollectionPaging<Exam>(
      query: Exam().collectionRef.orderBy('examId'),
      limit: 10000,
      decode: (snap) => Exam.fromSnapshot(snap), // don't use Exam()
    );
    return await collectionPaging.load();
  }

  Future<List<Lecture>> fetchLectures({List<String>? tags}) async {
    final collectionPaging = CollectionPaging<Lecture>(
      query: Lecture().collectionRef.orderBy('lectureId'),
      limit: 10000,
      decode: (snap) => Lecture(snapshot: snap),
    );
    return await collectionPaging.load();
  }

  Future<void> commitBatch<T extends UpdatableDocument>(Map<Rx<T>, String> batchMap) async {
    final _storage = Storage()..fetch();
    final _batch = Batch();
    for (final batch in batchMap.entries) {
      final action = batch.value;
      final doc = batch.key.value;
      _batch.actions[action]!(doc);
    }
    await _batch.commit();
    _storage.dispose();
  }
}
