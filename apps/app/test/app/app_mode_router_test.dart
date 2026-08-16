import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/app.dart';
import 'package:tio_app/app/app_mode/app_mode.dart';
import 'package:tio_app/app/onboarding/onboarding.dart';
import 'package:tio_app/app/app_theme.dart';
import 'package:tio_app/app/router.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_home/home.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_profile/profile.dart';
import 'package:tio_shared/shared.dart';

void main() {
  for (final testCase in const [
    (
      name: 'light',
      platformBrightness: Brightness.light,
      config: TioThemeConfig(),
      expectedIconBrightness: Brightness.dark,
    ),
    (
      name: 'dark',
      platformBrightness: Brightness.dark,
      config: TioThemeConfig(),
      expectedIconBrightness: Brightness.light,
    ),
    (
      name: 'OLED',
      platformBrightness: Brightness.light,
      config: TioThemeConfig(mode: TioThemeMode.oled),
      expectedIconBrightness: Brightness.light,
    ),
  ]) {
    testWidgets('system bar icons follow the resolved ${testCase.name} theme',
        (tester) async {
      final overlay = await _pumpSystemUiOverlay(
        tester,
        platformBrightness: testCase.platformBrightness,
        config: testCase.config,
      );

      expect(
        overlay.statusBarIconBrightness,
        testCase.expectedIconBrightness,
      );
      expect(
        overlay.systemNavigationBarIconBrightness,
        testCase.expectedIconBrightness,
      );
    });
  }

  test('bottom navigation is limited to main tab root routes', () {
    for (final branch in shellBranchRegistry) {
      expect(
        shellChromePolicyForPath(branch.route.path),
        ChromePolicy.mainChrome,
      );
    }

    expect(
      shellChromePolicyForPath('/workout/session'),
      ChromePolicy.noBottomBar,
    );
    expect(
      shellChromePolicyForPath('/nutrition/meal-log'),
      ChromePolicy.noBottomBar,
    );
    expect(
      shellChromePolicyForPath(AppRoutes.profile.path),
      ChromePolicy.fullScreen,
    );
  });

  testWidgets('mode change redirects an active hidden branch to Home',
      (tester) async {
    final preference = _MemoryAppModePreference(AppMode.hybrid);
    final controller = AppModeController(preference);
    await controller.load();
    final onboardingRepository = _MemoryOnboardingStatusRepository(
      status: OnboardingStatus.completed,
      hasStoredContractVersion: true,
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
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider);
    router.go(FeatureRoutes.nutrition.path);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TioApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path,
        FeatureRoutes.nutrition.path);
    expect(find.text('Nutrition'), findsWidgets);

    await controller.select(AppMode.workout);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path,
        FeatureRoutes.home.path);
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets(
      'first-run review stays in onboarding while compatibility steps block completion',
      (tester) async {
    final preference = _MemoryAppModePreference(null);
    final controller = AppModeController(preference);
    await controller.load();
    final onboardingRepository = _MemoryOnboardingStatusRepository(
      status: null,
      hasStoredContractVersion: false,
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
    await tester.ensureVisible(find.byKey(const ValueKey('app-mode-hybrid')));
    await tester.tap(find.byKey(const ValueKey('app-mode-hybrid')));
    await tester.pumpAndSettle();
    expect(controller.selectedMode, isNull);
    expect(find.text('Continue'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path,
        AppRoutes.onboarding.path);
    expect(controller.selectedMode, isNull);

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

    expect(controller.selectedMode, isNull);
    expect(onboardingRepository.status, OnboardingStatus.inProgress);
    expect(onboardingStatusController.status, OnboardingStatus.notStarted);
    expect(router.routeInformationProvider.value.uri.path,
        AppRoutes.onboarding.path);
  });

  testWidgets('Settings opens through Profile instead of the Home top bar',
      (tester) async {
    final preference = _MemoryAppModePreference(AppMode.hybrid);
    final controller = AppModeController(preference);
    await controller.load();
    final onboardingRepository = _MemoryOnboardingStatusRepository(
      status: OnboardingStatus.completed,
      hasStoredContractVersion: true,
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
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider);
    router.go(FeatureRoutes.home.path);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TioApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Settings'), findsNothing);
    expect(find.byTooltip('Profile'), findsOneWidget);

    tester
        .widget<TioShell>(find.byType(TioShell))
        .onAction(const ShellProfileClicked());
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('profile-settings-action')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('profile-settings-action')));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('settings-app-settings-entry')),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings-app-settings-entry')));
    await tester.pumpAndSettle();

    expect(find.text('App Settings'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('app-settings-app-mode-entry')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('app-settings-theme-entry')),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('settings-app-settings-entry')),
      findsOneWidget,
    );
  });

  testWidgets('Profile avatar opens the full-screen photo route',
      (tester) async {
    final preference = _MemoryAppModePreference(AppMode.hybrid);
    final controller = AppModeController(preference);
    await controller.load();
    final onboardingRepository = _MemoryOnboardingStatusRepository(
      status: OnboardingStatus.completed,
      hasStoredContractVersion: true,
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
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider);
    router.go(AppRoutes.profile.path);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TioApp(),
      ),
    );
    await tester.pumpAndSettle();

    tester
        .widget<InkWell>(
          find.descendant(
            of: find.byKey(const ValueKey('profile-avatar-entry')),
            matching: find.byType(InkWell),
          ),
        )
        .onTap!();
    await tester.pumpAndSettle();

    expect(find.byType(AvatarPreviewPage), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byTooltip('Edit profile photo'), findsOneWidget);
    expect(find.byTooltip('Delete profile photo'), findsOneWidget);
    expect(find.byTooltip('Download profile photo'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(AvatarPreviewPage), findsNothing);
    expect(find.byKey(const ValueKey('profile-avatar-entry')), findsOneWidget);
  });
}

Future<SystemUiOverlayStyle> _pumpSystemUiOverlay(
  WidgetTester tester, {
  required Brightness platformBrightness,
  required TioThemeConfig config,
}) async {
  tester.platformDispatcher.platformBrightnessTestValue = platformBrightness;
  addTearDown(
    tester.platformDispatcher.clearPlatformBrightnessTestValue,
  );
  final preference = _MemoryAppModePreference(AppMode.hybrid);
  final controller = AppModeController(preference);
  await controller.load();
  final onboardingRepository = _MemoryOnboardingStatusRepository(
    status: OnboardingStatus.completed,
    hasStoredContractVersion: true,
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
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: TioApp(themeConfig: config),
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
  await tester.enterText(find.byType(TextFormField), 'Tio User');
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();

  await _tapVisibleKey(tester, 'profile-choice-gender-other');
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();

  await _tapVisibleKey(tester, 'profile-choice-goal-keepFit');
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();

  // Date of birth (in-screen wheel picker defaults to 15/04/2003)
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();

  // Height (wheel picker defaults to 170cm)
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();

  // Current weight (wheel picker defaults to 70.0kg)
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();

  // Target weight (wheel picker defaults to 68.0kg)
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();

  await _tapVisibleKey(tester, 'profile-choice-activity-active');
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();

  await _tapVisibleKey(tester, 'profile-choice-health-none');
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
}

Future<void> _tapVisibleKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
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
