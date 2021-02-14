import 'package:flamingo/flamingo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

import 'routers.dart';
import 'service/api_service.dart';
import 'service/app_state_service.dart';
import 'service/audio_service.dart';
import 'service/user_service.dart';
import 'util/utility.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'CSchool后台管理',
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.fade,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale.fromSubtags(languageCode: 'zh'),
      ],
      getPages: AppRouter.setupRouter(),
      home: CSchoolWebApp(),
    );
  }
}

class CSchoolWebApp extends StatelessWidget {
  Future<void> _init() async {
    await initServices();
    await Get.toNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Container().afterFirstLayout(_init);
  }
}

Future<void> initServices() async {
  await Get.putAsync<ApiService>(() async => await ApiService.getInstance());
  await Flamingo.initializeApp();
  await Get.putAsync<UserService>(() async => await UserService.getInstance());
  Get.lazyPut<AudioService>(() => AudioService());
  Logger.level = AppStateService.isDebug ? Level.debug : Level.error;
}
