import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../state/state.dart';
import '../theme/onboarding_visual_tokens.dart';

class OnboardingProgressIndicator extends StatelessWidget {
  const OnboardingProgressIndicator({required this.state, super.key});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: state.progressSemantics,
      readOnly: true,
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: state.progressValue),
          duration: context.tioMotion.progress,
          curve: Curves.linearToEaseOut,
          builder: (context, progress, _) => LinearProgressIndicator(
            value: progress,
            minHeight: OnboardingVisualTokens.progressThickness,
            borderRadius: BorderRadius.circular(TioRadius.small),
            backgroundColor: context.tioColors.surfaceVariant,
          ),
        ),
      ),
    );
  }
}
