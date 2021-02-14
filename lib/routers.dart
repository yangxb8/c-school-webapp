import 'package:cschool_webapp/controller/lecture_management_controller.dart';
import 'package:cschool_webapp/view/lecture_management.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controller/home_controller.dart';
import 'controller/login_controller.dart';
import 'service/user_service.dart';
import 'view/home.dart';
import 'view/login_page.dart';

class AppRouter {
  static List<GetPage> setupRouter() {
    return [
      GetPage(
          name: '/login',
          page: () => LoginPage(),
          binding: BindingsBuilder(
                  () => {Get.lazyPut<LoginController>(() => LoginController())})),
      GetPage(
          middlewares: [HomeRouteMiddleware()],
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

class HomeRouteMiddleware extends GetMiddleware{
  @override
  RouteSettings redirect(String route) {
    if(UserService.user!=null && UserService.user.isLogin()){
      return null;
    } else {
      return RouteSettings(name: '/login');
    }
  }
}
