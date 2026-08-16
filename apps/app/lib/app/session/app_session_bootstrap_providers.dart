import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network_providers.dart';
import '../onboarding/onboarding.dart';
import 'app_session_bootstrap_controller.dart';

final appSessionBootstrapControllerProvider =
    ChangeNotifierProvider<AppSessionBootstrapController>((ref) {
  // The bootstrap controller owns the auth-session subscription and must remain
  // stable for the ProviderScope lifetime. In particular,
  // OnboardingStatusController.reconcileRemote() notifies its listeners; using
  // ref.watch here would rebuild/dispose the bootstrap controller from inside
  // its own in-flight reconciliation and leave Splash stuck in Loading.
  final controller = AppSessionBootstrapController(
    authSessionRepository: ref.read(authSessionRepositoryProvider),
    onboardingCompletionRepository:
        ref.read(onboardingCompletionRepositoryProvider),
    onboardingStatusController: ref.read(onboardingStatusControllerProvider),
  );
  controller.start();
  return controller;
});
