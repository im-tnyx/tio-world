import '../models/models.dart';

class OnboardingCompletionValidator {
  const OnboardingCompletionValidator({
    this.hasDurableOwnerPersistence = false,
    this.backendUserReady = false,
  });

  final bool hasDurableOwnerPersistence;
  final bool backendUserReady;

  static const _unsupportedSections = <OnboardingSectionId>{};

  OnboardingCompletionEligibility evaluate({
    required OnboardingDraft draft,
    required OnboardingFlowPlan flowPlan,
  }) {
    final selectedMode = draft.selectedMode;
    if (selectedMode == null) {
      return const OnboardingCompletionEligibility(
        isEligible: false,
        message: 'Choose an App Mode before finishing setup.',
      );
    }

    if (draft.status == OnboardingStatus.completed) {
      return OnboardingCompletionEligibility.eligible;
    }

    final blockingSteps = flowPlan.steps
        .where(
          (step) => step.isRequired && _unsupportedSections.contains(step.section),
        )
        .toList(growable: false);

    if (blockingSteps.isNotEmpty) {
      return OnboardingCompletionEligibility(
        isEligible: false,
        message: 'Finish stays disabled until the remaining required setup '
            'sections move from compatibility previews to real owner-owned '
            'implementations.',
        blockingSteps: blockingSteps,
      );
    }

    if (!hasDurableOwnerPersistence) {
      return const OnboardingCompletionEligibility(
        isEligible: false,
        message: 'Finish stays disabled until durable owner persistence writes '
            'setup answers to owner-backed repositories upon completion.',
      );
    }

    if (!backendUserReady) {
      return const OnboardingCompletionEligibility(
        isEligible: false,
        message: 'Sign in required to finish setup',
      );
    }

    return OnboardingCompletionEligibility.eligible;
  }
}
