import 'package:cschool_webapp/controller/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'ui_view/webapp_drawer.dart';

class HomeScreen extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('CSchool后台管理'),),
      drawer: const CSchoolWebAppDrawer(),
      body: Container(
        alignment: Alignment.centerLeft,
        child: Text('请点击左上角的菜单'),
      ),
    );
  }
}
