import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

List<ShellTab> shellTabsForDestinations(
  Iterable<AppDestination> destinations,
) {
  return destinations
      .map(ShellTab.fromDestination)
      .toList(growable: false);
}

List<ShellTab> guidedShellTabs(AppMode mode) {
  return shellTabsForDestinations(mode.guidedDestinations);
}

/// The main tab root that owns [path]: the path itself for a tab root, the
/// root for a destination nested inside that tab (such as
/// `/workout/exercises`), otherwise [path] unchanged.
///
/// Nested destinations follow their tab's onboarding and App Mode gating, so
/// a deep link cannot reach a screen whose tab the current mode hides.
String _owningShellPath(String path) {
  for (final branch in shellBranchRegistry) {
    final root = branch.route.path;
    if (path == root) return root;
    if (root != '/' && path.startsWith('$root/')) return root;
  }
  return path;
}

String? appModeRedirect({
  required String path,
  required AppMode? selectedMode,
  required OnboardingStatus onboardingStatus,
  List<AppDestination>? activeDestinations,
}) {
  final shellPath = _owningShellPath(path);

  final modeRequiredPaths = <String>{
    FeatureRoutes.home.path,
    FeatureRoutes.workout.path,
    FeatureRoutes.nutrition.path,
    FeatureRoutes.ai.path,
    FeatureRoutes.progress.path,
    AppRoutes.profile.path,
    AppRoutes.profileAvatar.path,
    AppRoutes.settings.path,
    AppRoutes.appSettings.path,
    AppRoutes.appModeSettings.path,
    AppRoutes.themeSettings.path,
    AppRoutes.calendarSettings.path,
  };

  final onboardingComplete = onboardingStatus == OnboardingStatus.completed;

  if (!onboardingComplete) {
    return modeRequiredPaths.contains(shellPath)
        ? AppRoutes.onboarding.path
        : null;
  }

  if (shellPath == AppRoutes.onboarding.path) return FeatureRoutes.home.path;

  final isShellPath =
      shellBranchRegistry.any((branch) => branch.route.path == shellPath);

  if (selectedMode == null) {
    final compatibilityPaths = missingModeCompatibilityShellTabs
        .map((tab) => tab.route.path)
        .toSet();
    if (isShellPath && !compatibilityPaths.contains(shellPath)) {
      return FeatureRoutes.home.path;
    }
    return null;
  }

  final effectiveDestinations =
      activeDestinations ?? selectedMode.guidedDestinations;
  final allowedTabs = shellTabsForDestinations(effectiveDestinations);
  final allowedPaths = allowedTabs.map((tab) => tab.route.path).toSet();
  final fallbackPath = allowedTabs.isEmpty
      ? FeatureRoutes.home.path
      : allowedTabs.first.route.path;

  if (isShellPath && !allowedPaths.contains(shellPath)) {
    return fallbackPath;
  }

  return null;
}
