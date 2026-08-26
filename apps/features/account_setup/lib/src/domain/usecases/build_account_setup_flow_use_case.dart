import '../models/account_setup_flow_plan.dart';
import '../models/account_setup_step_id.dart';

class BuildAccountSetupFlowUseCase {
  const BuildAccountSetupFlowUseCase();

  AccountSetupFlowPlan call({
    required bool hasUsername,
    required bool accountSetupCompleted,
    bool hasTrustedEmailIdentity = false,
    required bool hasTrustedPhoneIdentity,
  }) {
    final steps = <AccountSetupStepId>[];

    if (!hasUsername) {
      steps.add(AccountSetupStepId.username);
    }

    if (!accountSetupCompleted) {
      if (hasTrustedEmailIdentity && hasTrustedPhoneIdentity) {
        // Both complementary contacts are already trusted by Auth.
      } else if (hasTrustedPhoneIdentity) {
        steps.add(AccountSetupStepId.email);
      } else {
        // Trusted Email accounts need optional Mobile. The same Mobile fallback
        // is retained for compatibility if trusted Auth evidence is missing.
        steps.add(AccountSetupStepId.mobile);
      }
    }

    return AccountSetupFlowPlan(steps: steps);
  }

  AccountSetupStepId reconcileCurrentStep({
    required AccountSetupStepId currentStep,
    required AccountSetupFlowPlan previousPlan,
    required AccountSetupFlowPlan nextPlan,
  }) {
    if (nextPlan.contains(currentStep)) return currentStep;

    final previousIndex = previousPlan.indexOf(currentStep);
    for (var index = previousIndex - 1; index >= 0; index--) {
      final candidate = previousPlan.steps[index];
      if (nextPlan.contains(candidate)) return candidate;
    }

    return nextPlan.steps.first;
  }
}
