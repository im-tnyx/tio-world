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

TioPlaceholderPage _page(String title, String description) {
  return TioPlaceholderPage(title: title, description: description);
}

final goRouter = GoRouter(
  initialLocation: '/',
  navigatorKey: rootNavigatorKey,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/', builder: (context, state) => _page('Dashboard', 'Your daily health and fitness overview.'))]),
        StatefulShellBranch(routes: [GoRoute(path: WorkoutRoutes.path, builder: (context, state) => _page(WorkoutRoutes.title, WorkoutRoutes.description))]),
        StatefulShellBranch(routes: [GoRoute(path: NutritionRoutes.path, builder: (context, state) => _page(NutritionRoutes.title, NutritionRoutes.description))]),
        StatefulShellBranch(routes: [GoRoute(path: CoachingRoutes.path, builder: (context, state) => _page(CoachingRoutes.title, CoachingRoutes.description))]),
        StatefulShellBranch(routes: [GoRoute(path: ProgressRoutes.path, builder: (context, state) => _page(ProgressRoutes.title, ProgressRoutes.description))]),
      ],
    ),
    GoRoute(path: AuthRoutes.path, parentNavigatorKey: rootNavigatorKey, builder: (context, state) => _page(AuthRoutes.title, AuthRoutes.description)),
    GoRoute(path: OnboardingRoutes.path, parentNavigatorKey: rootNavigatorKey, builder: (context, state) => _page(OnboardingRoutes.title, OnboardingRoutes.description)),
    GoRoute(path: ProfileRoutes.path, parentNavigatorKey: rootNavigatorKey, builder: (context, state) => _page(ProfileRoutes.title, ProfileRoutes.description)),
    GoRoute(path: SettingsRoutes.path, parentNavigatorKey: rootNavigatorKey, builder: (context, state) => _page(SettingsRoutes.title, SettingsRoutes.description)),
  ],
);

class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tio'),
        actions: [
          IconButton(
            icon: const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 16)),
            onPressed: () => context.push(ProfileRoutes.path),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center_outlined), activeIcon: Icon(Icons.fitness_center), label: WorkoutRoutes.title),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_outlined), activeIcon: Icon(Icons.restaurant), label: NutritionRoutes.title),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), activeIcon: Icon(Icons.smart_toy), label: 'Coach'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: ProgressRoutes.title),
        ],
      ),
    );
  }
}
