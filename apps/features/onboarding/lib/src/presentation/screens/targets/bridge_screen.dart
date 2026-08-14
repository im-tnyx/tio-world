import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'targets_screen_components.dart';

class BridgeScreen extends StatelessWidget {
  const BridgeScreen({
    super.key,
    this.errorText,
  });

  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return TargetsScreenScaffold(
      stepId: TargetStepId.bridge,
      title: 'Building your targets',
      description:
          'Based on your profile and preferences, we are preparing daily targets tailored to your lifestyle.',
      errorText: errorText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withValues(alpha: 0.08),
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 40,
                color: colors.primary,
              ),
            ),
          ),
          const SizedBox(height: TioSpacing.extraLarge),
          TioCard(
            key: const ValueKey('targets-bridge-card'),
            variant: TioCardVariant.outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tune,
                      color: colors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: TioSpacing.small),
                    Text(
                      'Personalized & Flexible',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: TioSpacing.small),
                Text(
                  'In the next steps, you can fine-tune your daily steps, sleep duration, and water intake targets to match what works best for you.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
