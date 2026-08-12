import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/app.dart';
import 'package:tio_app/app/app_mode/app_mode.dart';
import 'package:tio_app/app/router.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_profile/profile.dart';
import 'package:tio_shared/shared.dart';

void main() {
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
    final container = ProviderContainer(
      overrides: [
        appModeControllerProvider.overrideWith((ref) => controller),
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
    expect(find.text('Nutrition'), findsNothing);
    expect(find.text('Home'), findsWidgets);
  });

  testWidgets('first-run mode confirmation opens Home with hybrid tabs',
      (tester) async {
    final preference = _MemoryAppModePreference(null);
    final controller = AppModeController(preference);
    await controller.load();
    final container = ProviderContainer(
      overrides: [
        appModeControllerProvider.overrideWith((ref) => controller),
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
    await tester.fling(find.byType(ListView), const Offset(0, -700), 1200);
    await tester.pumpAndSettle();
    expect(find.text('Continue'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(controller.selectedMode, AppMode.hybrid);
    expect(router.routeInformationProvider.value.uri.path,
        FeatureRoutes.home.path);
    for (final label in const ['Home', 'Workout', 'Nutrition', 'Progress']) {
      expect(find.text(label), findsWidgets);
    }
  });

  testWidgets('Settings opens through Profile instead of the Home top bar',
      (tester) async {
    final preference = _MemoryAppModePreference(AppMode.hybrid);
    final controller = AppModeController(preference);
    await controller.load();
    final container = ProviderContainer(
      overrides: [
        appModeControllerProvider.overrideWith((ref) => controller),
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
        find.byKey(const ValueKey('profile-settings-entry')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('profile-settings-entry')));
    await tester.pumpAndSettle();

    expect(find.text('App Mode'), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('profile-settings-entry')), findsOneWidget);
  });

  testWidgets('Profile avatar opens the full-screen photo route',
      (tester) async {
    final preference = _MemoryAppModePreference(AppMode.hybrid);
    final controller = AppModeController(preference);
    await controller.load();
    final container = ProviderContainer(
      overrides: [
        appModeControllerProvider.overrideWith((ref) => controller),
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
