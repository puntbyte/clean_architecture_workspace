/// Standardized weights for component resolution.
enum ScoreWeight {
  /// Defines a "Must Have". If failed, practically disqualifies the candidate.
  veto(-1000),

  /// A very strong signal (e.g. Explicit Inheritance requirement met).
  critical(100),

  /// A strong signal (e.g. Naming pattern match).
  strong(50),

  /// A moderate signal (e.g. "Impl" convention).
  medium(20),

  /// A weak signal (e.g. Path depth).
  weak(10),

  /// A minor adjustment (e.g. Tie-breaking).
  tiny(0.1)
  ;

  final double value;

  const ScoreWeight(this.value);
}
