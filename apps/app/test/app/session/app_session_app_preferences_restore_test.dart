import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/app_mode/app_mode.dart';
import 'package:tio_app/app/onboarding/onboarding.dart';
import 'package:tio_app/app/session/session.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  test('cleared local state restores canonical mode and exact tab order',
      () async {
    final fixture = await _Fixture.create(
      remotePreferences: AppPreferencesState.present(
        appMode: AppMode.nutrition,
        activeTabs: const [
          AppDestination.progress,
          AppDestination.home,
          AppDestination.nutrition,
        ],
      ),
    );

    await fixture.bootstrap.refresh();

    expect(
      fixture.bootstrap.state,
      const AppSessionBootstrapReady(userId: 'user-a'),
    );
    expect(fixture.modeController.selectedMode, AppMode.nutrition);
    expect(
      fixture.modeController.activeDestinations,
      const [
        AppDestination.progress,
        AppDestination.home,
        AppDestination.nutrition,
      ],
    );
    expect(fixture.localPreference.storedMode, AppMode.nutrition);
  });

  test('remote canonical state wins over a stale device-local mode', () async {
    final fixture = await _Fixture.create(
      localMode: AppMode.workout,
      remotePreferences: AppPreferencesState.present(
        appMode: AppMode.nutrition,
        activeTabs: const [
          AppDestination.home,
          AppDestination.nutrition,
          AppDestination.progress,
        ],
      ),
    );

    expect(fixture.modeController.selectedMode, AppMode.workout);

    await fixture.bootstrap.refresh();

    expect(fixture.modeController.selectedMode, AppMode.nutrition);
    expect(fixture.localPreference.storedMode, AppMode.nutrition);
  });

  test('app-mode-only canonical row derives current guided defaults', () async {
    final fixture = await _Fixture.create(
      remotePreferences: AppPreferencesState.present(
        appMode: AppMode.workout,
        activeTabs: null,
      ),
    );

    await fixture.bootstrap.refresh();

    expect(fixture.modeController.selectedMode, AppMode.workout);
    expect(
      fixture.modeController.activeDestinations,
      AppMode.workout.guidedDestinations,
    );
  });

  test('missing completed-account canonical row clears stale local mode',
      () async {
    final fixture = await _Fixture.create(
      localMode: AppMode.hybrid,
      remotePreferences: const AppPreferencesState.missing(),
    );

    await fixture.bootstrap.refresh();

    expect(
      fixture.bootstrap.state,
      const AppSessionBootstrapReady(userId: 'user-a'),
    );
    expect(fixture.modeController.selectedMode, isNull);
    expect(fixture.modeController.activeDestinations, isNull);
    expect(fixture.localPreference.storedMode, isNull);
  });

  test('present canonical row without app mode fails instead of inventing Hybrid',
      () async {
    final fixture = await _Fixture.create(
      localMode: AppMode.workout,
      remotePreferences: AppPreferencesState.present(
        appMode: null,
        activeTabs: const [AppDestination.home],
      ),
    );

    await fixture.bootstrap.refresh();

    expect(fixture.bootstrap.state, isA<AppSessionBootstrapFailure>());
    expect(fixture.modeController.selectedMode, AppMode.workout);
  });

  test('canonical repository failure keeps bootstrap out of Ready', () async {
    final fixture = await _Fixture.create(
      localMode: AppMode.hybrid,
      appPreferencesError: const FormatException('malformed canonical row'),
    );

    await fixture.bootstrap.refresh();

    expect(fixture.bootstrap.state, isA<AppSessionBootstrapFailure>());
    expect(fixture.modeController.selectedMode, AppMode.hybrid);
  });
}

class _Fixture {
  _Fixture({
    required this.bootstrap,
    required this.modeController,
    required this.localPreference,
  });

  final AppSessionBootstrapController bootstrap;
  final AppModeController modeController;
  final _FakeAppModePreference localPreference;

  static Future<_Fixture> create({
    AppMode? localMode,
    AppPreferencesState remotePreferences = const AppPreferencesState.missing(),
    Object? appPreferencesError,
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
      onboardingCompletionRepository: _CompletedRepository(),
      onboardingStatusController: statusController,
      appPreferencesRepository: _FakeAppPreferencesRepository(
        state: remotePreferences,
        error: appPreferencesError,
      ),
      appModeController: modeController,
    );

    return _Fixture(
      bootstrap: bootstrap,
      modeController: modeController,
      localPreference: localPreference,
    );
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

class _CompletedRepository implements OnboardingCompletionRepository {
  @override
  Future<RemoteOnboardingCompletionState> readCurrent() async =>
      RemoteOnboardingCompletionState.completed;

  @override
  Future<void> markCurrentCompleted() async {}
}

class _FakeAppPreferencesRepository implements AppPreferencesRepository {
  _FakeAppPreferencesRepository({required this.state, this.error});

  final AppPreferencesState state;
  final Object? error;

  @override
  Future<AppPreferencesState> read() async {
    if (error case final value?) throw value;
    return state;
  }

  @override
  Future<void> upsert(AppPreferencesUpdate preferences) async {}
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
