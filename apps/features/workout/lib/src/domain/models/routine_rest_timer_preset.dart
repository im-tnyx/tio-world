import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';

/// Configured rest duration preset for an Exercise entry in Routine Create/Edit.
///
/// Normal and Warm-up presets are independently optional:
/// - Both null: Rest Timer is OFF.
/// - Normal present, Warm-up null: Warm-up sets fallback to Normal duration.
/// - Normal null, Warm-up present: Warm-up sets use Warm-up duration; non-Warm-up sets are OFF.
/// - Both present: Warm-up sets use Warm-up duration; non-Warm-up sets use Normal duration.
///
/// Failure and Drop sets inherit the Normal preset (they do not have separate presets).
/// Explicit zero seconds (0) is distinct from OFF (null).
@immutable
final class RoutineRestTimerPreset {
  const RoutineRestTimerPreset({
    this.normalRestSeconds,
    this.warmUpRestSeconds,
  })  : assert(
          normalRestSeconds == null || normalRestSeconds >= 0,
          'normalRestSeconds must be null or non-negative',
        ),
        assert(
          warmUpRestSeconds == null || warmUpRestSeconds >= 0,
          'warmUpRestSeconds must be null or non-negative',
        );

  final int? normalRestSeconds;
  final int? warmUpRestSeconds;

  bool get isOff => normalRestSeconds == null && warmUpRestSeconds == null;

  /// Resolves effective rest duration in seconds for a given [RoutineSetType].
  ///
  /// Approved rules:
  /// - Warm-up timer ON: Warm-up sets use Warm-up duration.
  /// - Warm-up timer OFF: Warm-up sets fallback to Normal timer.
  /// - Normal timer ON: Normal, Failure, and Drop sets use Normal timer.
  /// - Normal timer OFF: Normal, Failure, and Drop sets have effective rest OFF (null).
  /// - Both OFF: All set types have effective rest OFF (null).
  int? effectiveRestFor(RoutineSetType setType) {
    if (setType == RoutineSetType.warmUp) {
      return warmUpRestSeconds ?? normalRestSeconds;
    }
    return normalRestSeconds;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutineRestTimerPreset &&
          other.normalRestSeconds == normalRestSeconds &&
          other.warmUpRestSeconds == warmUpRestSeconds;

  @override
  int get hashCode => Object.hash(normalRestSeconds, warmUpRestSeconds);
}

/// Formatter for rest durations, header summary labels, and accessibility semantics.
class RoutineRestTimerFormatter {
  const RoutineRestTimerFormatter._();

  /// Formats a non-negative duration in seconds into a concise label.
  ///
  /// Examples:
  /// - 0 -> "0s"
  /// - 45 -> "45s"
  /// - 60 -> "1min"
  /// - 90 -> "1min 30s"
  /// - 120 -> "2min"
  static String formatSeconds(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    }
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (remainingSeconds == 0) {
      return '${minutes}min';
    }
    return '${minutes}min ${remainingSeconds}s';
  }

  /// Formats the summary text shown on the Exercise-level header button.
  ///
  /// Reference format examples:
  /// - Both OFF: "Rest Timer: OFF"
  /// - Normal only: "Rest Timer: 1min 30s"
  /// - Warm-up only: "Rest Timer: (45s)"
  /// - Both active: "Rest Timer: 1min 30s (45s)"
  static String formatSummary({
    required int? normalSeconds,
    required int? warmUpSeconds,
  }) {
    if (normalSeconds == null && warmUpSeconds == null) {
      return 'Rest Timer: OFF';
    }
    if (normalSeconds != null && warmUpSeconds == null) {
      return 'Rest Timer: ${formatSeconds(normalSeconds)}';
    }
    if (normalSeconds == null && warmUpSeconds != null) {
      return 'Rest Timer: (${formatSeconds(warmUpSeconds)})';
    }
    return 'Rest Timer: ${formatSeconds(normalSeconds!)} (${formatSeconds(warmUpSeconds!)})';
  }

  /// Formats full accessibility semantics distinguishing duration categories.
  ///
  /// Examples:
  /// - Both OFF: "Rest Timer: OFF"
  /// - Normal only: "Rest Timer: Normal set 1min 30s, Warm-up set OFF"
  /// - Warm-up only: "Rest Timer: Normal set OFF, Warm-up set 45s"
  /// - Both: "Rest Timer: Normal set 1min 30s, Warm-up set 45s"
  static String formatSemantics({
    required int? normalSeconds,
    required int? warmUpSeconds,
  }) {
    if (normalSeconds == null && warmUpSeconds == null) {
      return 'Rest Timer: OFF';
    }
    final normalStr =
        normalSeconds == null ? 'OFF' : formatSeconds(normalSeconds);
    final warmUpStr =
        warmUpSeconds == null ? 'OFF' : formatSeconds(warmUpSeconds);
    return 'Rest Timer: Normal set $normalStr, Warm-up set $warmUpStr';
  }
}
