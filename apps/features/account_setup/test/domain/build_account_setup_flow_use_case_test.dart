import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_account_setup/account_setup.dart';

void main() {
  const buildFlow = BuildAccountSetupFlowUseCase();

  test('fresh email/google account requires username then optional mobile', () {
    final plan = buildFlow(
      hasUsername: false,
      accountSetupCompleted: false,
      hasTrustedPhoneIdentity: false,
    );

    expect(
      plan.steps,
      const [AccountSetupStepId.username, AccountSetupStepId.mobile],
    );
  });

  test('resume after username continues at mobile', () {
    final plan = buildFlow(
      hasUsername: true,
      accountSetupCompleted: false,
      hasTrustedPhoneIdentity: false,
    );

    expect(plan.steps, const [AccountSetupStepId.mobile]);
  });

  test('trusted phone identity skips mobile collection', () {
    final plan = buildFlow(
      hasUsername: false,
      accountSetupCompleted: false,
      hasTrustedPhoneIdentity: true,
    );

    expect(plan.steps, const [AccountSetupStepId.username]);
  });

  test('completed account with username has no account-setup steps', () {
    final plan = buildFlow(
      hasUsername: true,
      accountSetupCompleted: true,
      hasTrustedPhoneIdentity: false,
    );

    expect(plan.steps, isEmpty);
  });

  test('username remains required even if completion marker is inconsistent', () {
    final plan = buildFlow(
      hasUsername: false,
      accountSetupCompleted: true,
      hasTrustedPhoneIdentity: false,
    );

    expect(plan.steps, const [AccountSetupStepId.username]);
  });
}
