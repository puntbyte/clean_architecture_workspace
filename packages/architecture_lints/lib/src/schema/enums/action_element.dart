// lib/src/schema/enums/action_element.dart

import 'package:collection/collection.dart';

enum ActionElement {
  method('method'),
  field('field'),
  clazz('class'),
  constructor('constructor'),
  file('file');

  final String yamlKey;
  const ActionElement(this.yamlKey);

  static ActionElement? fromKey(String? key) =>
      ActionElement.values.firstWhereOrNull((e) => e.yamlKey == key);
}
