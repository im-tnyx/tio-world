import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_account_setup/account_setup.dart';

void main() {
  const buildFlow = BuildAccountSetupFlowUseCase();

  test('trusted Email only plans optional Mobile', () {
    final plan = buildFlow(
      hasUsername: false,
      accountSetupCompleted: false,
      hasTrustedEmailIdentity: true,
      hasTrustedPhoneIdentity: false,
    );

    expect(
      plan.steps,
      const [AccountSetupStepId.username, AccountSetupStepId.mobile],
    );
  });

  test('trusted Phone only plans optional Email', () {
    final plan = buildFlow(
      hasUsername: false,
      accountSetupCompleted: false,
      hasTrustedEmailIdentity: false,
      hasTrustedPhoneIdentity: true,
    );

    expect(
      plan.steps,
      const [AccountSetupStepId.username, AccountSetupStepId.email],
    );
  });

  test('both trusted contacts need no complementary contact step', () {
    final plan = buildFlow(
      hasUsername: false,
      accountSetupCompleted: false,
      hasTrustedEmailIdentity: true,
      hasTrustedPhoneIdentity: true,
    );

    expect(plan.steps, const [AccountSetupStepId.username]);
  });

  test('missing trusted evidence keeps compatibility Mobile fallback', () {
    final plan = buildFlow(
      hasUsername: true,
      accountSetupCompleted: false,
      hasTrustedEmailIdentity: false,
      hasTrustedPhoneIdentity: false,
    );

    expect(plan.steps, const [AccountSetupStepId.mobile]);
  });

  test('explicit Account Setup completion suppresses contact collection', () {
    final plan = buildFlow(
      hasUsername: true,
      accountSetupCompleted: true,
      hasTrustedEmailIdentity: false,
      hasTrustedPhoneIdentity: true,
    );

    expect(plan.steps, isEmpty);
  });
}
