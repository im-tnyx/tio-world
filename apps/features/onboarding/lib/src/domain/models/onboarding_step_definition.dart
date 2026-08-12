import 'onboarding_step_id.dart';

enum OnboardingStepOwner {
  onboarding,
  profile,
  workout,
  nutrition,
  crossFeature,
}

class OnboardingStepDefinition {
  const OnboardingStepDefinition({
    required this.id,
    required this.owner,
    required this.progressTitle,
    this.isRequired = true,
  });

  final OnboardingStepId id;
  final OnboardingStepOwner owner;
  final String progressTitle;
  final bool isRequired;
}
