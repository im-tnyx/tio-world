import '../models/account_setup_flow_plan.dart';
import '../models/account_setup_step_id.dart';

class BuildAccountSetupFlowUseCase {
  const BuildAccountSetupFlowUseCase();

  AccountSetupFlowPlan call({
    required bool hasUsername,
    required bool accountSetupCompleted,
    bool? hasTrustedEmailIdentity,
    required bool hasTrustedPhoneIdentity,
  }) {
    final steps = <AccountSetupStepId>[];

    if (!hasUsername) {
      steps.add(AccountSetupStepId.username);
    }

    if (!accountSetupCompleted) {
      // Legacy callers predate the complementary Email step and only supplied
      // trusted Phone. Preserve their old planning contract when Email evidence
      // is omitted. Production app composition now supplies Email trust
      // explicitly through AccountSetupAuthContactBridge.
      final hasTrustedEmail =
          hasTrustedEmailIdentity ?? hasTrustedPhoneIdentity;

      if (hasTrustedEmail && hasTrustedPhoneIdentity) {
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
