import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../state/state.dart';
import 'onboarding_progress_indicator.dart';

class OnboardingTopBar extends StatelessWidget {
  const OnboardingTopBar({
    required this.state,
    super.key,
    this.onExitRequested,
  });

  final OnboardingState state;
  final VoidCallback? onExitRequested;

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
                Expanded(
                  child: Text(
                    'Set up Tio',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (onExitRequested != null)
                  IconButton(
                    tooltip: 'Exit setup',
                    onPressed: state.isBusy ? null : onExitRequested,
                    icon: const Icon(Icons.close),
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
