// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:get/get.dart';

Future<void> showPasswordRequireDialog({Function success, Function fail, Function last}) async{
  const pwd = 'miaojiangfangpi';
  final textInputController = TextEditingController();

  await Get.dialog(
      AlertDialog(
          title: Text('请输入密码'),
          content: TextField(
            obscureText: true,
            controller: textInputController,
          ),
          actions: [
            TextButton(
                onPressed: () async{
                  if (last != null) {
                    await last();
                  }
                  Get.back();
                },
                child: Text('取消')),
            TextButton(
                onPressed: () async {
                  if (textInputController.text == pwd && success != null) {
                    await success();
                  } else if (fail != null) {
                    await fail();
                  }
                  if (last != null) {
                    await last();
                  }
                  Get.back();
                  if (textInputController.text != pwd) {
                    Get.snackbar('操作失败', '密码错误');
                  }
                },
                child: Text('变更')),
          ]),
      barrierDismissible: false);
}
