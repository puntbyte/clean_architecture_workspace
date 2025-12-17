// lib/src/schema/descriptors/action_target.dart

import 'package:architecture_lints/src/schema/enums/action_element.dart';
import 'package:architecture_lints/src/schema/enums/action_scope.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class ActionTarget {
  final ActionScope scope;
  final String? component;
  final ActionElement? element;

  const ActionTarget({this.scope = ActionScope.related, this.component, this.element});

  factory ActionTarget.fromMap(Map<String, dynamic> map) => ActionTarget(
    scope: ActionScope.fromKey(map.tryGetString('scope')),
    component: map.tryGetString('component'),
    element: ActionElement.fromKey(map.tryGetString('element')),
  );
}
