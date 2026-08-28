import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/app.dart';
import 'package:tio_app/app/app_mode/app_mode.dart';
import 'package:tio_app/app/network_providers.dart';
import 'package:tio_app/app/onboarding/onboarding.dart';
import 'package:tio_app/app/app_theme.dart';
import 'package:tio_app/app/router.dart';
import 'package:tio_app/app/session/session.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_progress/progress.dart';
import 'package:tio_shared/shared.dart';

/// Focused route-level coverage for the Daily Wellness async read states
/// (`/settings/health-goals/daily-wellness`): loading, error+Retry, and that
/// Retry invalidates the canonical provider rather than fabricating data.
void main() {
  Future<ProviderContainer> buildContainer(
      _FakeWellnessTargetsRepository repository) async {
    final preference = _MemoryAppModePreference(AppMode.hybrid);
    final appModeController = AppModeController(preference);
    await appModeController.load();
    final onboardingRepository = _MemoryOnboardingStatusRepository(
      status: OnboardingStatus.completed,
      hasStoredContractVersion: true,
    );
    final onboardingStatusController = OnboardingStatusController(
      repository: onboardingRepository,
      appModeController: appModeController,
    );
    await onboardingStatusController.load();
    final themeController =
        AppThemeController(_MemoryAppThemePreference(TioThemeMode.system));
    await themeController.load();

    final container = ProviderContainer(
      overrides: [
        appModeControllerProvider.overrideWith((ref) => appModeController),
        onboardingStatusControllerProvider
            .overrideWith((ref) => onboardingStatusController),
        onboardingStatusRepositoryProvider
            .overrideWith((ref) => onboardingRepository),
        appThemeControllerProvider.overrideWith((ref) => themeController),
        appSessionBootstrapControllerProvider.overrideWith(
          (ref) => _FixedAppSessionBootstrapController(
            state: const AppSessionBootstrapReady(userId: 'test-user'),
            onboardingStatusController: onboardingStatusController,
          ),
        ),
        wellnessTargetsRepositoryProvider.overrideWith((ref) => repository),
      ],
    );
    return container;
  }

  testWidgets('wellness read loading shows loading UI, not five Not set values',
      (tester) async {
    final repository = _FakeWellnessTargetsRepository();
    final container = await buildContainer(repository);
    addTearDown(container.dispose);

    container.read(goRouterProvider).go(AppRoutes.dailyWellnessSettings.path);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TioApp()),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Daily Wellness'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Not set'), findsNothing);
    expect(find.byKey(const ValueKey('daily-wellness-save')), findsNothing);

    repository.completeRead(null);
    await tester.pumpAndSettle();
  });

  testWidgets('wellness read error shows error and Retry UI',
      (tester) async {
    final repository = _FakeWellnessTargetsRepository();
    final container = await buildContainer(repository);
    addTearDown(container.dispose);

    container.read(goRouterProvider).go(AppRoutes.dailyWellnessSettings.path);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TioApp()),
    );
    await tester.pump();

    repository.failRead(Exception('network unreachable'));
    await tester.pumpAndSettle();

    expect(find.text('Could not load wellness targets'), findsOneWidget);
    expect(find.widgetWithText(TioButton, 'Retry'), findsOneWidget);
    expect(find.byKey(const ValueKey('daily-wellness-save')), findsNothing);
  });

  testWidgets('Retry invalidates the canonical provider and reloads real data',
      (tester) async {
    final repository = _FakeWellnessTargetsRepository();
    final container = await buildContainer(repository);
    addTearDown(container.dispose);

    container.read(goRouterProvider).go(AppRoutes.dailyWellnessSettings.path);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TioApp()),
    );
    await tester.pump();

    repository.failRead(Exception('network unreachable'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TioButton, 'Retry'), findsOneWidget);
    expect(repository.readCallCount, 1);

    await tester.tap(find.widgetWithText(TioButton, 'Retry'));
    await tester.pump();

    // Retry triggered a fresh canonical read rather than reusing stale state.
    expect(repository.readCallCount, 2);

    const realTargets = WellnessTargetsData(dailySteps: 9000, waterMl: 2400);
    repository.completeRead(realTargets);
    await tester.pumpAndSettle();

    expect(find.text('9000 steps/day'), findsOneWidget);
    expect(find.byKey(const ValueKey('daily-wellness-save')), findsOneWidget);
  });
}

class _FakeWellnessTargetsRepository implements WellnessTargetsRepository {
  Completer<WellnessTargetsData?> _completer =
      Completer<WellnessTargetsData?>();
  var readCallCount = 0;

  @override
  Future<WellnessTargetsData?> read() {
    readCallCount++;
    _completer = Completer<WellnessTargetsData?>();
    return _completer.future;
  }

  void completeRead(WellnessTargetsData? data) {
    if (!_completer.isCompleted) _completer.complete(data);
  }

  void failRead(Object error) {
    if (!_completer.isCompleted) _completer.completeError(error);
  }

  @override
  Future<void> upsert(WellnessTargetsData targets) async {}
}

class _FixedAppSessionBootstrapController
    extends AppSessionBootstrapController {
  _FixedAppSessionBootstrapController({
    required AppSessionBootstrapState state,
    required super.onboardingStatusController,
  })  : fixedState = state,
        super(
          authSessionRepository: InMemoryAuthSessionRepository(),
          onboardingCompletionRepository: null,
        );

  AppSessionBootstrapState fixedState;

  @override
  AppSessionBootstrapState get state => fixedState;

  @override
  void start() {}
}

class _MemoryAppModePreference implements AppModePreference {
  _MemoryAppModePreference(this.mode);

  AppMode? mode;

  @override
  Future<void> clear() async => mode = null;

  @override
  Future<AppMode?> read() async => mode;

  @override
  Future<void> write(AppMode mode) async => this.mode = mode;
}

class _MemoryAppThemePreference implements AppThemePreference {
  _MemoryAppThemePreference(this.mode);

  TioThemeMode? mode;

  @override
  Future<void> clear() async => mode = null;

  @override
  Future<TioThemeMode?> read() async => mode;

  @override
  Future<void> write(TioThemeMode mode) async => this.mode = mode;
}

class _MemoryOnboardingStatusRepository implements OnboardingStatusRepository {
  _MemoryOnboardingStatusRepository({
    required this.status,
    required this.hasStoredContractVersion,
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
  Future<void> write(OnboardingStatus status) async {
    await ensureInitialized();
    this.status = status;
  }
}
