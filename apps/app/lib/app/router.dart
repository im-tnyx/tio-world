import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_coaching/coaching.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_profile/profile.dart';
import 'package:tio_feature_progress/progress.dart';
import 'package:tio_feature_settings/settings.dart';
import 'package:tio_feature_workout/workout.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

TioShellPlaceholder _page(String title, String description) {
  return TioShellPlaceholder(title: title, description: description);
}

bool _isBottomNavVisible(GoRouterState state) {
  final location = state.uri.path;
  return !location.contains('editor') && !location.contains('modal');
}

void _handleShellAction(BuildContext context, StatefulNavigationShell navigationShell, ShellAction action) {
  if (action is ShellTabSelected) {
    navigationShell.goBranch(action.tab.index);
    return;
  }

  if (action is ShellProfileClicked) {
    context.push(ProfileRoutes.path);
  }
}

final goRouter = GoRouter(
  initialLocation: '/',
  navigatorKey: rootNavigatorKey,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return TioShell(
          state: ShellUiState(
            selectedTab: ShellTab.fromIndex(navigationShell.currentIndex),
            isBottomNavVisible: _isBottomNavVisible(state),
          ),
          onAction: (action) => _handleShellAction(context, navigationShell, action),
          child: navigationShell,
        );
      },
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/', builder: (context, state) => _page('Home', 'Your daily health and fitness overview.'))]),
        StatefulShellBranch(routes: [GoRoute(path: NutritionRoutes.path, builder: (context, state) => _page(NutritionRoutes.title, NutritionRoutes.description))]),
        StatefulShellBranch(routes: [GoRoute(path: CoachingRoutes.path, builder: (context, state) => _page(CoachingRoutes.title, CoachingRoutes.description))]),
        StatefulShellBranch(routes: [GoRoute(path: WorkoutRoutes.path, builder: (context, state) => _page(WorkoutRoutes.title, WorkoutRoutes.description))]),
        StatefulShellBranch(routes: [GoRoute(path: ProgressRoutes.path, builder: (context, state) => _page(ProgressRoutes.title, ProgressRoutes.description))]),
      ],
    ),
    GoRoute(path: AuthRoutes.path, parentNavigatorKey: rootNavigatorKey, builder: (context, state) => _page(AuthRoutes.title, AuthRoutes.description)),
    GoRoute(path: OnboardingRoutes.path, parentNavigatorKey: rootNavigatorKey, builder: (context, state) => _page(OnboardingRoutes.title, OnboardingRoutes.description)),
    GoRoute(path: ProfileRoutes.path, parentNavigatorKey: rootNavigatorKey, builder: (context, state) => _page(ProfileRoutes.title, ProfileRoutes.description)),
    GoRoute(path: SettingsRoutes.path, parentNavigatorKey: rootNavigatorKey, builder: (context, state) => _page(SettingsRoutes.title, SettingsRoutes.description)),
  ],
);
