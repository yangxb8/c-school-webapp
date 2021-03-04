// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:styled_widget/styled_widget.dart';

// Project imports:
import 'package:cschool_webapp/service/api_service.dart';
import 'package:cschool_webapp/service/app_state_service.dart';
import 'package:cschool_webapp/service/audio_service.dart';
import 'package:cschool_webapp/service/user_service.dart';
import '../util/utility.dart';

class Splash extends StatelessWidget {
  Future<void> _init() async {
    await initServices();
    if (AppStateService.isInitialized.isTrue) {
      // If redirected to splash, Go to original route. Otherwise go to /home
      await Get.offNamed(Get.arguments ?? '/home');
    } else {
      once(AppStateService.isInitialized, (_) => Get.offNamed(Get.arguments ?? '/home'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator().center().afterFirstLayout(_init);
  }
}

Future<void> initServices() async {
  if (AppStateService.isInitialized.isTrue) return;
  await Get.putAsync<ApiService>(() async => await ApiService.getInstance());
  await Get.find<ApiService>().firebaseAuthApi.loginWithEmail('yangxb10@gmail.com', '199141');
  await Get.putAsync<UserService>(() async => await UserService.getInstance());
  Get.lazyPut<AudioService>(() => AudioService());
  Logger.level = AppStateService.isDebug ? Level.debug : Level.error;
  if (UserService.isLectureServiceInitialized.isTrue) {
    AppStateService.isInitialized.value = true;
  } else {
    once(
        UserService.isLectureServiceInitialized, (_) => AppStateService.isInitialized.value = true);
  }
}
