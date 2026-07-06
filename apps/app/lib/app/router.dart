import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../shared/widgets/placeholder_page.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouter = GoRouter(
  initialLocation: '/',
  navigatorKey: rootNavigatorKey,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/', builder: (context, state) => const PlaceholderPage(title: 'Dashboard', description: 'Your daily health and fitness overview.'))]),
        StatefulShellBranch(routes: [GoRoute(path: '/workout', builder: (context, state) => const PlaceholderPage(title: 'Workout', description: 'Track your exercises and follow workout plans.'))]),
        StatefulShellBranch(routes: [GoRoute(path: '/nutrition', builder: (context, state) => const PlaceholderPage(title: 'Nutrition', description: 'Log your meals and monitor your macros.'))]),
        StatefulShellBranch(routes: [GoRoute(path: '/coach', builder: (context, state) => const PlaceholderPage(title: 'AI Coach', description: 'Get personalized guidance and answers to your questions.'))]),
        StatefulShellBranch(routes: [GoRoute(path: '/progress', builder: (context, state) => const PlaceholderPage(title: 'Progress', description: 'Visualize your journey and achievements.'))]),
      ],
    ),
    GoRoute(path: '/profile', parentNavigatorKey: rootNavigatorKey, builder: (context, state) => const PlaceholderPage(title: 'Profile', description: 'Manage your personal information and health data.')),
    GoRoute(path: '/settings', parentNavigatorKey: rootNavigatorKey, builder: (context, state) => const PlaceholderPage(title: 'Settings', description: 'Configure your app preferences and notifications.')),
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
            onPressed: () => context.push('/profile'),
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
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center_outlined), activeIcon: Icon(Icons.fitness_center), label: 'Workout'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_outlined), activeIcon: Icon(Icons.restaurant), label: 'Nutrition'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), activeIcon: Icon(Icons.smart_toy), label: 'Coach'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Progress'),
        ],
      ),
    );
  }
}
