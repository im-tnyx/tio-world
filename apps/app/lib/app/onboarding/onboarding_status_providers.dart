import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'onboarding_status_controller.dart';

final onboardingStatusControllerProvider =
    ChangeNotifierProvider<OnboardingStatusController>((ref) {
  throw StateError(
    'OnboardingStatusController must be overridden at the app composition boundary.',
  );
});
