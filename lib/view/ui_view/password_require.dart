import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

void showPasswordRequireDialog({Function success, Function fail, Function last}) {
  const pwd = 'miaojiangfangpi';
  var inProgress = false;
  final textInputController = TextEditingController();

  Get.dialog(
      ModalProgressHUD(
        inAsyncCall: inProgress,
        child: AlertDialog(
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
                    inProgress = true;
                    if (textInputController.text == pwd && success != null) {
                      await success();
                    } else if (fail != null) {
                      await fail();
                    }
                    if (last != null) {
                      await last();
                    }
                    inProgress = false;
                    Get.back();
                    if (textInputController.text != pwd) {
                      Get.snackbar('操作失败', '密码错误');
                    }
                  },
                  child: Text('变更')),
            ]),
      ),
      barrierDismissible: false);
}
