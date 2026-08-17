import 'onboarding_section_id.dart';
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
    required this.section,
    required this.owner,
    required this.progressTitle,
    this.isRequired = true,
  });

  final OnboardingStepId id;
  final OnboardingSectionId section;
  final OnboardingStepOwner owner;
  final String progressTitle;
  final bool isRequired;
}
