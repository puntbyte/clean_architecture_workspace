// lib/utils/npl/cache.dart

import 'package:dictionaryx/dictentry.dart';
import 'package:meta/meta.dart';

/// Public cache key used across files.
@immutable
class CacheKey {
  final POS pos; // Use the POS enum from dictionaryx
  final String token;

  const CacheKey(this.pos, this.token);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CacheKey && other.pos == pos && other.token == token);

  @override
  int get hashCode => Object.hash(pos, token);
}

/// Public cache value wrapper with timestamp.
class CacheValue<T> {
  final T value;
  final DateTime timestamp;

  CacheValue(this.value) : timestamp = DateTime.now();
}
