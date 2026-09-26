import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

List<RouteBase> buildOnboardingRoutes({
  required GlobalKey<NavigatorState> rootNavigatorKey,
  required OnboardingControllerSeed Function() seed,
  required Future<void> Function() onExitRequested,
  required Future<bool> Function(BuildContext context) onAuthRequired,
  required Future<void> Function(
    BuildContext context,
    OnboardingDraft draft,
  ) onFinishRequested,
  required void Function(BuildContext context) onCongratulationsContinue,
}) {
  return [
    GoRoute(
      path: AppRoutes.onboarding.path,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => OnboardingFlowPage(
        seed: seed(),
        onExitRequested: onExitRequested,
        onAuthRequired: () => onAuthRequired(context),
        onFinishRequested: (draft) => onFinishRequested(context, draft),
      ),
    ),
    GoRoute(
      path: AppRoutes.congratulations.path,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final userName = extra?['userName'] as String?;
        final isWelcomeBack = extra?['isWelcomeBack'] as bool? ?? false;
        return CongratulationsScreen(
          userName: userName,
          isWelcomeBack: isWelcomeBack,
          onContinue: () => onCongratulationsContinue(context),
        );
      },
    ),
  ];
}
