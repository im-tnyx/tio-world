import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/app_mode/app_mode.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('guidedShellTabs', () {
    test('maps modes to visible tabs without using visible indexes', () {
      expect(
        guidedShellTabs(AppMode.workout),
        const [ShellTab.home, ShellTab.workout, ShellTab.progress],
      );
      expect(
        guidedShellTabs(AppMode.nutrition),
        const [ShellTab.home, ShellTab.nutrition, ShellTab.progress],
      );
      expect(
        guidedShellTabs(AppMode.hybrid),
        const [
          ShellTab.home,
          ShellTab.workout,
          ShellTab.nutrition,
          ShellTab.progress
        ],
      );
    });
  });

  group('appModeRedirect', () {
    test('requires onboarding before mode-owned routes', () {
      expect(
        appModeRedirect(path: FeatureRoutes.home.path, selectedMode: null),
        AppRoutes.onboarding.path,
      );
      expect(
        appModeRedirect(path: AppRoutes.settings.path, selectedMode: null),
        AppRoutes.onboarding.path,
      );
      expect(
        appModeRedirect(path: AppRoutes.auth.path, selectedMode: null),
        isNull,
      );
    });

    test('keeps only workout guided routes in workout mode', () {
      expect(
        appModeRedirect(
            path: FeatureRoutes.workout.path, selectedMode: AppMode.workout),
        isNull,
      );
      expect(
        appModeRedirect(
            path: FeatureRoutes.nutrition.path, selectedMode: AppMode.workout),
        FeatureRoutes.home.path,
      );
    });

    test('keeps only nutrition guided routes in nutrition mode', () {
      expect(
        appModeRedirect(
            path: FeatureRoutes.nutrition.path,
            selectedMode: AppMode.nutrition),
        isNull,
      );
      expect(
        appModeRedirect(
            path: FeatureRoutes.workout.path, selectedMode: AppMode.nutrition),
        FeatureRoutes.home.path,
      );
    });

    test('allows both feature routes in hybrid mode and defers Coach', () {
      expect(
        appModeRedirect(
            path: FeatureRoutes.workout.path, selectedMode: AppMode.hybrid),
        isNull,
      );
      expect(
        appModeRedirect(
            path: FeatureRoutes.nutrition.path, selectedMode: AppMode.hybrid),
        isNull,
      );
      expect(
        appModeRedirect(
            path: FeatureRoutes.ai.path, selectedMode: AppMode.hybrid),
        FeatureRoutes.home.path,
      );
    });

    test('leaves onboarding after a mode exists', () {
      expect(
        appModeRedirect(
            path: AppRoutes.onboarding.path, selectedMode: AppMode.hybrid),
        FeatureRoutes.home.path,
      );
    });
  });
}
