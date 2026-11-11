/// Canonical lifecycle state for one WorkoutSession.
enum WorkoutSessionStatus {
  active('active'),
  paused('paused'),
  completed('completed'),
  discarded('discarded');

  const WorkoutSessionStatus(this.wireValue);

  /// Canonical serialization token.
  final String wireValue;

  /// Whether this state is terminal (no further transitions permitted).
  bool get isTerminal =>
      this == WorkoutSessionStatus.completed ||
      this == WorkoutSessionStatus.discarded;

  /// Whether transitioning from this state to [next] is legally permitted.
  bool canTransitionTo(WorkoutSessionStatus next) {
    if (this == next) return false;
    return switch (this) {
      WorkoutSessionStatus.active =>
        next == WorkoutSessionStatus.paused ||
            next == WorkoutSessionStatus.completed ||
            next == WorkoutSessionStatus.discarded,
      WorkoutSessionStatus.paused =>
        next == WorkoutSessionStatus.active ||
            next == WorkoutSessionStatus.completed ||
            next == WorkoutSessionStatus.discarded,
      WorkoutSessionStatus.completed => false,
      WorkoutSessionStatus.discarded => false,
    };
  }

  /// Parses from a wire storage token.
  static WorkoutSessionStatus fromWire(String value) {
    for (final status in values) {
      if (status.wireValue == value) return status;
    }
    throw ArgumentError.value(value, 'value', 'Unknown WorkoutSessionStatus');
  }
}
