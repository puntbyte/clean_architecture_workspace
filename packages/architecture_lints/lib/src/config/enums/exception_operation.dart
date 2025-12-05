import 'package:collection/collection.dart';

enum ExceptionOperation {
  /// YAML: 'try_return'
  tryReturn('try_return', 'Return value inside a try block'),

  /// YAML: 'catch_return'
  catchReturn('catch_return', 'Return value inside a catch block'),

  /// YAML: 'catch_throw'
  catchThrow('catch_throw', 'Throw exception inside a catch block'),

  /// YAML: 'throw'
  throw$('throw', 'Explicit throw statement'),

  /// YAML: 'rethrow'
  rethrow$('rethrow', 'Rethrow statement')
  ;

  final String yamlKey;
  final String description;

  const ExceptionOperation(this.yamlKey, this.description);

  static ExceptionOperation? fromKey(String? key) {
    return ExceptionOperation.values.firstWhereOrNull((e) => e.yamlKey == key);
  }
}
