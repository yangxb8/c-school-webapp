// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:get/get.dart';

// Project imports:
import 'package:cschool_webapp/service/lecture_service.dart';
import 'package:cschool_webapp/view/ui_view/webapp_drawer.dart';

class WordManagementHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word'),
      ),
      drawer: const CSchoolWebAppDrawer(),
      body: ListView.builder(
          itemCount: LectureService.allLecturesObx.length,
          itemBuilder: (_, index) {
            var lecture = LectureService.allLecturesObx[index].value;
            return ListTile(
              title: Text(lecture.title),
              trailing: Text(lecture.words.length.toString()),
              onTap: () => Get.toNamed('/manage/word/${lecture.id}'),
            );
          }),
    );
  }
}
