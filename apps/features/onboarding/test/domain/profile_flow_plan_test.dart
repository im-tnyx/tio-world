import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

void main() {
  const flow = ProfileFlowPlan();

  test('keeps the active common Profile order exact and typed', () {
    expect(ProfileFlowPlan.orderedSteps, const [
      ProfileStepId.name,
      ProfileStepId.gender,
      ProfileStepId.age,
      ProfileStepId.measurementUnits,
      ProfileStepId.height,
      ProfileStepId.activity,
      ProfileStepId.healthConditions,
    ]);
    expect(ProfileFlowPlan.orderedSteps, isNot(contains(ProfileStepId.goal)));
    expect(
      ProfileFlowPlan.orderedSteps,
      isNot(contains(ProfileStepId.currentWeight)),
    );
    expect(
      ProfileFlowPlan.orderedSteps,
      isNot(contains(ProfileStepId.targetWeight)),
    );
  });

  test('retains the pre-O3 mixed order only for legacy resume interpretation', () {
    expect(ProfileFlowPlan.legacyOrderedSteps, const [
      ProfileStepId.name,
      ProfileStepId.gender,
      ProfileStepId.goal,
      ProfileStepId.age,
      ProfileStepId.measurementUnits,
      ProfileStepId.height,
      ProfileStepId.currentWeight,
      ProfileStepId.targetWeight,
      ProfileStepId.activity,
      ProfileStepId.healthConditions,
    ]);
  });

  test('resolves deterministic next and previous common Profile boundaries', () {
    expect(flow.previous(ProfileStepId.name), isNull);
    expect(flow.next(ProfileStepId.name), ProfileStepId.gender);
    expect(flow.previous(ProfileStepId.gender), ProfileStepId.name);
    expect(flow.next(ProfileStepId.gender), ProfileStepId.age);
    expect(flow.next(ProfileStepId.age), ProfileStepId.measurementUnits);
    expect(flow.next(ProfileStepId.measurementUnits), ProfileStepId.height);
    expect(flow.next(ProfileStepId.height), ProfileStepId.activity);
    expect(flow.next(ProfileStepId.activity), ProfileStepId.healthConditions);
    expect(flow.next(ProfileStepId.healthConditions), isNull);
  });
}
