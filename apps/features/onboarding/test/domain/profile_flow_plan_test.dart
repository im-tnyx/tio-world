import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

void main() {
  const flow = ProfileFlowPlan();

  test('keeps the canonical profile order exact and typed', () {
    expect(ProfileFlowPlan.orderedSteps, const [
      ProfileStepId.name,
      ProfileStepId.gender,
      ProfileStepId.goal,
      ProfileStepId.age,
      ProfileStepId.height,
      ProfileStepId.currentWeight,
      ProfileStepId.targetWeight,
      ProfileStepId.activity,
      ProfileStepId.healthConditions,
    ]);
  });

  test('resolves deterministic next and previous boundaries', () {
    expect(flow.previous(ProfileStepId.name), isNull);
    expect(flow.next(ProfileStepId.name), ProfileStepId.gender);
    expect(flow.previous(ProfileStepId.gender), ProfileStepId.name);
    expect(flow.next(ProfileStepId.activity), ProfileStepId.healthConditions);
    expect(flow.next(ProfileStepId.healthConditions), isNull);
  });
}
