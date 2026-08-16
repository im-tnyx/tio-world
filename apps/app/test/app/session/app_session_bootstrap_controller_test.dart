import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/app_mode/app_mode.dart';
import 'package:tio_app/app/onboarding/onboarding.dart';
import 'package:tio_app/app/session/session.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  test('unauthenticated session resolves to unauthenticated', () async {
    final fixture = await _Fixture.create(
      authState: const AuthSessionUnauthenticated(),
    );

    await fixture.controller.refresh();

    expect(
      fixture.controller.state,
      const AppSessionBootstrapUnauthenticated(),
    );
  });

  test('remote completed resolves ready and reconciles local completion',
      () async {
    final fixture = await _Fixture.create(
      authState: _authenticated('user-a'),
      completionResolver: () async =>
          RemoteOnboardingCompletionState.completed,
    );

    await fixture.controller.refresh();

    expect(
      fixture.controller.state,
      const AppSessionBootstrapReady(userId: 'user-a'),
    );
    expect(
      fixture.onboardingStatusController.status,
      OnboardingStatus.completed,
    );
  });

  test('remote incomplete requires onboarding and clears stale local completed',
      () async {
    final fixture = await _Fixture.create(
      authState: _authenticated('user-a'),
      initialLocalStatus: OnboardingStatus.completed,
      completionResolver: () async =>
          RemoteOnboardingCompletionState.incomplete,
    );

    await fixture.controller.refresh();

    expect(
      fixture.controller.state,
      const AppSessionBootstrapRequiresOnboarding(userId: 'user-a'),
    );
    expect(
      fixture.onboardingStatusController.status,
      OnboardingStatus.notStarted,
    );
  });

  test('remote lookup error resolves failure instead of onboarding', () async {
    final fixture = await _Fixture.create(
      authState: _authenticated('user-a'),
      completionResolver: () async => throw StateError('lookup failed'),
    );

    await fixture.controller.refresh();

    expect(fixture.controller.state, isA<AppSessionBootstrapFailure>());
  });

  test('stale user lookup cannot overwrite a newer authenticated user',
      () async {
    final oldUserResult = Completer<RemoteOnboardingCompletionState>();
    var readCount = 0;
    final authRepository = _FakeAuthSessionRepository(
      initialState: _authenticated('user-a'),
    );
    final fixture = await _Fixture.create(
      authRepository: authRepository,
      completionResolver: () {
        readCount++;
        if (readCount == 1) return oldUserResult.future;
        return Future.value(RemoteOnboardingCompletionState.incomplete);
      },
    );

    fixture.controller.start();
    await _flush();

    authRepository.emit(_authenticated('user-b'));
    await _flush();

    expect(
      fixture.controller.state,
      const AppSessionBootstrapRequiresOnboarding(userId: 'user-b'),
    );

    oldUserResult.complete(RemoteOnboardingCompletionState.completed);
    await _flush();

    expect(
      fixture.controller.state,
      const AppSessionBootstrapRequiresOnboarding(userId: 'user-b'),
    );
  });
}

AuthSessionAuthenticated _authenticated(String userId) {
  return AuthSessionAuthenticated(AuthSession(userId: userId));
}

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _Fixture {
  _Fixture({
    required this.controller,
    required this.onboardingStatusController,
  });

  final AppSessionBootstrapController controller;
  final OnboardingStatusController onboardingStatusController;

  static Future<_Fixture> create({
    AuthSessionState? authState,
    _FakeAuthSessionRepository? authRepository,
    OnboardingStatus? initialLocalStatus,
    Future<RemoteOnboardingCompletionState> Function()? completionResolver,
  }) async {
    final modeController = AppModeController(_FakeAppModePreference());
    await modeController.load();

    final statusController = OnboardingStatusController(
      repository: _FakeOnboardingStatusRepository(
        status: initialLocalStatus,
        hasStoredContractVersion: initialLocalStatus != null,
      ),
      appModeController: modeController,
    );

    final sessionRepository = authRepository ??
        _FakeAuthSessionRepository(
          initialState: authState ?? const AuthSessionUnauthenticated(),
        );
    final completionRepository = _FakeOnboardingCompletionRepository(
      resolver: completionResolver ??
          () async => RemoteOnboardingCompletionState.uninitialized,
    );

    return _Fixture(
      onboardingStatusController: statusController,
      controller: AppSessionBootstrapController(
        authSessionRepository: sessionRepository,
        onboardingCompletionRepository: completionRepository,
        onboardingStatusController: statusController,
      ),
    );
  }
}

class _FakeAuthSessionRepository implements AuthSessionRepository {
  _FakeAuthSessionRepository({required AuthSessionState initialState})
      : _currentState = initialState;

  final StreamController<AuthSessionState> _changes =
      StreamController<AuthSessionState>.broadcast();
  AuthSessionState _currentState;

  void emit(AuthSessionState state) {
    _currentState = state;
    _changes.add(state);
  }

  @override
  Stream<AuthSessionState> get sessionState async* {
    yield _currentState;
    yield* _changes.stream;
  }

  @override
  Future<AuthSessionState> get currentSessionState async => _currentState;

  @override
  Future<void> signOut() async {
    emit(const AuthSessionUnauthenticated());
  }
}

class _FakeOnboardingCompletionRepository
    implements OnboardingCompletionRepository {
  _FakeOnboardingCompletionRepository({required this.resolver});

  final Future<RemoteOnboardingCompletionState> Function() resolver;

  @override
  Future<RemoteOnboardingCompletionState> readCurrent() => resolver();

  @override
  Future<void> markCurrentCompleted() async {}
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
  _FakeOnboardingStatusRepository({
    this.status,
    this.hasStoredContractVersion = false,
  });

  OnboardingStatus? status;
  bool hasStoredContractVersion;

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
