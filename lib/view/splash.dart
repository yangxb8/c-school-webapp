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
    // If redirected to splash, Go to original route. Otherwise go to /home
    await Get.offNamed(Get.arguments ?? '/home');
  }

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator().center().afterFirstLayout(_init);
  }
}

Future<void> initServices() async {
  if (AppStateService.isInitialized) return;
  await Get.putAsync<ApiService>(() async => await ApiService.getInstance());
  await Get.putAsync<UserService>(() async => await UserService.getInstance());
  Get.lazyPut<AudioService>(() => AudioService());
  await Get.find<ApiService>()
      .firebaseAuthApi
      .loginWithEmail('yangxb10@gmail.com', '199141');
  Logger.level = AppStateService.isDebug ? Level.debug : Level.error;
  AppStateService.isInitialized = true;
}
