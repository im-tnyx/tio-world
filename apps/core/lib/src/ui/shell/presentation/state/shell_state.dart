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

  static ShellTab fromIndex(int index) {
    if (index < 0 || index >= ShellTab.values.length) return ShellTab.home;
    return ShellTab.values[index];
  }
}

enum ShellPlanTier { free, plus, premium }

class ShellUiState {
  const ShellUiState({
    this.selectedTab = ShellTab.home,
    this.isBottomNavVisible = true,
    this.appBarOpacity = 0,
    this.planTier = ShellPlanTier.free,
  });

  final ShellTab selectedTab;
  final bool isBottomNavVisible;
  final double appBarOpacity;
  final ShellPlanTier planTier;
}
