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

    return FocusTraversalGroup(
      child: AnimatedSwitcher(
        duration: context.tioMotion.fadeThroughEnter,
        reverseDuration: context.tioMotion.fadeThroughExit,
        transitionBuilder: _buildReferenceTransition,
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.topLeft,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        ),
        child: SingleChildScrollView(
          key: ValueKey(
            state.stepId == OnboardingStepId.profileBasics
                ? '${state.stepId.name}-${state.draft.profile.currentStepId.name}'
                : state.stepId.name,
          ),
          padding: const EdgeInsets.fromLTRB(
            TioSpacing.extraLarge,
            TioSpacing.large,
            TioSpacing.extraLarge,
            TioSpacing.extraLarge,
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
            1,
            curve: Curves.fastOutSlowIn,
          ),
        );

        return FadeTransition(
          opacity: delayedEnter,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(delayedEnter),
            child: child,
          ),
        );
      },
      reverseBuilder: (context, exitAnimation, child) => FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0).animate(
          CurvedAnimation(
            parent: exitAnimation,
            curve: Curves.fastOutSlowIn,
          ),
        ),
        child: child,
      ),
      child: child,
    );
  }
}
