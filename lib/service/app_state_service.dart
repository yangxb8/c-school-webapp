/*
* This class provide AppState from firebase/shared_preference/others
* It should not expose inner service(_localStorageService etc.) usage!!!
* This service use ApiService and LocalStorageService so they must be
* initialized first!
*/
import 'package:get/get.dart';

class AppStateService {
  static RxBool isInitialized = false.obs;

  static bool get isDebug {
    var debugMode = false;
    assert(debugMode = true);
    return debugMode;
  }
}
