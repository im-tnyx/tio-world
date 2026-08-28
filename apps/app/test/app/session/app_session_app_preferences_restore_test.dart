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

  test('completed Ready session enables canonical-first Settings writes',
      () async {
    final fixture = await _Fixture.create(
      localMode: AppMode.workout,
      remotePreferences: AppPreferencesState.present(
        appMode: AppMode.workout,
        activeTabs: AppMode.workout.guidedDestinations,
      ),
    );

    await fixture.bootstrap.refresh();
    await fixture.modeController.select(AppMode.nutrition);

    expect(
      fixture.bootstrap.state,
      const AppSessionBootstrapReady(userId: 'user-a'),
    );
    expect(fixture.appPreferencesRepository.updates, hasLength(1));
    expect(
      fixture.appPreferencesRepository.updates.single.appMode,
      AppMode.nutrition,
    );
    expect(
      fixture.appPreferencesRepository.updates.single.activeTabs,
      AppMode.nutrition.guidedDestinations,
    );
    expect(fixture.modeController.selectedMode, AppMode.nutrition);
  });

  test('incomplete onboarding keeps App Mode selection local-only', () async {
    final fixture = await _Fixture.create(
      localMode: AppMode.workout,
      remoteCompletionState: RemoteOnboardingCompletionState.incomplete,
    );

    await fixture.bootstrap.refresh();
    await fixture.modeController.select(AppMode.nutrition);

    expect(
      fixture.bootstrap.state,
      const AppSessionBootstrapRequiresOnboarding(userId: 'user-a'),
    );
    expect(fixture.appPreferencesRepository.updates, isEmpty);
    expect(fixture.localPreference.storedMode, AppMode.nutrition);
  });

  test('sign out disables canonical writes before later local staging', () async {
    final fixture = await _Fixture.create(
      remotePreferences: AppPreferencesState.present(
        appMode: AppMode.workout,
        activeTabs: AppMode.workout.guidedDestinations,
      ),
    );

    await fixture.bootstrap.refresh();
    fixture.authRepository.state = const AuthSessionUnauthenticated();
    await fixture.bootstrap.refresh();
    await fixture.modeController.select(AppMode.nutrition);

    expect(
      fixture.bootstrap.state,
      const AppSessionBootstrapUnauthenticated(),
    );
    expect(fixture.appPreferencesRepository.updates, isEmpty);
    expect(fixture.localPreference.storedMode, AppMode.nutrition);
  });

  test('successful onboarding Ready publication enables later canonical writes',
      () async {
    final fixture = await _Fixture.create(
      localMode: AppMode.workout,
      remoteCompletionState: RemoteOnboardingCompletionState.incomplete,
    );

    await fixture.bootstrap.refresh();
    fixture.bootstrap.markReadyAfterOnboardingCompletion('user-a');
    await fixture.modeController.select(AppMode.hybrid);

    expect(
      fixture.bootstrap.state,
      const AppSessionBootstrapReady(userId: 'user-a'),
    );
    expect(fixture.appPreferencesRepository.updates, hasLength(1));
    expect(
      fixture.appPreferencesRepository.updates.single.appMode,
      AppMode.hybrid,
    );
    expect(
      fixture.appPreferencesRepository.updates.single.activeTabs,
      AppMode.hybrid.guidedDestinations,
    );
  });
}

class _Fixture {
  _Fixture({
    required this.bootstrap,
    required this.modeController,
    required this.localPreference,
    required this.appPreferencesRepository,
    required this.authRepository,
  });

  final AppSessionBootstrapController bootstrap;
  final AppModeController modeController;
  final _FakeAppModePreference localPreference;
  final _FakeAppPreferencesRepository appPreferencesRepository;
  final _FakeAuthSessionRepository authRepository;

  static Future<_Fixture> create({
    AppMode? localMode,
    AppPreferencesState remotePreferences = const AppPreferencesState.missing(),
    Object? appPreferencesError,
    RemoteOnboardingCompletionState remoteCompletionState =
        RemoteOnboardingCompletionState.completed,
  }) async {
    final localPreference = _FakeAppModePreference(initialMode: localMode);
    final modeController = AppModeController(localPreference);
    await modeController.load();

    final statusController = OnboardingStatusController(
      repository: _FakeOnboardingStatusRepository(),
      appModeController: modeController,
    );
    final appPreferencesRepository = _FakeAppPreferencesRepository(
      state: remotePreferences,
      error: appPreferencesError,
    );
    final authRepository = _FakeAuthSessionRepository();

    final bootstrap = AppSessionBootstrapController(
      authSessionRepository: authRepository,
      onboardingCompletionRepository:
          _CompletionRepository(remoteCompletionState),
      onboardingStatusController: statusController,
      appPreferencesRepository: appPreferencesRepository,
      appModeController: modeController,
    );

    return _Fixture(
      bootstrap: bootstrap,
      modeController: modeController,
      localPreference: localPreference,
      appPreferencesRepository: appPreferencesRepository,
      authRepository: authRepository,
    );
  }
}

class _FakeAuthSessionRepository implements AuthSessionRepository {
  AuthSessionState state = const AuthSessionAuthenticated(
    AuthSession(userId: 'user-a'),
  );

  @override
  Stream<AuthSessionState> get sessionState => Stream.value(state);

  @override
  Future<AuthSessionState> get currentSessionState async => state;

  @override
  Future<void> signOut() async {
    state = const AuthSessionUnauthenticated();
  }
}

class _CompletionRepository implements OnboardingCompletionRepository {
  _CompletionRepository(this.state);

  final RemoteOnboardingCompletionState state;

  @override
  Future<RemoteOnboardingCompletionState> readCurrent() async => state;

  @override
  Future<void> markCurrentCompleted() async {}
}

class _FakeAppPreferencesRepository implements AppPreferencesRepository {
  _FakeAppPreferencesRepository({required this.state, this.error});

  final AppPreferencesState state;
  final Object? error;
  final List<AppPreferencesUpdate> updates = [];

  @override
  Future<AppPreferencesState> read() async {
    if (error case final value?) throw value;
    return state;
  }

  @override
  Future<void> upsert(AppPreferencesUpdate preferences) async {
    updates.add(preferences);
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
