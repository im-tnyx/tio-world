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
}

enum AppDestination {
  home,
  workout,
  nutrition,
  progress,
}
