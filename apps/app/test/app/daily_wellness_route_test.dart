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
import 'package:tio_feature_settings/settings.dart';
import 'package:tio_shared/shared.dart';

/// Focused route-level coverage for the Daily Wellness async read states
/// (`/settings/health-goals/daily-wellness`): loading, error+Retry, and that
/// Retry invalidates the canonical provider rather than fabricating data.
void main() {
  Future<ProviderContainer> buildContainer(
    _FakeWellnessTargetsRepository repository, {
    _FakeHydrationRepository? hydration,
  }) async {
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
        hydrationPreferencesRepositoryProvider.overrideWith(
          (ref) => hydration ?? _FakeHydrationRepository(),
        ),
      ],
    );
    return container;
  }

  Future<void> openPage(WidgetTester tester, ProviderContainer container,
      _FakeWellnessTargetsRepository wellness) async {
    final router = container.read(goRouterProvider);
    router.go(AppRoutes.healthGoalsSettings.path);
    await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const TioApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daily Wellness'));
    await tester.pump();
    wellness.completeRead(wellness.value);
    await tester.pumpAndSettle();
  }

  Future<void> openGlass(WidgetTester tester) async {
    final row = find.byKey(const ValueKey('daily-wellness-glass-size-field'));
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();
  }

  testWidgets(
      'Glass Size loading and read retry remain isolated from Water Goal',
      (tester) async {
    final wellness = _FakeWellnessTargetsRepository()
      ..value = const WellnessTargetsData(waterMl: 2800);
    final hydration = _FakeHydrationRepository()..readGate = Completer<void>();
    final container = await buildContainer(wellness, hydration: hydration);
    addTearDown(container.dispose);
    await openPage(tester, container, wellness);
    expect(find.text('2800 ml/day (2.8 L)'), findsOneWidget);
    expect(find.text('Loading…'), findsOneWidget);
    await tester.tap(find.text('Glass Size'));
    await tester.pump();
    expect(find.text('Default Glass Size'), findsNothing);
    hydration.failRead = true;
    hydration.readGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Could not load Glass Size'), findsOneWidget);
    expect(find.text('2800 ml/day (2.8 L)'), findsOneWidget);
    hydration.failRead = false;
    hydration.value = const HydrationPreferences(defaultGlassSizeMl: 250);
    await tester.tap(find.byKey(const ValueKey('glass-size-load-retry')));
    await tester.pumpAndSettle();
    expect(hydration.reads, 2);
    expect(find.text('250 ml'), findsOneWidget);
    expect(wellness.writes, isEmpty);
  });

  testWidgets(
      'separate repositories preserve Water 2800 / Glass 250 -> 300, then Water 3000',
      (tester) async {
    final wellness = _FakeWellnessTargetsRepository()
      ..value = const WellnessTargetsData(waterMl: 2800);
    final hydration = _FakeHydrationRepository()
      ..value = const HydrationPreferences(defaultGlassSizeMl: 250);
    final container = await buildContainer(wellness, hydration: hydration);
    addTearDown(container.dispose);
    await openPage(tester, container, wellness);
    await openGlass(tester);
    await tester.tap(find.byKey(const ValueKey('glass-size-preset-300')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('glass-size-save')));
    await tester.pumpAndSettle();
    expect(wellness.value!.waterMl, 2800);
    expect(wellness.writes, isEmpty);
    expect(hydration.value.defaultGlassSizeMl, 300);
    expect(find.text('300 ml'), findsOneWidget);

    await tester.tap(find.text('Water Goal'));
    await tester.pumpAndSettle();
    tester.widget<Slider>(find.byType(Slider)).onChanged!(3000);
    await tester.pump();
    await tester.tap(find.text('Set Goal'));
    await tester.pumpAndSettle();
    expect(hydration.value.defaultGlassSizeMl, 300);
    await tester.tap(find.byKey(const ValueKey('daily-wellness-save')));
    await tester.pumpAndSettle();
    expect(wellness.value!.waterMl, 3000);
    expect(wellness.writes.length, 1);
    expect(hydration.writes.length, 1);
    expect(hydration.value.defaultGlassSizeMl, 300);
    expect(find.text('Health & Goals'), findsOneWidget);
    // Reopen through the route: both summaries hydrate the repositories.
    await tester.tap(find.text('Daily Wellness'));
    await tester.pump();
    wellness.completeRead(wellness.value);
    await tester.pumpAndSettle();
    expect(find.text('3000 ml/day (3 L)'), findsOneWidget);
    expect(find.text('300 ml'), findsOneWidget);
  });

  testWidgets(
      'Glass Save awaits repository, retries failure, and Reset persists on reopen',
      (tester) async {
    final wellness = _FakeWellnessTargetsRepository();
    final hydration = _FakeHydrationRepository()
      ..value = const HydrationPreferences(defaultGlassSizeMl: 300)
      ..writeGate = Completer<void>();
    final container = await buildContainer(wellness, hydration: hydration);
    addTearDown(container.dispose);
    await openPage(tester, container, wellness);
    await openGlass(tester);
    await tester.tap(find.byKey(const ValueKey('glass-size-reset-default')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('glass-size-save')));
    await tester.tap(find.byKey(const ValueKey('glass-size-save')));
    await tester.pump();
    expect(hydration.writes.length, 1);
    expect(hydration.value.defaultGlassSizeMl, 300);
    expect(find.text('Default Glass Size'), findsOneWidget);
    hydration.failWrite = true;
    hydration.writeGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Could not save Glass Size. Please try again.'),
        findsOneWidget);
    hydration.failWrite = false;
    await tester.tap(find.byKey(const ValueKey('glass-size-save')));
    await tester.pumpAndSettle();
    expect(hydration.value.defaultGlassSizeMl, 250);
    expect(wellness.writes, isEmpty);
    await openGlass(tester);
    expect(
        tester
            .widget<Text>(
                find.byKey(const ValueKey('glass-size-draft-summary')))
            .data,
        '250 ml');
  });

  testWidgets('canonical provider refresh reaches open draft and converges',
      (tester) async {
    final wellness = _FakeWellnessTargetsRepository();
    final hydration = _FakeHydrationRepository()
      ..value = const HydrationPreferences(defaultGlassSizeMl: 250);
    final container = await buildContainer(wellness, hydration: hydration);
    addTearDown(container.dispose);
    await openPage(tester, container, wellness);
    await openGlass(tester);
    hydration.value = const HydrationPreferences(defaultGlassSizeMl: 300);
    container.invalidate(hydrationPreferencesDataProvider);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<ChoiceChip>(
                find.byKey(const ValueKey('glass-size-preset-300')))
            .selected,
        isTrue);
    await tester.tap(find.byKey(const ValueKey('glass-size-preset-350')));
    await tester.pump();
    hydration.value = const HydrationPreferences(defaultGlassSizeMl: 500);
    container.invalidate(hydrationPreferencesDataProvider);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<ChoiceChip>(
                find.byKey(const ValueKey('glass-size-preset-350')))
            .selected,
        isTrue);
    hydration.value = const HydrationPreferences(defaultGlassSizeMl: 350);
    container.invalidate(hydrationPreferencesDataProvider);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TioButton>(find.byKey(const ValueKey('glass-size-save')))
            .onPressed,
        isNull);
  });

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
  WellnessTargetsData? value;
  final writes = <WellnessTargetsData>[];
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
  Future<void> upsert(WellnessTargetsData targets) async {
    writes.add(targets);
    value = targets;
  }
}

class _FakeHydrationRepository implements HydrationPreferencesRepository {
  HydrationPreferences value = const HydrationPreferences();
  final writes = <HydrationPreferences>[];
  var reads = 0;
  var failRead = false;
  var failWrite = false;
  Completer<void>? readGate;
  Completer<void>? writeGate;

  @override
  Future<HydrationPreferences> read() async {
    reads++;
    await readGate?.future;
    if (failRead) throw StateError('read failed');
    return value;
  }

  @override
  Future<void> write(HydrationPreferences preferences) async {
    writes.add(preferences);
    await writeGate?.future;
    if (failWrite) throw StateError('write failed');
    value = preferences;
  }

  @override
  Future<void> clear() async => value = const HydrationPreferences();
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
