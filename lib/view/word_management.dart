import 'package:cschool_webapp/controller/word_management_controller.dart';
import 'package:cschool_webapp/model/word.dart';
import 'package:cschool_webapp/view/ui_view/document_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:get/get.dart';

class WordManagement extends GetView<WordManagementController>{
  @override
  Widget build(BuildContext context) {
    var schema = <String, double>{
      'id': 100.0,
      '单词': 100,
      '拼音': 100,
      '单词音频': 100,
      '词性': 100,
      '日语意思': 100,
      '提示': 100,
      '解释': 200,
      'tags':100,
      '图片': 100,
      '占位图片': 100,
      '例句': 200,
      '其他意思ID': 100,
      '关联单词ID': 100,
    };

    Widget exampleContentBuilder(Word word){
      throw UnimplementedError();
    };

    Widget exampleInputBuilder(Word word){
      throw UnimplementedError();
    }

    return DocumentManager<Word, WordManagementController>(
      schema: schema,
      contentBuilder: {
        '例句':exampleContentBuilder
      },
      inputBuilder: {
        '例句':exampleInputBuilder
      },
    );
  }

}