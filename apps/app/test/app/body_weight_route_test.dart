import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/app.dart';
import 'package:tio_app/app/app_mode/app_mode.dart';
import 'package:tio_app/app/app_theme.dart';
import 'package:tio_app/app/network_providers.dart';
import 'package:tio_app/app/onboarding/onboarding.dart';
import 'package:tio_app/app/router.dart';
import 'package:tio_app/app/session/session.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_profile/profile.dart';
import 'package:tio_feature_progress/progress.dart';
import 'package:tio_feature_settings/settings.dart';
import 'package:tio_shared/shared.dart';

/// Focused route-level coverage for Body & Weight
/// (`/settings/health-goals/body-weight`): navigation from Health & Goals,
/// App Mode independence, canonical provider refresh after save, and that
/// the Profile canonical read provider is invalidated alongside it so
/// Profile Current Weight cannot go stale.
void main() {
  Future<ProviderContainer> buildContainer(
    _FakeBodyRepository repository, {
    AppMode appMode = AppMode.hybrid,
    List<Override> extraOverrides = const [],
  }) async {
    final preference = _MemoryAppModePreference(appMode);
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
        bodyRepositoryProvider.overrideWith((ref) => repository),
        ...extraOverrides,
      ],
    );
    return container;
  }

  Future<void> openHealthGoals(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    final router = container.read(goRouterProvider);
    router.go(AppRoutes.healthGoalsSettings.path);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TioApp()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
      'Health & Goals navigates to Body & Weight and shows canonical state',
      (tester) async {
    final repository = _FakeBodyRepository();
    final container = await buildContainer(repository);
    addTearDown(container.dispose);

    await openHealthGoals(tester, container);
    expect(find.text('Body & Weight'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('health-goals-body-weight-entry')),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repository.completeRead(
      BodyState(
        latestWeight: BodyWeightEntry(
          weightKg: 68.4,
          measuredAt: DateTime.utc(2026, 4, 20),
        ),
        activeGoal: const BodyGoalState(
          goalType: BodyGoalType.loseWeight,
          startingWeightKg: 71,
          targetWeightKg: 65,
          weeklyWeightChangeKg: 0.5,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Body & Weight'), findsOneWidget);
    expect(find.text('68.4 kg'), findsOneWidget);
    expect(find.text('Lose Weight'), findsOneWidget);
  });

  testWidgets('Daily Wellness still routes normally alongside Body & Weight',
      (tester) async {
    final repository = _FakeBodyRepository();
    final container = await buildContainer(
      repository,
      extraOverrides: [
        wellnessTargetsRepositoryProvider
            .overrideWith((ref) => InMemoryWellnessTargetsRepository()),
        hydrationPreferencesRepositoryProvider
            .overrideWith((ref) => _NoopHydrationRepository()),
      ],
    );
    addTearDown(container.dispose);

    await openHealthGoals(tester, container);
    expect(find.text('Daily Wellness'), findsOneWidget);
    expect(find.text('Body & Weight'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('health-goals-daily-wellness-entry')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Set and adjust your daily targets for movement, hydration, '
        'sleep duration, and schedule.',
      ),
      findsOneWidget,
    );
  });

  for (final mode in [AppMode.workout, AppMode.nutrition, AppMode.hybrid]) {
    testWidgets('Body & Weight is reachable regardless of App Mode ($mode)',
        (tester) async {
      final repository = _FakeBodyRepository();
      final container = await buildContainer(repository, appMode: mode);
      addTearDown(container.dispose);

      await openHealthGoals(tester, container);
      expect(find.text('Body & Weight'), findsOneWidget);

      await tester.tap(find.text('Body & Weight'));
      await tester.pump();
      await tester.pump();
      repository.completeRead(const BodyState());
      await tester.pumpAndSettle();

      expect(find.text('Body & Weight'), findsWidgets);
      expect(find.byKey(const ValueKey('body-weight-current-weight-field')),
          findsOneWidget);
    });
  }

  testWidgets(
      'saving Current Weight refreshes canonical Body state and Profile read provider',
      (tester) async {
    final repository = _FakeBodyRepository();
    var profileRebuilds = 0;
    final container = await buildContainer(
      repository,
      extraOverrides: [
        profileDataProvider.overrideWith((ref) {
          profileRebuilds++;
          return Stream<ProfileSetupData?>.value(null);
        }),
      ],
    );
    addTearDown(container.dispose);

    await openHealthGoals(tester, container);
    await tester.tap(find.text('Body & Weight'));
    await tester.pump();
    await tester.pump();
    repository.completeRead(const BodyState());
    await tester.pumpAndSettle();

    final rebuildsBeforeSave = profileRebuilds;
    expect(find.text('Not set'), findsWidgets);

    await tester
        .tap(find.byKey(const ValueKey('body-weight-current-weight-field')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('body-weight-current-weight-input')),
      '69.5',
    );
    repository.nextRead = BodyState(
      latestWeight: BodyWeightEntry(
        weightKg: 69.5,
        measuredAt: DateTime.utc(2026, 4, 21),
      ),
    );
    await tester
        .tap(find.byKey(const ValueKey('body-weight-current-weight-save')));
    await tester.pumpAndSettle();

    expect(repository.writes, hasLength(1));
    expect((repository.writes.single as BodyWeightRecord).weightKg, 69.5);
    expect(
      (repository.writes.single as BodyWeightRecord).source,
      BodyWeightSources.bodyWeightSettings,
    );
    // Profile's own canonical read provider was invalidated too, so it does
    // not stay stale relative to the Body owner Body & Weight just wrote.
    expect(profileRebuilds, greaterThan(rebuildsBeforeSave));
    expect(find.text('69.5 kg'), findsOneWidget);
  });
}

class _FakeBodyRepository implements BodyRepository {
  BodyState? nextRead;
  final writes = <Object>[];
  Completer<BodyState> _completer = Completer<BodyState>();
  var readCallCount = 0;

  @override
  Future<BodyState> getBodyState() {
    readCallCount++;
    _completer = Completer<BodyState>();
    if (nextRead != null) {
      _completer.complete(nextRead);
    }
    return _completer.future;
  }

  void completeRead(BodyState state) {
    if (!_completer.isCompleted) _completer.complete(state);
  }

  @override
  Future<void> recordCurrentWeight(BodyWeightRecord record) async {
    writes.add(record);
  }

  @override
  Future<void> setActiveBodyGoal(BodyGoalUpdate update) async {
    writes.add(update);
  }

  @override
  Future<void> saveBodySetup(BodySetupData data) async {
    throw UnsupportedError('not used by this route test');
  }
}

class _NoopHydrationRepository implements HydrationPreferencesRepository {
  @override
  Future<HydrationPreferences> read() async => const HydrationPreferences();

  @override
  Future<void> write(HydrationPreferences preferences) async {}

  @override
  Future<void> clear() async {}
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
