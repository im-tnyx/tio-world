import 'package:tio_feature_progress/progress.dart' as wellness_owner;

import '../models/models.dart';

/// Maps onboarding Wellness compatibility fields into the canonical Wellness
/// owner contract.
///
/// `TargetsOnboardingDraft` remains the serialized compatibility container.
/// Its `has*Value` provenance flags prevent legacy compatibility UI defaults
/// from becoming fabricated canonical Wellness values when historical fields
/// were absent.
class WellnessTargetsMapper {
  const WellnessTargetsMapper();

  wellness_owner.WellnessTargetsData map(TargetsOnboardingDraft draft) {
    return wellness_owner.WellnessTargetsData(
      dailySteps: draft.hasDailyStepsValue ? draft.dailySteps : null,
      waterMl: draft.hasWaterMlValue ? draft.waterMl : null,
      sleepTargetMinutes: draft.hasSleepTargetMinutesValue
          ? draft.sleepTargetMinutes
          : null,
      bedTimeMinutes:
          draft.hasSleepTimeMinutesValue ? draft.sleepTimeMinutes : null,
      wakeTimeMinutes:
          draft.hasWakeTimeMinutesValue ? draft.wakeTimeMinutes : null,
    );
  }
}
