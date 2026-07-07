import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_splash/splash.dart';
import 'package:tio_feature_welcome/welcome.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

TioShellPlaceholder _page(TioRouteContract route) {
  return TioShellPlaceholder(title: route.title, description: route.description);
}

ChromePolicy _chromePolicyForPath(String location) {
  final appRoutes = [
    AppRoutes.splash,
    AppRoutes.auth,
    AppRoutes.onboarding,
    AppRoutes.profile,
    AppRoutes.settings,
    AppRoutes.login,
  ];

  for (final route in appRoutes) {
    if (route.path == location) return route.chromePolicy;
  }

  if (location.contains('editor')) return ChromePolicy.noBottomBar;
  if (location.contains('modal')) return ChromePolicy.bottomSheet;

  return ChromePolicy.mainChrome;
}

void _handleShellAction(BuildContext context, StatefulNavigationShell navigationShell, ShellAction action) {
  if (action is ShellTabSelected) {
    navigationShell.goBranch(action.tab.index);
    return;
  }

  if (action is ShellProfileClicked) {
    context.push(AppRoutes.profile.path);
  }
}

final goRouter = GoRouter(
  initialLocation: AppRoutes.splash.path,
  navigatorKey: rootNavigatorKey,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        final chromePolicy = _chromePolicyForPath(state.uri.path);

        return TioShell(
          state: ShellUiState(
            selectedTab: ShellTab.fromIndex(navigationShell.currentIndex),
            isBottomNavVisible: chromePolicy.showsBottomNav,
          ),
          onAction: (action) => _handleShellAction(context, navigationShell, action),
          child: navigationShell,
        );
      },
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: FeatureRoutes.home.path, builder: (context, state) => _page(FeatureRoutes.home))]),
        StatefulShellBranch(routes: [GoRoute(path: FeatureRoutes.nutrition.path, builder: (context, state) => _page(FeatureRoutes.nutrition))]),
        StatefulShellBranch(routes: [GoRoute(path: FeatureRoutes.ai.path, builder: (context, state) => _page(FeatureRoutes.ai))]),
        StatefulShellBranch(routes: [GoRoute(path: FeatureRoutes.workout.path, builder: (context, state) => _page(FeatureRoutes.workout))]),
        StatefulShellBranch(routes: [GoRoute(path: FeatureRoutes.progress.path, builder: (context, state) => _page(FeatureRoutes.progress))]),
      ],
    ),
    GoRoute(path: AppRoutes.splash.path, parentNavigatorKey: rootNavigatorKey, builder: (context, state) => const SplashScreen()),
    GoRoute(path: AppRoutes.auth.path, parentNavigatorKey: rootNavigatorKey, builder: (context, state) => const WelcomeScreen()),
    GoRoute(path: AppRoutes.login.path, parentNavigatorKey: rootNavigatorKey, builder: (context, state) => const LoginPage()),
    GoRoute(path: AppRoutes.onboarding.path, parentNavigatorKey: rootNavigatorKey, builder: (context, state) => _page(AppRoutes.onboarding)),
    GoRoute(path: AppRoutes.profile.path, parentNavigatorKey: rootNavigatorKey, builder: (context, state) => _page(AppRoutes.profile)),
    GoRoute(path: AppRoutes.settings.path, parentNavigatorKey: rootNavigatorKey, builder: (context, state) => _page(AppRoutes.settings)),
  ],
);
