import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../domain/domain.dart';
import '../controllers/controllers.dart';
import '../renderer/onboarding_section_renderer.dart';
import '../state/state.dart';

typedef OnboardingStepBuilder = Widget Function(
  BuildContext context,
  OnboardingState state,
  OnboardingController controller,
);

class OnboardingContentHost extends StatelessWidget {
  const OnboardingContentHost({
    required this.state,
    required this.controller,
    super.key,
    this.stepBuilder,
  });

  final OnboardingState state;
  final OnboardingController controller;
  final OnboardingStepBuilder? stepBuilder;

  static const _enterDelayFraction =
      TioMotion.fadeThroughExitMs / TioMotion.fadeThroughEnterMs;

  @override
  Widget build(BuildContext context) {
    final child = stepBuilder?.call(context, state, controller) ??
        OnboardingSectionRenderer(state: state, controller: controller);

    final String stepKey = state.stepId == OnboardingStepId.profileBasics
        ? '${state.stepId.name}-${state.draft.profile.currentStepId.name}'
        : state.stepId.name;

    return FocusTraversalGroup(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: TioMotion.fadeThroughEnterMs),
        reverseDuration: const Duration(milliseconds: TioMotion.fadeThroughExitMs),
        transitionBuilder: _buildReferenceTransition,
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.topLeft,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        ),
        child: SingleChildScrollView(
          key: ValueKey(stepKey),
          padding: const EdgeInsets.fromLTRB(
            TioSpacing.large,
            TioSpacing.large,
            TioSpacing.large,
            TioSpacing.large,
          ),
          child: child,
        ),
      ),
    );
  }

  static Widget _buildReferenceTransition(
    Widget child,
    Animation<double> animation,
  ) {
    return DualTransitionBuilder(
      animation: animation,
      forwardBuilder: (context, enterAnimation, child) {
        final delayedEnter = CurvedAnimation(
          parent: enterAnimation,
          curve: const Interval(
            _enterDelayFraction,
            1.0,
            curve: Curves.easeOutCubic,
          ),
        );
        return FadeTransition(
          opacity: delayedEnter,
          child: child,
        );
      },
      reverseBuilder: (context, exitAnimation, child) {
        final fastExit = CurvedAnimation(
          parent: exitAnimation,
          curve: const Interval(
            0.0,
            _enterDelayFraction,
            curve: Curves.easeInCubic,
          ),
        );
        return FadeTransition(
          opacity: Tween<double>(begin: 1.0, end: 0.0).animate(fastExit),
          child: child,
        );
      },
      child: child,
    );
  }
}
