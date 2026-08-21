import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/app.dart';
import 'package:tio_app/app/app_mode.dart';
import 'package:tio_app/app/app_theme.dart';
import 'package:tio_app/app/onboarding.dart';
import 'package:tio_app/app/providers.dart';
import 'package:tio_app/app/router.dart';
import 'package:tio_app/app/session.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_account_setup/account_setup.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('system bar icons follow the resolved light theme', (tester) async {
    final style = await _pumpResolvedSystemUiStyle(
      tester,
      themeMode: TioThemeMode.light,
      platformBrightness: Brightness.dark,
    );

    expect(style.statusBarIconBrightness, Brightness.dark);
    expect(style.systemNavigationBarIconBrightness, Brightness.dark);
  });

  testWidgets('system bar icons follow the resolved dark theme', (tester) async {
    final style = await _pumpResolvedSystemUiStyle(
      tester,
      themeMode: TioThemeMode.dark,
      platformBrightness: Brightness.light,
    );

    expect(style.statusBarIconBrightness, Brightness.light);
    expect(style.systemNavigationBarIconBrightness, Brightness.light);
  });

  testWidgets('system bar icons follow the resolved OLED theme', (tester) async {
    final style = await _pumpResolvedSystemUiStyle(
      tester,
      themeMode: TioThemeMode.oled,
      platformBrightness: Brightness.light,
    );

    expect(style.statusBarIconBrightness, Brightness.light);
    expect(style.systemNavigationBarIconBrightness, Brightness.light);
  });

  testWidgets('bottom navigation is limited to main tab root routes',
      (tester) async {
    final preference = _MemoryAppModePreference(AppMode.hybrid);
    final controller = AppModeController(preference);
    await controller.load();
    final themeController = await _createThemeController();
    final container = ProviderContainer(
      overrides: [
        appModeControllerProvider.overrideWith((ref) => controller),
        appThemeControllerProvider.overrideWith((ref) => themeController),
        appSessionBootstrapControllerProvider.overrideWith(
          (ref) => _FixedAppSessionBootstrapController(
            state: const AppSessionBootstrapReady(
              userId: 'test-user',
              confirmedMode: AppMode.hybrid,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TioApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);

    router.go(FeatureRoutes.profile.path);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);

    router.go(FeatureRoutes.workout.path);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('mode change redirects an active hidden branch to Home',
      (tester) async {
    final preference = _MemoryAppModePreference(AppMode.hybrid);
    final controller = AppModeController(preference);
    await controller.load();
    final themeController = await _createThemeController();
    final container = ProviderContainer(
      overrides: [
        appModeControllerProvider.overrideWith((ref) => controller),
        appThemeControllerProvider.overrideWith((ref) => themeController),
        appSessionBootstrapControllerProvider.overrideWith(
          (ref) => _FixedAppSessionBootstrapController(
            state: const AppSessionBootstrapReady(
              userId: 'test-user',
              confirmedMode: AppMode.hybrid,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TioApp(),
      ),
    );
    await tester.pumpAndSettle();

    router.go(FeatureRoutes.workout.path);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path,
        FeatureRoutes.workout.path);

    await controller.selectMode(AppMode.nutrition);
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      FeatureRoutes.home.path,
    );
  });

  testWidgets(
      'first-run review stays in onboarding while durable persistence blocks completion',
      (tester) async {
    final preference = _MemoryAppModePreference(AppMode.hybrid);
    final controller = AppModeController(preference);
    await controller.load();
    final onboardingRepository = _MemoryOnboardingStatusRepository(
      OnboardingStatus.inProgress,
    );
    final onboardingStatusController = OnboardingStatusController(
      repository: onboardingRepository,
      appModeController: controller,
    );
    await onboardingStatusController.load();
    final themeController = await _createThemeController();
    final container = ProviderContainer(
      overrides: [
        appModeControllerProvider.overrideWith((ref) => controller),
        onboardingStatusControllerProvider
            .overrideWith((ref) => onboardingStatusController),
        onboardingStatusRepositoryProvider
            .overrideWith((ref) => onboardingRepository),
        appThemeControllerProvider.overrideWith((ref) => themeController),
        appSessionBootstrapControllerProvider.overrideWith(
          (ref) => _FixedAppSessionBootstrapController(
            state: const AppSessionBootstrapRequiresOnboarding(
              userId: 'test-user',
            ),
            onboardingStatusController: onboardingStatusController,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider)
      ..go(FeatureRoutes.home.path);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TioApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path,
        AppRoutes.onboarding.path);
    expect(find.byKey(const ValueKey('app-mode-hybrid')), findsNothing);
    expect(find.text('What should Tio call you?'), findsOneWidget);
    expect(controller.selectedMode, AppMode.hybrid);

    await _completeProfileInputs(tester);

    await tester
        .ensureVisible(find.byKey(const ValueKey('workout-intro-later')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('workout-intro-later')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    for (var step = 0;
        step < 8 && find.text('Finish').evaluate().isEmpty;
        step++) {
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
    }

    expect(find.text('Finish'), findsOneWidget);
    expect(
      find.textContaining('Finish stays disabled until durable owner persistence'),
      findsOneWidget,
    );
    expect(find.text('Pending'), findsNothing);

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(controller.selectedMode, AppMode.hybrid);
    expect(onboardingStatusController.status, OnboardingStatus.inProgress);
    expect(router.routeInformationProvider.value.uri.path,
        AppRoutes.onboarding.path);
  });

  testWidgets('Settings opens through Profile instead of the Home top bar',
      (tester) async {
    final preference = _MemoryAppModePreference(AppMode.hybrid);
    final controller = AppModeController(preference);
    await controller.load();
    final themeController = await _createThemeController();
    final container = ProviderContainer(
      overrides: [
        appModeControllerProvider.overrideWith((ref) => controller),
        appThemeControllerProvider.overrideWith((ref) => themeController),
        appSessionBootstrapControllerProvider.overrideWith(
          (ref) => _FixedAppSessionBootstrapController(
            state: const AppSessionBootstrapReady(
              userId: 'test-user',
              confirmedMode: AppMode.hybrid,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TioApp(),
      ),
    );
    await tester.pumpAndSettle();

    router.go(FeatureRoutes.profile.path);
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsWidgets);

    router.go(FeatureRoutes.settings.path);
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('Profile avatar opens the full-screen photo route',
      (tester) async {
    final preference = _MemoryAppModePreference(AppMode.hybrid);
    final controller = AppModeController(preference);
    await controller.load();
    final themeController = await _createThemeController();
    final container = ProviderContainer(
      overrides: [
        appModeControllerProvider.overrideWith((ref) => controller),
        appThemeControllerProvider.overrideWith((ref) => themeController),
        appSessionBootstrapControllerProvider.overrideWith(
          (ref) => _FixedAppSessionBootstrapController(
            state: const AppSessionBootstrapReady(
              userId: 'test-user',
              confirmedMode: AppMode.hybrid,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TioApp(),
      ),
    );
    await tester.pumpAndSettle();

    router.go(FeatureRoutes.profile.path);
    await tester.pumpAndSettle();

    final avatar = find.byType(TioAvatar).first;
    await tester.tap(avatar);
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      FeatureRoutes.profilePhoto.path,
    );
  });
}

Future<SystemUiOverlayStyle> _pumpResolvedSystemUiStyle(
  WidgetTester tester, {
  required TioThemeMode themeMode,
  required Brightness platformBrightness,
}) async {
  tester.platformDispatcher.platformBrightnessTestValue = platformBrightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

  final preference = _MemoryAppThemePreference(themeMode);
  final controller = AppThemeController(preference);
  await controller.load();
  final modeController = AppModeController(
    _MemoryAppModePreference(AppMode.hybrid),
  );
  await modeController.load();
  final container = ProviderContainer(
    overrides: [
      appThemeControllerProvider.overrideWith((ref) => controller),
      appModeControllerProvider.overrideWith((ref) => modeController),
      appSessionBootstrapControllerProvider.overrideWith(
        (ref) => _FixedAppSessionBootstrapController(
          state: const AppSessionBootstrapReady(
            userId: 'test-user',
            confirmedMode: AppMode.hybrid,
          ),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const TioApp(),
    ),
  );
  await tester.pumpAndSettle();

  return tester
      .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
      )
      .firstWhere(
        (region) => region.value.systemNavigationBarContrastEnforced == false,
      )
      .value;
}

Future<AppThemeController> _createThemeController() async {
  final controller =
      AppThemeController(_MemoryAppThemePreference(TioThemeMode.system));
  await controller.load();
  return controller;
}

Future<void> _completeProfileInputs(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), 'Tio User');
  await tester.tap(find.widgetWithText(TioButton, 'Continue'),
      warnIfMissed: false);
  await tester.pumpAndSettle();

  await tester.tap(
    find.byKey(const ValueKey('gender-other'), skipOffstage: false),
    warnIfMissed: false,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(TioButton, 'Continue'),
      warnIfMissed: false);
  await tester.pumpAndSettle();

  await tester.tap(
    find.byKey(const ValueKey('goal-intent-stayFit'), skipOffstage: false),
    warnIfMissed: false,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(TioButton, 'Continue'),
      warnIfMissed: false);
  await tester.pumpAndSettle();

  final onboardingController = tester
      .widget<ProfileStepRenderer>(find.byType(ProfileStepRenderer))
      .controller;
  onboardingController
    ..updateProfileDateOfBirth(DateTime(2000, 1, 1))
    ..updateProfileHeight(170.0)
    ..updateProfileCurrentWeight(70.0)
    ..updateProfileTargetWeight(65.0);
  await tester.pump();

  // Age -> Measurement Units. Defaults are valid, so Continue advances.
  await tester.tap(find.widgetWithText(TioButton, 'Continue'),
      warnIfMissed: false);
  await tester.pumpAndSettle();
  expect(find.text('Choose your units'), findsOneWidget);

  // Measurement Units -> Height.
  await tester.tap(find.widgetWithText(TioButton, 'Continue'),
      warnIfMissed: false);
  await tester.pumpAndSettle();

  // Height -> Current Weight.
  await tester.tap(find.widgetWithText(TioButton, 'Continue'),
      warnIfMissed: false);
  await tester.pumpAndSettle();

  // Current Weight -> Target Weight.
  await tester.tap(find.widgetWithText(TioButton, 'Continue'),
      warnIfMissed: false);
  await tester.pumpAndSettle();

  // Target Weight -> Activity.
  await tester.tap(find.widgetWithText(TioButton, 'Continue'),
      warnIfMissed: false);
  await tester.pumpAndSettle();

  onboardingController.updateProfileActivity(ProfileActivityLevel.active);
  await tester.pump();
  await tester.tap(find.widgetWithText(TioButton, 'Continue'),
      warnIfMissed: false);
  await tester.pumpAndSettle();

  // Health conditions are optional.
  await tester.tap(find.widgetWithText(TioButton, 'Continue'),
      warnIfMissed: false);
  await tester.pumpAndSettle();
}

class _MemoryAppModePreference implements AppModePreference {
  _MemoryAppModePreference(this.mode);

  AppMode? mode;

  @override
  Future<AppMode?> read() async => mode;

  @override
  Future<void> write(AppMode mode) async {
    this.mode = mode;
  }
}

class _MemoryOnboardingStatusRepository implements OnboardingStatusRepository {
  _MemoryOnboardingStatusRepository(this.status);

  OnboardingStatus status;

  @override
  Future<OnboardingStatusSnapshot> read() async => OnboardingStatusSnapshot(
        status: status,
        schemaVersion: OnboardingStatusSnapshot.currentSchemaVersion,
      );

  @override
  Future<void> write(OnboardingStatus status) async {
    this.status = status;
  }
}

class _MemoryAppThemePreference implements AppThemePreference {
  _MemoryAppThemePreference(this.mode);

  TioThemeMode mode;

  @override
  Future<TioThemeMode?> read() async => mode;

  @override
  Future<void> write(TioThemeMode mode) async {
    this.mode = mode;
  }
}

class _FixedAppSessionBootstrapController extends AppSessionBootstrapController {
  _FixedAppSessionBootstrapController({
    required this.state,
    OnboardingStatusController? onboardingStatusController,
  }) : super(
          appSessionRepository: _FakeAppSessionRepository(),
          completionRepository: _FixedCompletionRepository(),
          onboardingStatusController: onboardingStatusController,
        );

  @override
  final AppSessionBootstrapState state;

  @override
  void start() {}

  @override
  void dispose() {}
}

class _FakeAppSessionRepository implements AppSessionRepository {
  @override
  AppSessionAuthState get currentAuthState =>
      const AppSessionAuthenticated(userId: 'test-user');

  @override
  Stream<AppSessionAuthState> get authStateChanges => const Stream.empty();
}

class _FixedCompletionRepository implements OnboardingCompletionRepository {
  @override
  Future<RemoteOnboardingCompletionState> readCurrent() async =>
      RemoteOnboardingCompletionState.incomplete;

  @override
  Future<void> markCurrentCompleted() async {}
}
