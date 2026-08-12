import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../controllers/controllers.dart';
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
    required this.stepBuilder,
    super.key,
  });

  final OnboardingState state;
  final OnboardingController controller;
  final OnboardingStepBuilder stepBuilder;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      child: AnimatedSwitcher(
        duration: context.tioMotion.normal,
        child: SingleChildScrollView(
          key: ValueKey(state.stepId),
          padding: const EdgeInsets.fromLTRB(
            TioSpacing.extraLarge,
            TioSpacing.large,
            TioSpacing.extraLarge,
            TioSpacing.extraLarge,
          ),
          child: stepBuilder(context, state, controller),
        ),
      ),
    );
  }
}
