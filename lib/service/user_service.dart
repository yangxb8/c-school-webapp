// 📦 Package imports:
import 'package:get/get.dart';
// 🌎 Project imports:
import '../model/user.dart';
import 'api_service.dart';
import 'lecture_service.dart';

/// Provide user related service, like create and update user
class UserService extends GetxService {
  static UserService? _instance;
  static late AppUser user;
  static final ApiService _apiService = Get.find();
  static final isLectureServiceInitialized = false.obs;

  static Future<UserService> getInstance() async {
    if (_instance == null) {
      _instance = UserService();
      await _refreshAppUser();
      _listenToFirebaseAuth();
    }
    return _instance!;
  }

  static void _listenToFirebaseAuth() {
    _apiService.firebaseAuthApi.listenToFirebaseAuth(_refreshAppUser);
  }

  /// Return Empty AppUser if firebase user is null, otherwise,
  /// return AppUser fetched from firestore
  static Future<AppUser> _getCurrentUser() async =>
      await _apiService.firestoreApi
          .fetchAppUser(firebaseUser: await _apiService.firebaseAuthApi.getCurrentUser()) ??
          AppUser();

  static Future<void> _refreshAppUser() async {
    user = await _getCurrentUser();
    if (user.isLogin() && isLectureServiceInitialized.isFalse) {
      await Get.putAsync<LectureService>(() async => (await LectureService.getInstance())!);
      isLectureServiceInitialized.toggle();
    }
  }

  static void commitChange() {
    if (!user.isLogin()) {
      logger.e('AppUser is not registered! Commit is canceled');
      return;
    }
    _apiService.firestoreApi.updateAppUser(user, _refreshAppUser);
  }

  /// Commit any change made to user
  @override
  void onClose() {
    commitChange();
    super.onClose();
  }
}
