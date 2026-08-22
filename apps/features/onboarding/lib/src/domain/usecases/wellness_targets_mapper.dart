import 'package:tio_feature_progress/progress.dart' as wellness_owner;

import '../models/models.dart';

/// Maps onboarding Wellness compatibility fields into the canonical Wellness
/// owner contract.
///
/// `TargetsOnboardingDraft` remains the serialized compatibility container for
/// O4C. Durable ownership is nevertheless `WellnessTargetsRepository`.
class WellnessTargetsMapper {
  const WellnessTargetsMapper();

  wellness_owner.WellnessTargetsData map(TargetsOnboardingDraft draft) {
    return wellness_owner.WellnessTargetsData(
      dailySteps: draft.dailySteps,
      waterMl: draft.waterMl,
      sleepTargetMinutes: draft.sleepTargetMinutes,
      bedTimeMinutes: draft.sleepTimeMinutes,
      wakeTimeMinutes: draft.wakeTimeMinutes,
    );
  }
}
