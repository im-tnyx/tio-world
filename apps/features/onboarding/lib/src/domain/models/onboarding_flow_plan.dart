import 'package:tio_shared/shared.dart';

import 'onboarding_entry_path.dart';
import 'onboarding_step_definition.dart';
import 'onboarding_step_id.dart';

class OnboardingFlowPlan {
  OnboardingFlowPlan({
    required this.entryPath,
    required List<OnboardingStepDefinition> steps,
    this.mode,
  }) : steps = List.unmodifiable(steps) {
    if (steps.isEmpty) {
      throw ArgumentError.value(steps, 'steps', 'Flow plan cannot be empty.');
    }
  }

  final OnboardingEntryPath entryPath;
  final AppMode? mode;
  final List<OnboardingStepDefinition> steps;

  List<OnboardingStepId> get stepIds =>
      steps.map((definition) => definition.id).toList(growable: false);

  bool contains(OnboardingStepId stepId) =>
      steps.any((definition) => definition.id == stepId);

  int indexOf(OnboardingStepId stepId) =>
      steps.indexWhere((definition) => definition.id == stepId);

  OnboardingStepDefinition definitionFor(OnboardingStepId stepId) {
    return steps.firstWhere((definition) => definition.id == stepId);
  }
}
