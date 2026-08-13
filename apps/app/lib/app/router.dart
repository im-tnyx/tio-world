import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_home/home.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_profile/profile.dart';
import 'package:tio_feature_settings/settings.dart';
import 'package:tio_feature_splash/splash.dart';
import 'package:tio_feature_welcome/welcome.dart';

import 'app_mode/app_mode.dart';
import 'app_theme.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

TioShellPlaceholder _page(TioRouteContract route) {
  return TioShellPlaceholder(
      title: route.title, description: route.description);
}

Widget _shellBranchPage(ShellBranchDefinition branch) {
  if (branch.tab == ShellTab.home) {
    return const HomePage();
  }

  return _page(branch.route);
}

ChromePolicy shellChromePolicyForPath(String location) {
  final appRoutes = [
    AppRoutes.splash,
    AppRoutes.auth,
    AppRoutes.onboarding,
    AppRoutes.profile,
    AppRoutes.profileAvatar,
    AppRoutes.settings,
    AppRoutes.appSettings,
    AppRoutes.appModeSettings,
    AppRoutes.themeSettings,
    AppRoutes.login,
  ];

  for (final route in appRoutes) {
    if (route.path == location) return route.chromePolicy;
  }

  final isMainTabRoot =
      shellBranchRegistry.any((branch) => branch.route.path == location);
  if (isMainTabRoot) return ChromePolicy.mainChrome;

  return ChromePolicy.noBottomBar;
}

void _handleShellAction(GoRouter router,
    StatefulNavigationShell navigationShell, ShellAction action) {
  if (action is ShellTabSelected) {
    navigationShell.goBranch(action.tab.branchIndex);
    return;
  }

  if (action is ShellProfileClicked) {
    router.push(AppRoutes.profile.path);
    return;
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final appModeController = ref.read(appModeControllerProvider);
  final appThemeController = ref.read(appThemeControllerProvider);
  late final GoRouter router;
  router = GoRouter(
    initialLocation: AppRoutes.splash.path,
    navigatorKey: rootNavigatorKey,
    refreshListenable: appModeController,
    redirect: (context, state) => appModeRedirect(
      path: state.uri.path,
      selectedMode: appModeController.selectedMode,
    ),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          final chromePolicy = shellChromePolicyForPath(state.uri.path);

          return Consumer(
            builder: (context, ref, child) {
              final selectedMode =
                  ref.watch(appModeControllerProvider).selectedMode;
              final visibleTabs = selectedMode == null
                  ? const [ShellTab.home]
                  : guidedShellTabs(selectedMode);

              return TioShell(
                state: ShellUiState(
                  selectedTab:
                      ShellTab.fromBranchIndex(navigationShell.currentIndex),
                  visibleTabs: visibleTabs,
                  isBottomNavVisible: chromePolicy.showsBottomNav,
                  isRootTopBarVisible: chromePolicy.showsRootTopBar,
                ),
                onAction: (action) =>
                    _handleShellAction(router, navigationShell, action),
                child: child!,
              );
            },
            child: navigationShell,
          );
        },
        branches: shellBranchRegistry.map((branch) {
          return StatefulShellBranch(
            routes: [
              GoRoute(
                path: branch.route.path,
                builder: (context, state) => _shellBranchPage(branch),
              ),
            ],
          );
        }).toList(growable: false),
      ),
      GoRoute(
        path: AppRoutes.splash.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const WelcomeRoute(),
      ),
      GoRoute(
        path: AppRoutes.login.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => OnboardingFlowPage(
          seed: OnboardingControllerSeed(
            entryPath: OnboardingEntryPath.firstRun,
          ),
          onExitRequested: () async {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go(AppRoutes.auth.path);
          },
          onFinishRequested: (draft) async {
            final mode = draft.selectedMode;
            if (mode == null) {
              throw StateError('App Mode is required before finishing setup.');
            }

            await appModeController.select(mode);
            if (context.mounted) context.go(FeatureRoutes.home.path);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.profile.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => ProfilePage(
          onAvatarPressed: () => context.push(AppRoutes.profileAvatar.path),
          onSettingsPressed: () => context.push(AppRoutes.settings.path),
        ),
      ),
      GoRoute(
        path: AppRoutes.profileAvatar.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => AvatarPreviewPage(
          onBackPressed: context.pop,
        ),
      ),
      GoRoute(
        path: AppRoutes.settings.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => SettingsPage(
          onAppSettingsPressed: () => context.push(AppRoutes.appSettings.path),
        ),
      ),
      GoRoute(
        path: AppRoutes.appSettings.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final currentMode = appModeController.selectedMode;
          if (currentMode == null) return const SizedBox.shrink();

          return AppSettingsPage(
            currentMode: currentMode,
            currentThemeMode: appThemeController.selectedMode,
            onAppModePressed: () =>
                context.push(AppRoutes.appModeSettings.path),
            onThemePressed: () => context.push(AppRoutes.themeSettings.path),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.appModeSettings.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final currentMode = appModeController.selectedMode;
          if (currentMode == null) return const SizedBox.shrink();

          return AppModeSettingsPage(
            currentMode: currentMode,
            onModeChanged: (mode) async {
              await appModeController.select(mode);
              if (context.mounted) context.go(FeatureRoutes.home.path);
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.themeSettings.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => ThemeSettingsPage(
          currentMode: appThemeController.selectedMode,
          onThemeChanged: (mode) async {
            await appThemeController.select(mode);
            if (context.mounted) context.pop();
          },
        ),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
