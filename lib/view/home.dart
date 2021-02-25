// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:get/get.dart';
import 'package:styled_widget/styled_widget.dart';

// Project imports:
import 'package:cschool_webapp/controller/home_controller.dart';
import 'ui_view/webapp_drawer.dart';

class HomeScreen extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('CSchool后台管理'),),
      drawer: const CSchoolWebAppDrawer(),
      body: Container(
        alignment: Alignment.centerLeft,
        child: Text('请点击左上角的菜单').center(),
      ),
    );
  }
}
