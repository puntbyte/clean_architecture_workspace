import 'package:architecture_lints/src/context/module_context.dart';
import 'package:architecture_lints/src/engines/file/module_resolver.dart';
import 'package:architecture_lints/src/schema/definitions/module_definition.dart';

mixin ModuleLogic {
  /// Resolves the module context for a file.
  /// Delegates to the centralized [ModuleResolver] engine.
  ModuleContext? resolveModuleContext(String filePath, List<ModuleDefinition> modules) {
    // Instantiate the engine on the fly.
    // Since ModuleResolver is lightweight (just holds the list), this is cheap.
    return ModuleResolver(modules).resolve(filePath);
  }
}
