import 'target_step_id.dart';

/// In-memory draft for the Targets onboarding section.
///
/// All fields are pure Dart — no Flutter/material imports.
///
/// Storage conventions:
/// - [dailySteps]: Int steps/day. Default 10000.
/// - [sleepTargetMinutes]: Int minutes. Default 480 (8h).
/// - [sleepTimeMinutes]: Minutes since midnight for sleep time. Default 1320 (22:00).
/// - [wakeTimeMinutes]: Minutes since midnight for wake time. Default 360 (06:00).
/// - [waterMl]: Canonical Int ml. Default 2500.
/// - [goalPaceKgPerWeek]: Goal pace in kg/week (0.1..1.5). Default 0.5.
///
/// The `has*Value` flags preserve whether a Wellness value was actually present
/// in serialized compatibility data. A legacy snapshot may hydrate a UI default
/// for rendering without allowing that default to become fabricated canonical
/// persistence. Current/new drafts default to known values because these are the
/// active Product Onboarding starting values; DTO hydration can explicitly mark
/// missing historical values unknown.
///
/// Display-unit preference (L/ml/oz) is a presentation concern and
/// must not appear in this draft.
class TargetsOnboardingDraft {
  const TargetsOnboardingDraft({
    this.currentStepId = TargetStepId.bridge,
    this.dailySteps = 10000,
    this.sleepTargetMinutes = 480,
    this.sleepTimeMinutes = 1320,
    this.wakeTimeMinutes = 360,
    this.waterMl = 2500,
    this.goalPaceKgPerWeek = 0.5,
    this.hasDailyStepsValue = true,
    this.hasSleepTargetMinutesValue = true,
    this.hasSleepTimeMinutesValue = true,
    this.hasWakeTimeMinutesValue = true,
    this.hasWaterMlValue = true,
  });

  final TargetStepId currentStepId;

  /// Daily step target. Range: 2000–18000.
  final int dailySteps;

  /// Sleep duration in minutes. Range: 240–720 (4h–12h).
  /// Slider supports half-hour increments (step 30 min).
  final int sleepTargetMinutes;

  /// Bedtime as minutes since midnight. 0 = 00:00, 1320 = 22:00, 1380 = 23:00.
  final int sleepTimeMinutes;

  /// Wake time as minutes since midnight. 0 = 00:00, 360 = 06:00, 420 = 07:00.
  final int wakeTimeMinutes;

  /// Daily water target in millilitres. Range: 1000–8000. Default: 2500.
  final int waterMl;

  /// Goal pace in kg/week for weight loss or gain. Range: 0.1–1.5. Default 0.5.
  final double goalPaceKgPerWeek;

  /// Whether [dailySteps] came from an explicit/current draft value rather than
  /// a compatibility fallback for a missing historical field.
  final bool hasDailyStepsValue;

  /// Whether [sleepTargetMinutes] is known in the serialized/runtime draft.
  final bool hasSleepTargetMinutesValue;

  /// Whether [sleepTimeMinutes] is known in the serialized/runtime draft.
  final bool hasSleepTimeMinutesValue;

  /// Whether [wakeTimeMinutes] is known in the serialized/runtime draft.
  final bool hasWakeTimeMinutesValue;

  /// Whether [waterMl] is known in the serialized/runtime draft.
  final bool hasWaterMlValue;

  TargetsOnboardingDraft copyWith({
    TargetStepId? currentStepId,
    int? dailySteps,
    int? sleepTargetMinutes,
    int? sleepTimeMinutes,
    int? wakeTimeMinutes,
    int? waterMl,
    double? goalPaceKgPerWeek,
    bool? hasDailyStepsValue,
    bool? hasSleepTargetMinutesValue,
    bool? hasSleepTimeMinutesValue,
    bool? hasWakeTimeMinutesValue,
    bool? hasWaterMlValue,
  }) {
    return TargetsOnboardingDraft(
      currentStepId: currentStepId ?? this.currentStepId,
      dailySteps: dailySteps ?? this.dailySteps,
      sleepTargetMinutes: sleepTargetMinutes ?? this.sleepTargetMinutes,
      sleepTimeMinutes: sleepTimeMinutes ?? this.sleepTimeMinutes,
      wakeTimeMinutes: wakeTimeMinutes ?? this.wakeTimeMinutes,
      waterMl: waterMl ?? this.waterMl,
      goalPaceKgPerWeek: goalPaceKgPerWeek ?? this.goalPaceKgPerWeek,
      hasDailyStepsValue: hasDailyStepsValue ??
          (dailySteps != null ? true : this.hasDailyStepsValue),
      hasSleepTargetMinutesValue: hasSleepTargetMinutesValue ??
          (sleepTargetMinutes != null
              ? true
              : this.hasSleepTargetMinutesValue),
      hasSleepTimeMinutesValue: hasSleepTimeMinutesValue ??
          (sleepTimeMinutes != null ? true : this.hasSleepTimeMinutesValue),
      hasWakeTimeMinutesValue: hasWakeTimeMinutesValue ??
          (wakeTimeMinutes != null ? true : this.hasWakeTimeMinutesValue),
      hasWaterMlValue:
          hasWaterMlValue ?? (waterMl != null ? true : this.hasWaterMlValue),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TargetsOnboardingDraft &&
            currentStepId == other.currentStepId &&
            dailySteps == other.dailySteps &&
            sleepTargetMinutes == other.sleepTargetMinutes &&
            sleepTimeMinutes == other.sleepTimeMinutes &&
            wakeTimeMinutes == other.wakeTimeMinutes &&
            waterMl == other.waterMl &&
            (goalPaceKgPerWeek - other.goalPaceKgPerWeek).abs() < 0.001 &&
            hasDailyStepsValue == other.hasDailyStepsValue &&
            hasSleepTargetMinutesValue == other.hasSleepTargetMinutesValue &&
            hasSleepTimeMinutesValue == other.hasSleepTimeMinutesValue &&
            hasWakeTimeMinutesValue == other.hasWakeTimeMinutesValue &&
            hasWaterMlValue == other.hasWaterMlValue;
  }

  @override
  int get hashCode => Object.hash(
        currentStepId,
        dailySteps,
        sleepTargetMinutes,
        sleepTimeMinutes,
        wakeTimeMinutes,
        waterMl,
        goalPaceKgPerWeek,
        hasDailyStepsValue,
        hasSleepTargetMinutesValue,
        hasSleepTimeMinutesValue,
        hasWakeTimeMinutesValue,
        hasWaterMlValue,
      );
}
