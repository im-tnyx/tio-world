import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/src/domain/domain.dart';

void main() {
  const mapper = WellnessTargetsMapper();

  test('maps onboarding Wellness compatibility values losslessly', () {
    const draft = TargetsOnboardingDraft(
      dailySteps: 12345,
      sleepTargetMinutes: 465,
      sleepTimeMinutes: 1375,
      wakeTimeMinutes: 395,
      waterMl: 2875,
      goalPaceKgPerWeek: 0.5,
    );

    final result = mapper.map(draft);

    expect(result.dailySteps, 12345);
    expect(result.waterMl, 2875);
    expect(result.sleepTargetMinutes, 465);
    expect(result.bedTimeMinutes, 1375);
    expect(result.wakeTimeMinutes, 395);
  });

  test('does not leak Body-owned Goal Pace into Wellness owner', () {
    const draft = TargetsOnboardingDraft(
      dailySteps: 9000,
      sleepTargetMinutes: 480,
      sleepTimeMinutes: 1320,
      wakeTimeMinutes: 360,
      waterMl: 2500,
      goalPaceKgPerWeek: 0.75,
    );

    final result = mapper.map(draft);

    expect(result.dailySteps, 9000);
    expect(result.sleepTargetMinutes, 480);
    expect(result.waterMl, 2500);
  });
}
