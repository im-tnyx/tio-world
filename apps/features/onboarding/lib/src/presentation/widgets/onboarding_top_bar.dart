import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../state/state.dart';
import 'onboarding_progress_indicator.dart';

class OnboardingTopBar extends StatelessWidget {
  const OnboardingTopBar({
    required this.state,
    super.key,
    this.onBack,
  });

  final OnboardingState state;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.tioColors.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TioSpacing.extraLarge,
          TioSpacing.medium,
          TioSpacing.extraLarge,
          TioSpacing.large,
        ),
        child: Column(
          children: [
            Row(
              children: [
                if (onBack != null)
                  IconButton(
                    tooltip: 'Back',
                    onPressed: state.isBusy ? null : onBack,
                    icon: const Icon(Icons.arrow_back),
                  ),
                Expanded(
                  child: Text(
                    'Set up Tio',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TioSpacing.medium),
            OnboardingProgressIndicator(state: state),
          ],
        ),
      ),
    );
  }
}
