import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';

/// Configured rest duration preset for an Exercise entry in Routine Create/Edit.
///
/// Active duration presets are positive seconds (in 5-second steps up to 10 minutes).
/// A null, zero, or negative value represents Rest Timer OFF.
///
/// - Both OFF (null/non-positive): Rest Timer is OFF.
/// - Normal present, Warm-up OFF: Warm-up sets fallback to Normal duration.
/// - Normal OFF, Warm-up present: Warm-up sets use Warm-up duration; non-Warm-up sets are OFF.
/// - Both present: Warm-up sets use Warm-up duration; non-Warm-up sets use Normal duration.
///
/// Failure and Drop sets inherit the Normal preset (they do not have separate presets).
@immutable
final class RoutineRestTimerPreset {
  const RoutineRestTimerPreset({
    int? normalRestSeconds,
    int? warmUpRestSeconds,
  })  : normalRestSeconds =
            (normalRestSeconds != null && normalRestSeconds > 0)
                ? normalRestSeconds
                : null,
        warmUpRestSeconds =
            (warmUpRestSeconds != null && warmUpRestSeconds > 0)
                ? warmUpRestSeconds
                : null;

  final int? normalRestSeconds;
  final int? warmUpRestSeconds;

  /// Infers a [RoutineRestTimerPreset] from persisted or draft [SetPrescription] items.
  ///
  /// - Non-Warm-up sets (Normal, Failure, Drop) map to [normalRestSeconds].
  /// - Warm-up sets map to [warmUpRestSeconds].
  /// - If Warm-up rest matches Normal rest, [warmUpRestSeconds] remains null to
  ///   preserve the approved fallback behavior and concise summary formatting.
  factory RoutineRestTimerPreset.fromPrescriptions(Iterable<SetPrescription> prescriptions) {
    if (prescriptions.isEmpty) return const RoutineRestTimerPreset();

    int? normalRest;
    int? warmUpRest;
    bool hasNormal = false;
    bool hasWarmUp = false;
    bool normalMixed = false;
    bool warmUpMixed = false;

    for (final p in prescriptions) {
      final pRest = (p.restSeconds != null && p.restSeconds! > 0) ? p.restSeconds : null;
      if (p.setType == RoutineSetType.warmUp) {
        if (!hasWarmUp) {
          warmUpRest = pRest;
          hasWarmUp = true;
        } else if (warmUpRest != pRest) {
          warmUpMixed = true;
        }
      } else {
        if (!hasNormal) {
          normalRest = pRest;
          hasNormal = true;
        } else if (normalRest != pRest) {
          normalMixed = true;
        }
      }
    }

    if (normalMixed || warmUpMixed || (normalRest == null && warmUpRest == null)) {
      return const RoutineRestTimerPreset();
    }

    if (!hasNormal && hasWarmUp) {
      return RoutineRestTimerPreset(
        normalRestSeconds: null,
        warmUpRestSeconds: warmUpRest,
      );
    }

    if (hasNormal && !hasWarmUp) {
      return RoutineRestTimerPreset(
        normalRestSeconds: normalRest,
        warmUpRestSeconds: null,
      );
    }

    if (warmUpRest == normalRest) {
      return RoutineRestTimerPreset(
        normalRestSeconds: normalRest,
        warmUpRestSeconds: null,
      );
    }

    return RoutineRestTimerPreset(
      normalRestSeconds: normalRest,
      warmUpRestSeconds: warmUpRest,
    );
  }

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

  /// Formats wheel duration item:
  /// - index 0 -> "Off"
  /// - index 1 (5s) -> "5s"
  /// - index 12 (60s) -> "1m 0s"
  /// - index 18 (90s) -> "1m 30s"
  /// - index 60 (300s) -> "5m 0s"
  static String formatWheelItem(int index, {int stepSeconds = 5}) {
    if (index <= 0) return 'Off';
    final seconds = index * stepSeconds;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes == 0) {
      return '${remainingSeconds}s';
    }
    return '${minutes}m ${remainingSeconds}s';
  }

  /// Formats the summary text shown on the Exercise-level header button.
  ///
  /// Reference format examples:
  /// - Both OFF: "Rest: OFF"
  /// - Normal only: "Rest: 1min 30s"
  /// - Warm-up only: "Rest: (45s)"
  /// - Both active: "Rest: 1min 30s (45s)"
  static String formatSummary({
    required int? normalSeconds,
    required int? warmUpSeconds,
  }) {
    if (normalSeconds == null && warmUpSeconds == null) {
      return 'Rest: OFF';
    }
    if (normalSeconds != null && warmUpSeconds == null) {
      return 'Rest: ${formatSeconds(normalSeconds)}';
    }
    if (normalSeconds == null && warmUpSeconds != null) {
      return 'Rest: (${formatSeconds(warmUpSeconds)})';
    }
    return 'Rest: ${formatSeconds(normalSeconds!)} (${formatSeconds(warmUpSeconds!)})';
  }

  /// Formats full accessibility semantics distinguishing duration categories.
  ///
  /// Examples:
  /// - Both OFF: "Rest: OFF"
  /// - Normal only: "Rest: Normal set 1min 30s, Warm-up set OFF"
  /// - Warm-up only: "Rest: Normal set OFF, Warm-up set 45s"
  /// - Both: "Rest: Normal set 1min 30s, Warm-up set 45s"
  static String formatSemantics({
    required int? normalSeconds,
    required int? warmUpSeconds,
  }) {
    if (normalSeconds == null && warmUpSeconds == null) {
      return 'Rest: OFF';
    }
    final normalStr =
        normalSeconds == null ? 'OFF' : formatSeconds(normalSeconds);
    final warmUpStr =
        warmUpSeconds == null ? 'OFF' : formatSeconds(warmUpSeconds);
    return 'Rest: Normal set $normalStr, Warm-up set $warmUpStr';
  }
}
