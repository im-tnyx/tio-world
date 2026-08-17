import 'account_setup_step_id.dart';

class AccountSetupFlowPlan {
  AccountSetupFlowPlan({required List<AccountSetupStepId> steps})
      : steps = List<AccountSetupStepId>.unmodifiable(steps);

  final List<AccountSetupStepId> steps;

  bool get isEmpty => steps.isEmpty;
  bool get isNotEmpty => steps.isNotEmpty;

  bool contains(AccountSetupStepId step) => steps.contains(step);

  int indexOf(AccountSetupStepId step) => steps.indexOf(step);
}
