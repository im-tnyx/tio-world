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
          TioSpacing.sm,
          0,
          TioSpacing.lg,
          0,
        ),
        child: SizedBox(
          height: TioSize.dp48,
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  tooltip: 'Back',
                  onPressed: state.isBusy ? null : onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
              const SizedBox(width: TioSpacing.sm),
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
