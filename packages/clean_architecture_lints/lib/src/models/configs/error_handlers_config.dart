// lib/src/models/configs/error_handlers_config.dart

import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/utils/config/config_keys.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

part '../details/error_handlers_detail.dart';

part '../rules/error_handler_rule.dart';

/// The main configuration for Error Handling.
class ErrorHandlersConfig {
  final List<ErrorHandlerRule> rules;

  const ErrorHandlersConfig({required this.rules});

  factory ErrorHandlersConfig.fromMap(Map<String, dynamic> map) {
    final list = map.asMapList(ConfigKey.root.errorHandlers);
    return ErrorHandlersConfig(
      rules: list.map(ErrorHandlerRule.fromMap).toList(),
    );
  }

  ErrorHandlerRule? ruleFor(ArchComponent component) {
    return rules.firstWhereOrNull((rule) => rule.on == component.id);
  }
}
