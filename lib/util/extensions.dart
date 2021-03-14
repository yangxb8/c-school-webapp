// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:fuzzy/fuzzy.dart';

// Project imports:
import 'classes.dart';

extension DateTimeExtension on DateTime {
  String yyyyMMdd() {
    var mm = month < 10 ? '0$month' : '$month';
    var dd = day < 10 ? '0$day' : '$day';
    return '$this.year$mm$dd';
  }
  String get yyyy_MM_dd {
    var mm = month.toString().padLeft(2,'0');
    var dd = day.toString().padLeft(2,'0');
    return '$year-$mm-$dd';
  }
}

RegExp singleHanziRegExp = RegExp(r'[\u4e00-\u9fa5]{1}',
    caseSensitive: false, multiLine: false, unicode: true);

extension HanziUtil on String {
  bool get isSingleHanzi {
    assert(length == 1);
    return singleHanziRegExp.hasMatch(this);
  }
}

extension StringListUtil on Iterable<String> {
  /// Fuzzy search a list of String by keyword, options can be provided
  List<String> searchFuzzy(String key, {FuzzyOptions? options}) {
    options ??=
        FuzzyOptions(findAllMatches: true, tokenize: true, threshold: 0.5);
    final fuse = Fuzzy(toList(), options: options);
    return fuse.search(key).map((r) => r.item.toString()) as List<String>;
  }

  /// Search if this string list contains key fuzzily
  bool containsFuzzy(String key, {FuzzyOptions? options}) {
    options ??=
        FuzzyOptions(findAllMatches: true, tokenize: true, threshold: 0.5);
    final fuse = Fuzzy(toList(), options: options);
    return fuse.search(key).isNotEmpty;
  }

  List<String> get copy => map((s) => s.substring(0)).toList();
}

extension StringUtil on String {
  /// Search if this string contains key fuzzily
  bool containsFuzzy(String key, {FuzzyOptions? options}) {
    return [this].containsFuzzy(key, options: options);
  }
}

extension WidgetWrapper on Widget {
  Widget statefulWrapper(
      {Function? onInit,
      Function? afterFirstLayout,
      Function? deactivate,
      Function? didUpdateWidget,
      Function? dispose}) {
    return StatefulWrapper(
      onInit: onInit,
      afterFirstLayout: afterFirstLayout,
      deactivate: deactivate,
      didUpdateWidget: didUpdateWidget,
      dispose: dispose,
      child: this,
    );
  }

  Widget onInit(Function onInit) {
    return StatefulWrapper( onInit: onInit, child: this,);
  }

  Widget afterFirstLayout(Function afterFirstLayout) {
    return StatefulWrapper( afterFirstLayout: afterFirstLayout,child: this,);
  }
}
