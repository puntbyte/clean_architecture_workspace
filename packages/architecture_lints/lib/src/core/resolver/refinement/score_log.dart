import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'dart:math' as math;

class ScoreEntry {
  final String tag;
  final String description;
  final double score;

  ScoreEntry(this.tag, this.description, this.score);
}

class ScoreLog implements Comparable<ScoreLog> {
  final Candidate candidate;
  final List<ScoreEntry> _entries = [];
  double _totalScore = 0.0;

  /// Normalized confidence (0.0 to 1.0)
  double confidence = 0.0;

  ScoreLog(this.candidate);

  double get totalScore => _totalScore;

  void add(double points, String description) {
    _totalScore += points;

    // Split "TAG: Detail" string
    final parts = description.split(':');
    final tag = parts.isNotEmpty ? parts.first.trim() : 'MISC';
    final detail = parts.length > 1 ? parts.sublist(1).join(':').trim() : '';

    _entries.add(ScoreEntry(tag, detail, points));
  }

  @override
  int compareTo(ScoreLog other) {
    return other._totalScore.compareTo(_totalScore); // Descending
  }

  /// Generates the pretty output
  String generateReport({bool isWinner = false}) {
    final sb = StringBuffer();
    final icon = isWinner ? '🏆' : '  ';

    // Header
    sb.writeln('$icon ${candidate.component.id}');

    // Visual Confidence Bar
    final percent = (confidence * 100).clamp(0, 100).round();
    final barLength = 10;
    final filled = (confidence * barLength).round();
    final bar = '█' * filled + '░' * (barLength - filled);

    sb.writeln('   $bar $percent% (Score: ${_totalScore.toStringAsFixed(1)})');
    sb.writeln('');

    // Entries
    for (final entry in _entries) {
      final sign = entry.score >= 0 ? '+' : '';
      final scoreStr = '$sign${entry.score.toStringAsFixed(0)}'.padLeft(5); // e.g. "  +50"
      final tagStr = '[${entry.tag}]'.padRight(10);

      sb.writeln('   $scoreStr $tagStr ${entry.description}');
    }

    sb.writeln(''); // Spacer
    return sb.toString();
  }
}