import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../state/state.dart';
import 'onboarding_progress_indicator.dart';

class OnboardingTopBar extends StatelessWidget {
  const OnboardingTopBar({
    required this.state,
    super.key,
    this.onBack,
    this.showProgress = true,
  });

  final OnboardingState state;
  final VoidCallback? onBack;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.tioColors.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TioSpacing.small,
          TioSpacing.small,
          TioSpacing.extraLarge,
          TioSpacing.small,
        ),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  tooltip: 'Back',
                  onPressed: state.isBusy ? null : onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
              if (showProgress)
                Expanded(
                  child: OnboardingProgressIndicator(state: state),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
