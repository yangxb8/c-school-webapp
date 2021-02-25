// Flutter imports:
import 'package:flutter/cupertino.dart';

// Package imports:
import 'package:get/get.dart';

// Project imports:
import 'package:cschool_webapp/controller/lecture_management_controller.dart';
import 'package:cschool_webapp/view/lecture_management.dart';
import 'package:cschool_webapp/view/splash.dart';
import 'controller/home_controller.dart';
import 'service/app_state_service.dart';
import 'view/home.dart';

class AppRouter {
  static List<GetPage> setupRouter() {
    return [
      GetPage(
        name: '/splash',
        page: () => Splash(),
      ),
      GetPage(
          middlewares: [SplashMiddleware()],
          name: '/home',
          page: () => HomeScreen(),
          binding:
              BindingsBuilder(() => {Get.lazyPut(() => HomeController())})),
      GetPage(
          middlewares: [SplashMiddleware()],
          name: '/manage/lecture',
          page: () => LectureManagement(),
          binding: BindingsBuilder(
              () => {Get.lazyPut(() => LectureManagementController())})),
    ];
  }
}

class SplashMiddleware extends GetMiddleware {
  @override
  RouteSettings redirect(String route) {
    if (AppStateService.isInitialized) {
      return null;
    } else {
      return RouteSettings(name: '/splash', arguments: route);
    }
  }
}
