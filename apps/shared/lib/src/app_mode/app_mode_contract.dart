enum AppMode {
  workout,
  nutrition,
  hybrid;

  String get storageValue => name;

  static AppMode? fromStorageValue(String? value) {
    if (value == null) return null;

    for (final mode in AppMode.values) {
      if (mode.storageValue == value) return mode;
    }

    return null;
  }

  /// Phone App Guided Destinations / Bottom Navigation Tabs
  List<AppDestination> get guidedDestinations {
    return switch (this) {
      AppMode.workout => const [
          AppDestination.home,
          AppDestination.workout,
          AppDestination.progress,
        ],
      AppMode.nutrition => const [
          AppDestination.home,
          AppDestination.nutrition,
          AppDestination.progress,
        ],
      AppMode.hybrid => const [
          AppDestination.home,
          AppDestination.workout,
          AppDestination.nutrition,
          AppDestination.progress,
        ],
    };
  }

  /// Watch (Wear OS / Apple Watch) Home Screen Cards & Tiles
  List<WatchCardType> get watchCards {
    return switch (this) {
      AppMode.workout => const [
          WatchCardType.activeWorkout,
          WatchCardType.heartRateRestTimer,
          WatchCardType.workoutHistory,
        ],
      AppMode.nutrition => const [
          WatchCardType.caloriesMacros,
          WatchCardType.quickWaterLog,
          WatchCardType.dailyActivitySummary,
        ],
      AppMode.hybrid => const [
          WatchCardType.activeWorkout,
          WatchCardType.caloriesMacros,
          WatchCardType.quickWaterLog,
          WatchCardType.dailyActivitySummary,
        ],
    };
  }
}

enum AppDestination {
  home,
  workout,
  nutrition,
  progress;

  /// Stable storage identifier used by `user_app_preferences.active_tabs`.
  String get storageValue => name;

  static AppDestination? fromStorageValue(String? value) {
    if (value == null) return null;

    for (final destination in AppDestination.values) {
      if (destination.storageValue == value) return destination;
    }

    return null;
  }
}

enum WatchCardType {
  activeWorkout,
  heartRateRestTimer,
  workoutHistory,
  caloriesMacros,
  quickWaterLog,
  dailyActivitySummary;

  String get label => switch (this) {
        WatchCardType.activeWorkout => 'Active Workout Launcher',
        WatchCardType.heartRateRestTimer => 'Heart Rate & Rest Timer',
        WatchCardType.workoutHistory => 'Recent Routine & Logs',
        WatchCardType.caloriesMacros => 'Calorie & Macro Ring',
        WatchCardType.quickWaterLog => 'Quick Water Logger (+250ml)',
        WatchCardType.dailyActivitySummary => 'Daily Activity & Burn',
      };
}
