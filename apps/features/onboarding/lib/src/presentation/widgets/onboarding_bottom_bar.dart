import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../domain/domain.dart';
import '../state/state.dart';

class OnboardingBottomBar extends StatelessWidget {
  const OnboardingBottomBar({
    required this.state,
    required this.onBack,
    required this.onContinue,
    super.key,
  });

  final OnboardingState state;
  final VoidCallback onBack;
  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.tioColors.surface,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.all(TioSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.retryableError != null) ...[
              Text(
                'Could not finish setup. Please try again.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
              const SizedBox(height: TioSpacing.medium),
            ],
            Row(
              children: [
                if (state.canGoBack) ...[
                  TioButton.ghost(
                    label: 'Back',
                    onPressed: onBack,
                    leading: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: TioSpacing.medium),
                ],
                Expanded(
                  child: TioButton.primary(
                    label: state.primaryActionLabel,
                    loading: state.isCompleting || state.isSaving,
                    loadingLabel: state.isCompleting ? 'Finishing' : 'Saving',
                    expand: true,
                    enabled: state.canContinue,
                    onPressed: () => unawaited(onContinue()),
                    trailing: state.stepId == OnboardingStepId.review
                        ? const Icon(Icons.check)
                        : const Icon(Icons.arrow_forward),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
