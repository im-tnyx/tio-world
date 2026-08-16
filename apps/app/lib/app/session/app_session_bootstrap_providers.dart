import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network_providers.dart';
import '../onboarding/onboarding.dart';
import 'app_session_bootstrap_controller.dart';

final appSessionBootstrapControllerProvider =
    ChangeNotifierProvider<AppSessionBootstrapController>((ref) {
  final controller = AppSessionBootstrapController(
    authSessionRepository: ref.watch(authSessionRepositoryProvider),
    onboardingCompletionRepository:
        ref.watch(onboardingCompletionRepositoryProvider),
    onboardingStatusController: ref.watch(onboardingStatusControllerProvider),
  );
  controller.start();
  return controller;
});
