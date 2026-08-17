import 'package:tio_shared/shared.dart';

import '../../../../routing/routes/feature_routes.dart';
import '../../../../routing/routes/route_contract.dart';

enum ShellTab {
  home,
  nutrition,
  ai,
  workout,
  progress;

  String get label {
    switch (this) {
      case ShellTab.home:
        return 'Home';
      case ShellTab.nutrition:
        return 'Nutrition';
      case ShellTab.ai:
        return 'AI';
      case ShellTab.workout:
        return 'Workout';
      case ShellTab.progress:
        return 'Progress';
    }
  }

  int get branchIndex {
    return shellBranchRegistry.indexWhere((branch) => branch.tab == this);
  }

  static ShellTab fromBranchIndex(int index) {
    if (index < 0 || index >= shellBranchRegistry.length) return ShellTab.home;
    return shellBranchRegistry[index].tab;
  }

  TioRouteContract get route => shellBranchRegistry[branchIndex].route;

  static ShellTab fromDestination(AppDestination destination) {
    return switch (destination) {
      AppDestination.home => ShellTab.home,
      AppDestination.workout => ShellTab.workout,
      AppDestination.nutrition => ShellTab.nutrition,
      AppDestination.progress => ShellTab.progress,
    };
  }
}

const missingModeCompatibilityShellTabs = <ShellTab>[
  ShellTab.home,
  ShellTab.workout,
  ShellTab.nutrition,
  ShellTab.progress,
];

class ShellBranchDefinition {
  const ShellBranchDefinition({required this.tab, required this.route});

  final ShellTab tab;
  final TioRouteContract route;
}

const shellBranchRegistry = <ShellBranchDefinition>[
  ShellBranchDefinition(tab: ShellTab.home, route: FeatureRoutes.home),
  ShellBranchDefinition(
      tab: ShellTab.nutrition, route: FeatureRoutes.nutrition),
  ShellBranchDefinition(tab: ShellTab.ai, route: FeatureRoutes.ai),
  ShellBranchDefinition(tab: ShellTab.workout, route: FeatureRoutes.workout),
  ShellBranchDefinition(tab: ShellTab.progress, route: FeatureRoutes.progress),
];

enum ShellPlanTier {
  free,
  plus,
  premium;

  String get label => switch (this) {
        ShellPlanTier.free => 'Get Pro',
        ShellPlanTier.plus => 'Plus',
        ShellPlanTier.premium => 'Pro',
      };
}

class ShellUiState {
  const ShellUiState({
    required this.visibleTabs,
    this.selectedTab = ShellTab.home,
    this.isBottomNavVisible = true,
    this.isRootTopBarVisible = true,
    this.appBarOpacity = 0,
    this.planTier = ShellPlanTier.free,
    this.workoutStreakDays,
    this.mealLogStreakDays,
    this.userName,
    this.avatarUrl,
  })  : assert(workoutStreakDays == null || workoutStreakDays >= 0),
        assert(mealLogStreakDays == null || mealLogStreakDays >= 0);

  final ShellTab selectedTab;
  final List<ShellTab> visibleTabs;
  final bool isBottomNavVisible;
  final bool isRootTopBarVisible;
  final double appBarOpacity;
  final ShellPlanTier planTier;
  final int? workoutStreakDays;
  final int? mealLogStreakDays;
  final String? userName;
  final String? avatarUrl;
}
