import 'package:auto_size_text/auto_size_text.dart';
import 'package:cschool_webapp/controller/word_management_controller.dart';
import 'package:cschool_webapp/model/word.dart';
import 'package:cschool_webapp/view/ui_view/document_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:get/get.dart';
import 'package:reactive_forms/reactive_forms.dart';

class WordManagement extends GetView<WordManagementController> {
  static const idPattern = r'^C\d{4}-\d{3}$';
  static const hanziPattern = r'^[\u4e00-\u9fa5]*[。？！]*';

  static const schema = <String, double>{
    'id': 100.0,
    '单词': 100,
    '拼音': 100,
    '词性': 100,
    '日语意思': 100,
    '例句': 400,
    '提示': 100,
    '解释': 200,
    'tags': 100,
    '图片': 100,
    '占位图片': 100,
    '其他意思ID': 100,
    '关联单词ID': 100,
  };

  static const uneditableFields = ['占位图片'];

  @override
  Widget build(BuildContext context) {
    var validators = {
      'id': [Validators.required, Validators.pattern(idPattern)],
      '单词': [Validators.required, Validators.pattern(hanziPattern)],
      '日语意思': [Validators.required],
      '例句-中文': [Validators.pattern(hanziPattern)]
    };

    ValidatorFunction _equalLength(String controlName, String matchingControlName) {
      return (AbstractControl<dynamic> control) {
        final form = control as FormGroup;

        final formControl = form.control(controlName);
        final matchingFormControl = form.control(matchingControlName);

        if (formControl.value.split('/').length != matchingFormControl.value.split('/').length) {
          matchingFormControl.setErrors({'equalLength': true});

          // force messages to show up as soon as possible
          matchingFormControl.markAsTouched();
        } else {
          matchingFormControl.removeError('equalLength');
        }

        return null;
      };
    }

    Widget exampleContentBuilder(Word word) {
      if (word.wordMeanings.isEmpty) {
        return const SizedBox.expand();
      }
      final examples = word.wordMeanings.single.examples;
      // If we have too many examples, let it overflow
      return ListView.separated(
        itemCount: examples.length,
        itemBuilder: (BuildContext _, int i) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AutoSizeText(
              examples[i].pinyin.join('-'),
              maxLines: 2,
            ),
            AutoSizeText(
              examples[i].example,
              maxLines: 2,
            ),
            AutoSizeText(
              examples[i].meaning,
              maxLines: 2,
            ),
          ],
        ),
        separatorBuilder: (BuildContext _, int __) => const Divider(),
      );
    }

    Widget exampleInputBuilder(Word word) {
      final examples = word.wordMeanings.single.examples;
      controller.form(FormGroup({
        '例句-拼音': FormControl(value: examples.map((e) => e.pinyin.join('-')).join('/')),
        '例句-中文': FormControl(
            value: examples.map((e) => e.example).join('/'), validators: validators['例句-中文']),
        '例句-日语': FormControl(value: examples.map((e) => e.meaning).join('/')),
      }, validators: [
        _equalLength('例句-中文', '例句-日语'),
        _equalLength('例句-中文', '例句-拼音')
      ]));

      return ReactiveForm(
          formGroup: controller.form.value,
          child: Column(
            children: [
              ReactiveTextField(
                formControlName: '例句-拼音',
              ),
              ReactiveTextField(
                formControlName: '例句-中文',
              ),
              ReactiveTextField(
                formControlName: '例句-日语',
              ),
            ],
          ));
    }

    return DocumentManager<Word, WordManagementController>(
      schema: schema,
      uneditableFields: uneditableFields,
      validators: validators,
      contentBuilder: {'例句': exampleContentBuilder},
      inputBuilder: {'例句': exampleInputBuilder},
    );
  }
}
