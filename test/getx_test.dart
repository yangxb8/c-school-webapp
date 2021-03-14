// Package imports:
import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:supercharged/supercharged.dart';

void main() {
  test('RxList of custom class', () {
    var count = 0;
    var list = <MyClass>[].obs;
    ever(list, (dynamic val) => count++);
    1.rangeTo(4).forEach((e) => list.add(MyClass(e)));
    list.forEach((e) => e.id++);
    expect(count, 4, reason: 'Only list added event is observed, not element updated event');
    list.forEachIndexed((index, element) => expect(element.id, index + 2));
  });

  test('RxList of Rx<CustomClass>', () {
    var listCount = 0;
    var elementCount = 0;
    var list = <Rx<MyClass>>[].obs;
    ever(list, (dynamic _) => listCount++);
    1.rangeTo(4).forEach((e) => list.add(MyClass(e).obs));
    list.forEach((element) => ever(element, (dynamic _) => elementCount++));
    list.forEachIndexed((idx, e) => e.update((val) => val!.id = idx + 2));
    expect(listCount, 4, reason: 'Only list added event is observed, not element updated event');
    expect(elementCount, 4, reason: 'all elements updated once');
    list.forEachIndexed((index, element) {
      expect(element.value!.properties['id'], index + 2);
    });
    list.forEachIndexed((idx, e) => e.update((val) => val!.properties['id'] = idx + 5));
    list.forEachIndexed((index, element) {
      expect(element.value!.properties['id'], index + 2,
          reason: 'Must directly access value(val.id) to update properly');
    });
  });
}

class MyClass {
  int id;
  MyClass(this.id);

  Map<String, dynamic> get properties => {
        'id': id,
      };
}
