import 'package:tio_shared/shared.dart';

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
    return switch (this) {
      ShellTab.home => 0,
      ShellTab.nutrition => 1,
      ShellTab.ai => 2,
      ShellTab.workout => 3,
      ShellTab.progress => 4,
    };
  }

  static ShellTab fromBranchIndex(int index) {
    return switch (index) {
      1 => ShellTab.nutrition,
      2 => ShellTab.ai,
      3 => ShellTab.workout,
      4 => ShellTab.progress,
      _ => ShellTab.home,
    };
  }

  static ShellTab fromDestination(AppDestination destination) {
    return switch (destination) {
      AppDestination.home => ShellTab.home,
      AppDestination.workout => ShellTab.workout,
      AppDestination.nutrition => ShellTab.nutrition,
      AppDestination.progress => ShellTab.progress,
    };
  }
}

enum ShellPlanTier { free, plus, premium }

class ShellUiState {
  const ShellUiState({
    required this.visibleTabs,
    this.selectedTab = ShellTab.home,
    this.isBottomNavVisible = true,
    this.appBarOpacity = 0,
    this.planTier = ShellPlanTier.free,
  });

  final ShellTab selectedTab;
  final List<ShellTab> visibleTabs;
  final bool isBottomNavVisible;
  final double appBarOpacity;
  final ShellPlanTier planTier;
}
