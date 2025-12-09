import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' as p;

class RefinementContext {
  final String filePath;
  final ResolvedUnitResult unit;

  /// The main class/element in the file (lazy loaded or pre-calculated).
  late final NamedCompilationUnitMember? mainNode;
  late final Element? mainElement;
  late final String? mainName;

  RefinementContext({required this.filePath, required this.unit}) {
    _analyze();
  }

  void _analyze() {
    final filename = p.basenameWithoutExtension(filePath);
    // Naive PascalCase conversion for matching
    final expectedName = filename.split('_')
        .map((s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '')
        .join();

    NamedCompilationUnitMember? exactMatch;
    NamedCompilationUnitMember? firstStructural;
    NamedCompilationUnitMember? firstPublic;

    for (final declaration in unit.unit.declarations) {
      if (declaration is! NamedCompilationUnitMember) continue;

      final name = declaration.name.lexeme;

      if (name == expectedName) {
        exactMatch = declaration;
        break;
      }

      final isStructural = declaration is ClassDeclaration ||
          declaration is MixinDeclaration ||
          declaration is EnumDeclaration ||
          declaration is ExtensionDeclaration;

      if (!name.startsWith('_')) {
        if (isStructural && firstStructural == null) firstStructural = declaration;
        if (firstPublic == null) firstPublic = declaration;
      }
    }

    mainNode = exactMatch ??
        firstStructural ??
        firstPublic ??
        (unit.unit.declarations.whereType<NamedCompilationUnitMember>().firstOrNull);

    mainElement = mainNode?.declaredFragment?.element;
    mainName = mainNode?.name.lexeme;
  }
}