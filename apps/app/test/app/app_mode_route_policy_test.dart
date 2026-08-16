import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/app_mode/app_mode.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('guidedShellTabs', () {
    test('keeps branch index and route identity in one canonical registry', () {
      expect(shellBranchRegistry.map((branch) => branch.tab).toSet(),
          ShellTab.values.toSet());
      expect(shellBranchRegistry.map((branch) => branch.route.path).toSet(),
          hasLength(shellBranchRegistry.length));

      for (var index = 0; index < shellBranchRegistry.length; index++) {
        final branch = shellBranchRegistry[index];
        expect(branch.tab.branchIndex, index);
        expect(ShellTab.fromBranchIndex(index), branch.tab);
        expect(branch.tab.route, same(branch.route));
      }
    });

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
      expect(
        missingModeCompatibilityTabs,
        const [
          ShellTab.home,
          ShellTab.workout,
          ShellTab.nutrition,
          ShellTab.progress,
        ],
      );
    });
  });

  group('appModeRedirect', () {
    test('requires onboarding before mode-owned routes when not started', () {
      expect(
        appModeRedirect(
          path: FeatureRoutes.home.path,
          selectedMode: null,
          onboardingStatus: OnboardingStatus.notStarted,
        ),
        AppRoutes.onboarding.path,
      );
      expect(
        appModeRedirect(
          path: AppRoutes.settings.path,
          selectedMode: null,
          onboardingStatus: OnboardingStatus.notStarted,
        ),
        AppRoutes.onboarding.path,
      );
      expect(
        appModeRedirect(
          path: AppRoutes.appSettings.path,
          selectedMode: null,
          onboardingStatus: OnboardingStatus.notStarted,
        ),
        AppRoutes.onboarding.path,
      );
      expect(
        appModeRedirect(
          path: AppRoutes.appModeSettings.path,
          selectedMode: null,
          onboardingStatus: OnboardingStatus.notStarted,
        ),
        AppRoutes.onboarding.path,
      );
      expect(
        appModeRedirect(
          path: AppRoutes.themeSettings.path,
          selectedMode: null,
          onboardingStatus: OnboardingStatus.notStarted,
        ),
        AppRoutes.onboarding.path,
      );
      expect(
        appModeRedirect(
          path: AppRoutes.profileAvatar.path,
          selectedMode: null,
          onboardingStatus: OnboardingStatus.notStarted,
        ),
        AppRoutes.onboarding.path,
      );
      expect(
        appModeRedirect(
          path: AppRoutes.auth.path,
          selectedMode: null,
          onboardingStatus: OnboardingStatus.notStarted,
        ),
        isNull,
      );
    });

    test('requires onboarding while in progress even if no confirmed mode exists',
        () {
      expect(
        appModeRedirect(
          path: FeatureRoutes.home.path,
          selectedMode: null,
          onboardingStatus: OnboardingStatus.inProgress,
        ),
        AppRoutes.onboarding.path,
      );
      expect(
        appModeRedirect(
          path: AppRoutes.onboarding.path,
          selectedMode: null,
          onboardingStatus: OnboardingStatus.inProgress,
        ),
        isNull,
      );
    });

    test('keeps only workout guided routes after explicit completion', () {
      expect(
        appModeRedirect(
          path: FeatureRoutes.workout.path,
          selectedMode: AppMode.workout,
          onboardingStatus: OnboardingStatus.completed,
        ),
        isNull,
      );
      expect(
        appModeRedirect(
          path: FeatureRoutes.nutrition.path,
          selectedMode: AppMode.workout,
          onboardingStatus: OnboardingStatus.completed,
        ),
        FeatureRoutes.home.path,
      );
    });

    test('keeps only nutrition guided routes after explicit completion', () {
      expect(
        appModeRedirect(
          path: FeatureRoutes.nutrition.path,
          selectedMode: AppMode.nutrition,
          onboardingStatus: OnboardingStatus.completed,
        ),
        isNull,
      );
      expect(
        appModeRedirect(
          path: FeatureRoutes.workout.path,
          selectedMode: AppMode.nutrition,
          onboardingStatus: OnboardingStatus.completed,
        ),
        FeatureRoutes.home.path,
      );
    });

    test('allows both feature routes in hybrid mode and defers Coach', () {
      expect(
        appModeRedirect(
          path: FeatureRoutes.workout.path,
          selectedMode: AppMode.hybrid,
          onboardingStatus: OnboardingStatus.completed,
        ),
        isNull,
      );
      expect(
        appModeRedirect(
          path: FeatureRoutes.nutrition.path,
          selectedMode: AppMode.hybrid,
          onboardingStatus: OnboardingStatus.completed,
        ),
        isNull,
      );
      expect(
        appModeRedirect(
          path: FeatureRoutes.ai.path,
          selectedMode: AppMode.hybrid,
          onboardingStatus: OnboardingStatus.completed,
        ),
        FeatureRoutes.home.path,
      );
    });

    test('leaves onboarding only after explicit completion', () {
      expect(
        appModeRedirect(
          path: AppRoutes.onboarding.path,
          selectedMode: AppMode.hybrid,
          onboardingStatus: OnboardingStatus.completed,
        ),
        FeatureRoutes.home.path,
      );
      expect(
        appModeRedirect(
          path: AppRoutes.onboarding.path,
          selectedMode: AppMode.hybrid,
          onboardingStatus: OnboardingStatus.inProgress,
        ),
        isNull,
      );
    });

    test('completed without confirmed mode keeps compatibility tabs accessible',
        () {
      for (final tab in missingModeCompatibilityTabs) {
        expect(
          appModeRedirect(
            path: tab.route.path,
            selectedMode: null,
            onboardingStatus: OnboardingStatus.completed,
          ),
          isNull,
        );
      }

      expect(
        appModeRedirect(
          path: AppRoutes.settings.path,
          selectedMode: null,
          onboardingStatus: OnboardingStatus.completed,
        ),
        isNull,
      );
      expect(
        appModeRedirect(
          path: FeatureRoutes.ai.path,
          selectedMode: null,
          onboardingStatus: OnboardingStatus.completed,
        ),
        FeatureRoutes.home.path,
      );
    });
  });
}
