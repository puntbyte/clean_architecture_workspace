// lib/src/schema/descriptors/action_trigger.dart

import 'package:architecture_lints/src/schema/enums/action_element.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class ActionTrigger {
  final String? component;
  final ActionElement? element;
  final String? errorCode;

  const ActionTrigger({this.component, this.element, this.errorCode});

  factory ActionTrigger.fromMap(Map<String, dynamic> map) => ActionTrigger(
    component: map.tryGetString('component'),
    element: ActionElement.fromKey(map.tryGetString('element')),
    errorCode: map.tryGetString('error_code'),
  );
}
