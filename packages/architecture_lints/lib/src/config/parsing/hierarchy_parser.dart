class HierarchyParser {
  const HierarchyParser._();

  /// Parses a hybrid hierarchical YAML map into a flat Map of [ID -> Object].
  static Map<String, T> parse<T>({
    required Map<String, dynamic> yaml,
    // CHANGED: Factory now accepts dynamic value (could be Map or String)
    required T Function(String id, dynamic value) factory,
    Set<String> scopeKeys = const {},
    // CHANGED: Validation now accepts dynamic value
    bool Function(dynamic value)? shouldParseNode,
  }) {
    final results = <String, T>{};

    _parseNode(
      node: yaml,
      parentId: '',
      results: results,
      scopeKeys: scopeKeys,
      factory: factory,
      shouldParseNode: shouldParseNode,
    );

    return results;
  }

  static void _parseNode<T>({
    required dynamic node, // CHANGED: allow non-Map inputs
    required String parentId,
    required Map<String, T> results,
    required Set<String> scopeKeys,
    required T Function(String id, dynamic value) factory,
    bool Function(dynamic value)? shouldParseNode,
  }) {
    // 1. Try to parse the current node as an object [T]
    if (parentId.isNotEmpty) {
      bool isValid = true;
      if (shouldParseNode != null) {
        isValid = shouldParseNode(node);
      }

      if (isValid) {
        try {
          results[parentId] = factory(parentId, node);
        } catch (_) {}
      }
    }

    // 2. Iterate children (Only if node is a Map)
    if (node is! Map) return;

    for (final entry in node.entries) {
      final key = entry.key.toString();
      final value = entry.value;

      // --- CASE A: Child Node (starts with .) ---
      if (key.startsWith('.')) {
        final childSuffix = key.substring(1);
        final newId = parentId.isEmpty
            ? childSuffix
            : '$parentId.$childSuffix';

        _parseNode(
          node: value, // Recurse with value (Map or String)
          parentId: newId,
          results: results,
          scopeKeys: scopeKeys,
          factory: factory,
          shouldParseNode: shouldParseNode,
        );
        continue;
      }

      // --- CASE B: Root Level Special Handling ---
      if (parentId.isEmpty) {
        // Sub-case B1: Scope Key
        if (scopeKeys.contains(key)) {
          _parseNode(
            node: value,
            parentId: key,
            results: results,
            scopeKeys: scopeKeys,
            factory: factory,
            shouldParseNode: shouldParseNode,
          );
          continue;
        }

        // Sub-case B2: Flat Key
        _parseNode(
          node: value,
          parentId: key,
          results: results,
          scopeKeys: scopeKeys,
          factory: factory,
          shouldParseNode: shouldParseNode,
        );
        continue;
      }
    }
  }
}