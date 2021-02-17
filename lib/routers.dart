import 'package:cschool_webapp/controller/lecture_management_controller.dart';
import 'package:cschool_webapp/view/lecture_management.dart';
import 'package:get/get.dart';

import 'controller/home_controller.dart';
import 'view/home.dart';

class AppRouter {
  static List<GetPage> setupRouter() {
    return [
      GetPage(
          name: '/home',
          page: () =>HomeScreen(),
          binding: BindingsBuilder(() =>
          {Get.lazyPut<HomeController>(() => HomeController())})),
      GetPage(
          name: '/manage/lecture',
          page: () =>LectureManagement(),
          binding: BindingsBuilder(() =>
          {Get.lazyPut<LectureManagementController>(() => LectureManagementController())})),
    ];
  }
}
