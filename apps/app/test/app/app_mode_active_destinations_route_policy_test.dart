import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/app_mode/app_mode.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  test('maps canonical active destinations without changing their order', () {
    expect(
      shellTabsForDestinations(const [
        AppDestination.progress,
        AppDestination.home,
        AppDestination.nutrition,
      ]),
      const [
        ShellTab.progress,
        ShellTab.home,
        ShellTab.nutrition,
      ],
    );
  });

  test('completed routing honors restored active destinations over guided mode',
      () {
    const restoredTabs = <AppDestination>[
      AppDestination.progress,
      AppDestination.home,
      AppDestination.workout,
    ];

    expect(
      appModeRedirect(
        path: FeatureRoutes.workout.path,
        selectedMode: AppMode.hybrid,
        activeDestinations: restoredTabs,
        onboardingStatus: OnboardingStatus.completed,
      ),
      isNull,
    );
    expect(
      appModeRedirect(
        path: FeatureRoutes.nutrition.path,
        selectedMode: AppMode.hybrid,
        activeDestinations: restoredTabs,
        onboardingStatus: OnboardingStatus.completed,
      ),
      FeatureRoutes.progress.path,
    );
  });

  test('missing canonical mode keeps completed compatibility navigation', () {
    for (final tab in missingModeCompatibilityShellTabs) {
      expect(
        appModeRedirect(
          path: tab.route.path,
          selectedMode: null,
          activeDestinations: null,
          onboardingStatus: OnboardingStatus.completed,
        ),
        isNull,
      );
    }
  });
}
