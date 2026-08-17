import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/app_mode/app_mode.dart';
import 'package:tio_app/app/onboarding/onboarding.dart';
import 'package:tio_app/app/session/session.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_profile/profile.dart';
import 'package:tio_shared/shared.dart';

void main() {
  test('incomplete account without username requires Account Setup', () async {
    final controller = await _buildController(
      completionState: RemoteOnboardingCompletionState.incomplete,
      accountState: const AccountSetupAccountState(),
    );

    await controller.refresh();

    expect(
      controller.state,
      const AppSessionBootstrapRequiresAccountSetup(userId: 'user-a'),
    );
  });

  test('username chosen but Account Setup marker missing resumes Account Setup',
      () async {
    final controller = await _buildController(
      completionState: RemoteOnboardingCompletionState.incomplete,
      accountState: const AccountSetupAccountState(username: 'tio.user'),
    );

    await controller.refresh();

    expect(
      controller.state,
      const AppSessionBootstrapRequiresAccountSetup(userId: 'user-a'),
    );
  });

  test('completed Account Setup continues to product onboarding', () async {
    final controller = await _buildController(
      completionState: RemoteOnboardingCompletionState.incomplete,
      accountState: const AccountSetupAccountState(
        username: 'tio.user',
        isCompleted: true,
      ),
    );

    await controller.refresh();

    expect(
      controller.state,
      const AppSessionBootstrapRequiresOnboarding(userId: 'user-a'),
    );
  });

  test('completed legacy account bypasses new Account Setup marker', () async {
    final controller = await _buildController(
      completionState: RemoteOnboardingCompletionState.completed,
      accountState: const AccountSetupAccountState(),
    );

    await controller.refresh();

    expect(
      controller.state,
      const AppSessionBootstrapReady(userId: 'user-a'),
    );
  });
}

Future<AppSessionBootstrapController> _buildController({
  required RemoteOnboardingCompletionState completionState,
  required AccountSetupAccountState accountState,
}) async {
  final modeController = AppModeController(_FakeAppModePreference());
  await modeController.load();
  final statusController = OnboardingStatusController(
    repository: _FakeOnboardingStatusRepository(),
    appModeController: modeController,
  );

  return AppSessionBootstrapController(
    authSessionRepository: _FakeAuthSessionRepository(),
    onboardingCompletionRepository:
        _FakeOnboardingCompletionRepository(completionState),
    onboardingStatusController: statusController,
    accountSetupRepository: _FakeAccountSetupRepository(accountState),
  );
}

class _FakeAuthSessionRepository implements AuthSessionRepository {
  final AuthSessionState _state = const AuthSessionAuthenticated(
    AuthSession(userId: 'user-a'),
  );

  @override
  Future<AuthSessionState> get currentSessionState async => _state;

  @override
  Stream<AuthSessionState> get sessionState => Stream.value(_state);

  @override
  Future<void> signOut() async {}
}

class _FakeOnboardingCompletionRepository
    implements OnboardingCompletionRepository {
  const _FakeOnboardingCompletionRepository(this.state);

  final RemoteOnboardingCompletionState state;

  @override
  Future<RemoteOnboardingCompletionState> readCurrent() async => state;

  @override
  Future<void> markCurrentCompleted() async {}
}

class _FakeAccountSetupRepository implements AccountSetupRepository {
  const _FakeAccountSetupRepository(this.state);

  final AccountSetupAccountState state;

  @override
  Future<AccountSetupAccountState> readAccountSetupState() async => state;

  @override
  Future<void> completeAccountSetup({String? mobile}) async {}
}

class _FakeAppModePreference implements AppModePreference {
  AppMode? _mode;

  @override
  Future<void> clear() async => _mode = null;

  @override
  Future<AppMode?> read() async => _mode;

  @override
  Future<void> write(AppMode mode) async => _mode = mode;
}

class _FakeOnboardingStatusRepository implements OnboardingStatusRepository {
  OnboardingStatus? status;
  bool hasStoredContractVersion = false;

  @override
  Future<void> clear() async {
    status = null;
    hasStoredContractVersion = false;
  }

  @override
  Future<void> ensureInitialized() async {
    hasStoredContractVersion = true;
  }

  @override
  Future<OnboardingStatusSnapshot> read() async {
    return OnboardingStatusSnapshot(
      status: status,
      hasStoredContractVersion: hasStoredContractVersion,
    );
  }

  @override
  Future<void> write(OnboardingStatus next) async {
    status = next;
    hasStoredContractVersion = true;
  }
}
