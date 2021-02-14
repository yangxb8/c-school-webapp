import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CSchoolWebAppDrawer extends StatelessWidget {
  const CSchoolWebAppDrawer();
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          ListTile(title: Text('课程管理') ,onTap: ()=>Get.toNamed('/manage/lecture'),)
        ],
      ),
    );
  }
}
