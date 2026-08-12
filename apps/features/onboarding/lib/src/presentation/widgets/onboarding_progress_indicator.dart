import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../state/state.dart';

class OnboardingProgressIndicator extends StatelessWidget {
  const OnboardingProgressIndicator({required this.state, super.key});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: state.progressSemantics,
      readOnly: true,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.currentStep.progressTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: TioSpacing.small),
            LinearProgressIndicator(
              value: state.progressValue,
              minHeight: 6,
              borderRadius: BorderRadius.circular(context.radiusSmall),
              backgroundColor: context.tioColors.surfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
