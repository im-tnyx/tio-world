import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/app_mode/app_mode.dart';
import 'package:tio_app/app/onboarding/onboarding.dart';
import 'package:tio_app/app/session/session.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('O1F durable App Mode integrated acceptance', () {
    test(
        'onboarding completion survives cleared, stale, Settings-changed, and fresh-device restore',
        () async {
      final account = _FakeCanonicalAccountStore();
      final firstDevicePreference = _FakeAppModePreference();
      final firstDeviceStatus = _FakeOnboardingStatusRepository();

      final completeOnboarding = CompleteOnboardingUseCase(
        confirmedModePreference: firstDevicePreference,
        appPreferencesRepository: account,
        statusRepository: firstDeviceStatus,
        completionRepository: account,
        validator: _validator,
      );

      await completeOnboarding(
        draft: OnboardingDraft(selectedMode: AppMode.workout),
        flowPlan: _workoutFlowPlan,
      );

      expect(account.completionState, RemoteOnboardingCompletionState.completed);
      expect(account.preferencesState.appMode, AppMode.workout);
      expect(
        account.preferencesState.activeTabs,
        AppMode.workout.guidedDestinations,
      );
      expect(firstDevicePreference.storedMode, AppMode.workout);
      expect(firstDeviceStatus.status, OnboardingStatus.completed);

      final clearedDevice = await _DeviceFixture.create(account: account);
      addTearDown(clearedDevice.bootstrap.dispose);
      expect(clearedDevice.modeController.selectedMode, isNull);

      await clearedDevice.bootstrap.refresh();

      expect(
        clearedDevice.bootstrap.state,
        const AppSessionBootstrapReady(userId: 'user-a'),
      );
      expect(clearedDevice.modeController.selectedMode, AppMode.workout);
      expect(
        clearedDevice.modeController.activeDestinations,
        AppMode.workout.guidedDestinations,
      );
      expect(clearedDevice.localPreference.storedMode, AppMode.workout);

      final staleDevice = await _DeviceFixture.create(
        account: account,
        localMode: AppMode.nutrition,
      );
      addTearDown(staleDevice.bootstrap.dispose);
      expect(staleDevice.modeController.selectedMode, AppMode.nutrition);

      await staleDevice.bootstrap.refresh();

      expect(staleDevice.modeController.selectedMode, AppMode.workout);
      expect(staleDevice.localPreference.storedMode, AppMode.workout);

      final hiddenBefore = account.hiddenDomainSnapshot;
      await clearedDevice.modeController.select(AppMode.hybrid);

      expect(account.preferencesState.appMode, AppMode.hybrid);
      expect(
        account.preferencesState.activeTabs,
        AppMode.hybrid.guidedDestinations,
      );
      expect(clearedDevice.modeController.selectedMode, AppMode.hybrid);
      expect(clearedDevice.localPreference.storedMode, AppMode.hybrid);
      expect(account.hiddenDomainSnapshot, hiddenBefore);

      final laterFreshDevice = await _DeviceFixture.create(account: account);
      addTearDown(laterFreshDevice.bootstrap.dispose);
      await laterFreshDevice.bootstrap.refresh();

      expect(laterFreshDevice.modeController.selectedMode, AppMode.hybrid);
      expect(
        laterFreshDevice.modeController.activeDestinations,
        AppMode.hybrid.guidedDestinations,
      );
      expect(laterFreshDevice.localPreference.storedMode, AppMode.hybrid);
    });

    test('exact canonical tab order reaches shell and route policy unchanged',
        () async {
      final account = _FakeCanonicalAccountStore(
        completionState: RemoteOnboardingCompletionState.completed,
        preferencesState: AppPreferencesState.present(
          appMode: AppMode.hybrid,
          activeTabs: const [
            AppDestination.progress,
            AppDestination.home,
            AppDestination.workout,
          ],
        ),
      );
      final device = await _DeviceFixture.create(
        account: account,
        localMode: AppMode.nutrition,
      );
      addTearDown(device.bootstrap.dispose);

      await device.bootstrap.refresh();

      const restored = [
        AppDestination.progress,
        AppDestination.home,
        AppDestination.workout,
      ];
      expect(device.modeController.selectedMode, AppMode.hybrid);
      expect(device.modeController.activeDestinations, restored);
      expect(
        shellTabsForDestinations(restored),
        const [ShellTab.progress, ShellTab.home, ShellTab.workout],
      );
      expect(
        appModeRedirect(
          path: FeatureRoutes.workout.path,
          selectedMode: device.modeController.selectedMode,
          activeDestinations: device.modeController.activeDestinations,
          onboardingStatus: OnboardingStatus.completed,
        ),
        isNull,
      );
      expect(
        appModeRedirect(
          path: FeatureRoutes.nutrition.path,
          selectedMode: device.modeController.selectedMode,
          activeDestinations: device.modeController.activeDestinations,
          onboardingStatus: OnboardingStatus.completed,
        ),
        FeatureRoutes.progress.path,
      );
    });

    test('mode-only and missing legacy canonical states recover without Hybrid inference',
        () async {
      final modeOnlyAccount = _FakeCanonicalAccountStore(
        completionState: RemoteOnboardingCompletionState.completed,
        preferencesState: AppPreferencesState.present(
          appMode: AppMode.nutrition,
          activeTabs: null,
        ),
      );
      final modeOnlyDevice = await _DeviceFixture.create(
        account: modeOnlyAccount,
        localMode: AppMode.workout,
      );
      addTearDown(modeOnlyDevice.bootstrap.dispose);

      await modeOnlyDevice.bootstrap.refresh();

      expect(modeOnlyDevice.modeController.selectedMode, AppMode.nutrition);
      expect(
        modeOnlyDevice.modeController.activeDestinations,
        AppMode.nutrition.guidedDestinations,
      );

      final missingAccount = _FakeCanonicalAccountStore(
        completionState: RemoteOnboardingCompletionState.completed,
      );
      final missingDevice = await _DeviceFixture.create(
        account: missingAccount,
        localMode: AppMode.hybrid,
      );
      addTearDown(missingDevice.bootstrap.dispose);

      await missingDevice.bootstrap.refresh();

      expect(
        missingDevice.bootstrap.state,
        const AppSessionBootstrapReady(userId: 'user-a'),
      );
      expect(missingDevice.modeController.selectedMode, isNull);
      expect(missingDevice.modeController.activeDestinations, isNull);
      expect(missingDevice.localPreference.storedMode, isNull);
      for (final tab in missingModeCompatibilityShellTabs) {
        expect(
          appModeRedirect(
            path: tab.route.path,
            selectedMode: missingDevice.modeController.selectedMode,
            activeDestinations: missingDevice.modeController.activeDestinations,
            onboardingStatus: OnboardingStatus.completed,
          ),
          isNull,
        );
      }
    });

    test('malformed canonical read keeps authenticated bootstrap out of Ready',
        () async {
      final account = _FakeCanonicalAccountStore(
        completionState: RemoteOnboardingCompletionState.completed,
        readError: const FormatException('duplicate canonical active_tabs'),
      );
      final device = await _DeviceFixture.create(
        account: account,
        localMode: AppMode.workout,
      );
      addTearDown(device.bootstrap.dispose);

      await device.bootstrap.refresh();

      expect(device.bootstrap.state, isA<AppSessionBootstrapFailure>());
      expect(device.modeController.selectedMode, AppMode.workout);
      expect(device.localPreference.storedMode, AppMode.workout);
    });

    test('Settings canonical failure preserves effective and hidden domain state',
        () async {
      final account = _FakeCanonicalAccountStore(
        completionState: RemoteOnboardingCompletionState.completed,
        preferencesState: AppPreferencesState.present(
          appMode: AppMode.workout,
          activeTabs: AppMode.workout.guidedDestinations,
        ),
      );
      final device = await _DeviceFixture.create(account: account);
      addTearDown(device.bootstrap.dispose);
      await device.bootstrap.refresh();

      final hiddenBefore = account.hiddenDomainSnapshot;
      account.writeError = StateError('canonical write failed');

      await expectLater(
        () => device.modeController.select(AppMode.nutrition),
        throwsStateError,
      );

      expect(device.modeController.selectedMode, AppMode.workout);
      expect(
        device.modeController.activeDestinations,
        AppMode.workout.guidedDestinations,
      );
      expect(device.localPreference.storedMode, AppMode.workout);
      expect(account.preferencesState.appMode, AppMode.workout);
      expect(account.hiddenDomainSnapshot, hiddenBefore);
    });
  });
}

const _validator = OnboardingCompletionValidator(
  hasDurableOwnerPersistence: true,
  backendUserReady: true,
);

final _workoutFlowPlan = const BuildOnboardingFlowUseCase()(
  entryPath: OnboardingEntryPath.firstRun,
  mode: AppMode.workout,
  workoutIntroChoice: null,
);

class _DeviceFixture {
  _DeviceFixture({
    required this.bootstrap,
    required this.modeController,
    required this.localPreference,
  });

  final AppSessionBootstrapController bootstrap;
  final AppModeController modeController;
  final _FakeAppModePreference localPreference;

  static Future<_DeviceFixture> create({
    required _FakeCanonicalAccountStore account,
    AppMode? localMode,
  }) async {
    final localPreference = _FakeAppModePreference(initialMode: localMode);
    final modeController = AppModeController(localPreference);
    await modeController.load();

    final statusController = OnboardingStatusController(
      repository: _FakeOnboardingStatusRepository(),
      appModeController: modeController,
    );
    final bootstrap = AppSessionBootstrapController(
      authSessionRepository: _FakeAuthSessionRepository(),
      onboardingCompletionRepository: account,
      onboardingStatusController: statusController,
      appPreferencesRepository: account,
      appModeController: modeController,
    );

    return _DeviceFixture(
      bootstrap: bootstrap,
      modeController: modeController,
      localPreference: localPreference,
    );
  }
}

class _FakeCanonicalAccountStore
    implements OnboardingCompletionRepository, AppPreferencesRepository {
  _FakeCanonicalAccountStore({
    this.completionState = RemoteOnboardingCompletionState.incomplete,
    this.preferencesState = const AppPreferencesState.missing(),
    this.readError,
    this.writeError,
  });

  RemoteOnboardingCompletionState completionState;
  AppPreferencesState preferencesState;
  Object? readError;
  Object? writeError;

  String bodyOwnerData = 'body-preserved';
  String nutritionOwnerData = 'nutrition-preserved';
  String workoutOwnerData = 'workout-preserved';

  List<String> get hiddenDomainSnapshot => List<String>.unmodifiable([
        bodyOwnerData,
        nutritionOwnerData,
        workoutOwnerData,
      ]);

  @override
  Future<RemoteOnboardingCompletionState> readCurrent() async => completionState;

  @override
  Future<void> markCurrentCompleted() async {
    completionState = RemoteOnboardingCompletionState.completed;
  }

  @override
  Future<AppPreferencesState> read() async {
    if (readError case final error?) throw error;
    return preferencesState;
  }

  @override
  Future<void> upsert(AppPreferencesUpdate preferences) async {
    if (writeError case final error?) throw error;
    preferencesState = AppPreferencesState.present(
      appMode: preferences.appMode,
      activeTabs: preferences.activeTabs,
    );
  }
}

class _FakeAppModePreference implements AppModePreference {
  _FakeAppModePreference({AppMode? initialMode}) : storedMode = initialMode;

  AppMode? storedMode;

  @override
  Future<void> clear() async => storedMode = null;

  @override
  Future<AppMode?> read() async => storedMode;

  @override
  Future<void> write(AppMode mode) async => storedMode = mode;
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
  Future<OnboardingStatusSnapshot> read() async => OnboardingStatusSnapshot(
        status: status,
        hasStoredContractVersion: hasStoredContractVersion,
      );

  @override
  Future<void> write(OnboardingStatus next) async {
    status = next;
    hasStoredContractVersion = true;
  }
}

class _FakeAuthSessionRepository implements AuthSessionRepository {
  static const _authenticated = AuthSessionAuthenticated(
    AuthSession(userId: 'user-a'),
  );

  @override
  Stream<AuthSessionState> get sessionState => Stream.value(_authenticated);

  @override
  Future<AuthSessionState> get currentSessionState async => _authenticated;

  @override
  Future<void> signOut() async {}
}
