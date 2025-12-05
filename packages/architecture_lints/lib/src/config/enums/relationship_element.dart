import 'package:collection/collection.dart';

enum RelationshipElement {
  /// YAML: 'class'
  classElement('class'),

  /// YAML: 'method'
  methodElement('method')
  ;

  final String yamlKey;

  const RelationshipElement(this.yamlKey);

  static RelationshipElement? fromKey(String? key) {
    return RelationshipElement.values.firstWhereOrNull((e) => e.yamlKey == key);
  }
}
