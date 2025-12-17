// lib/src/schema/descriptors/action_source.dart

import 'package:architecture_lints/src/schema/enums/action_element.dart';
import 'package:architecture_lints/src/schema/enums/action_scope.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class ActionSource {
  final ActionScope scope;
  final String? component;
  final ActionElement? element;

  const ActionSource({this.scope = ActionScope.current, this.component, this.element});

  factory ActionSource.fromMap(Map<String, dynamic> map) => ActionSource(
    scope: ActionScope.fromKey(map.tryGetString('scope')),
    component: map.tryGetString('component'),
    element: ActionElement.fromKey(map.tryGetString('element')),
  );
}
