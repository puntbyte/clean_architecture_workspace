mixin ComponentLogic {
  /// Checks if [targetId] matches any rule ID in the [configList].
  ///
  /// Supports:
  /// 1. Exact Match: 'data.repository' matches 'data.repository'
  /// 2. Parent Match: 'data' matches 'data.repository'
  /// 3. Suffix Match (Shorthand): 'repository' matches 'data.repository'
  bool matchesComponent(List<String> configList, String targetId) {
    for (final configId in configList) {
      // 1. Exact
      if (targetId == configId) return true;

      // 2. Parent Layer (Prefix)
      // Rule 'data' matches target 'data.repository'
      if (targetId.startsWith('$configId.')) return true;

      // 3. Shorthand (Suffix)
      // Rule 'repository' matches target 'data.repository'
      if (targetId.endsWith('.$configId')) return true;
    }
    return false;
  }
}
