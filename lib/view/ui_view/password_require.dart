import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

void showPasswordRequireDialog(Function callback) {
  const pwd = 'miaojiangfangpi';
  var inProgress = false;
  final textInputController = TextEditingController();

  Get.dialog(ModalProgressHUD(
    inAsyncCall: inProgress,
    child: AlertDialog(
        title: Text('请输入密码'),
        content: TextField(
          obscureText: true,
          controller: textInputController,
        ),
        actions: [
          TextButton(
              onPressed: () {
                Get.back();
              },
              child: Text('取消')),
          TextButton(
              onPressed: () async {
                inProgress = true;
                if (textInputController.text == pwd) {
                  await callback();
                } else {
                  Get.snackbar('操作失败', '密码错误');
                }
                inProgress = false;
                Get.back();
              },
              child: Text('变更')),
        ]),
  ),barrierDismissible: false);
}
