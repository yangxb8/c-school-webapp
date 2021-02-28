// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:get/get.dart';

class CSchoolWebAppDrawer extends StatelessWidget {
  const CSchoolWebAppDrawer();
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          ListTile(title: Text('课程管理') ,onTap: ()=>Get.offNamed('/manage/lecture'),),
          ListTile(title: Text('单词管理') ,onTap: ()=>Get.offNamed('/manage/word'),)
        ],
      ),
    );
  }
}
