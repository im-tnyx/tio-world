import '../models/account_setup_flow_plan.dart';
import '../models/account_setup_step_id.dart';

class BuildAccountSetupFlowUseCase {
  const BuildAccountSetupFlowUseCase();

  AccountSetupFlowPlan call({
    required bool hasUsername,
    required bool accountSetupCompleted,
    required bool hasTrustedPhoneIdentity,
  }) {
    final steps = <AccountSetupStepId>[];

    if (!hasUsername) {
      steps.add(AccountSetupStepId.username);
    }

    // Mobile is optional, but the step itself must be durably acknowledged for
    // non-phone-authenticated fresh accounts. A trusted authenticated phone
    // identity satisfies this account-level requirement without showing the
    // collection step.
    if (!accountSetupCompleted && !hasTrustedPhoneIdentity) {
      steps.add(AccountSetupStepId.mobile);
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
