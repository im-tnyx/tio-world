import 'onboarding_step_definition.dart';
import 'onboarding_step_id.dart';

class OnboardingCompletionEligibility {
  const OnboardingCompletionEligibility({
    required this.isEligible,
    this.message,
    this.blockingSteps = const <OnboardingStepDefinition>[],
  });

  final bool isEligible;
  final String? message;
  final List<OnboardingStepDefinition> blockingSteps;

  bool get hasBlockingSteps => blockingSteps.isNotEmpty;

  List<OnboardingStepId> get blockingStepIds =>
      blockingSteps.map((step) => step.id).toList(growable: false);

  static const eligible = OnboardingCompletionEligibility(isEligible: true);
}
