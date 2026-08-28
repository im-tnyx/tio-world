import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/app_mode/app_mode.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('O9D completion routing policy', () {
    test('Congratulations remains reachable before in-memory completion publish', () {
      expect(
        appModeRedirect(
          path: AppRoutes.congratulations.path,
          selectedMode: AppMode.hybrid,
          onboardingStatus: OnboardingStatus.inProgress,
        ),
        isNull,
      );
    });

    test('Congratulations remains reachable after completion publish', () {
      expect(
        appModeRedirect(
          path: AppRoutes.congratulations.path,
          selectedMode: AppMode.hybrid,
          onboardingStatus: OnboardingStatus.completed,
        ),
        isNull,
      );
    });

    test('stale completed onboarding route still falls through to Home', () {
      expect(
        appModeRedirect(
          path: AppRoutes.onboarding.path,
          selectedMode: AppMode.hybrid,
          onboardingStatus: OnboardingStatus.completed,
        ),
        FeatureRoutes.home.path,
      );
    });
  });
}
