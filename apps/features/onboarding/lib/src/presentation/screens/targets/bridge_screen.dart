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
    final colors = TioTheme.colors(context);
    final textTheme = Theme.of(context).textTheme;

    return TargetsScreenScaffold(
      stepId: TargetStepId.bridge,
      title: 'Building your targets',
      description:
          'Based on your profile, we are preparing daily targets tailored to your lifestyle and goals.',
      errorText: errorText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BridgeHighlightRow(
            icon: Icons.directions_walk_outlined,
            title: 'Daily Activity & Steps',
            description:
                'Smart baseline step targets to keep your daily energy expenditure consistent.',
            colors: colors,
            textTheme: textTheme,
          ),
          const SizedBox(height: TioSpacing.large),
          _BridgeHighlightRow(
            icon: Icons.water_drop_outlined,
            title: 'Hydration Intake',
            description:
                'Personalized daily water target calibrated to your body weight and activity.',
            colors: colors,
            textTheme: textTheme,
          ),
          const SizedBox(height: TioSpacing.large),
          _BridgeHighlightRow(
            icon: Icons.bedtime_outlined,
            title: 'Sleep & Recovery Schedule',
            description:
                'Consistent sleep and wake timing to maximize recovery and performance.',
            colors: colors,
            textTheme: textTheme,
          ),
          const SizedBox(height: TioSpacing.extraLarge),
          Row(
            children: [
              Icon(
                Icons.tune_outlined,
                size: 16,
                color: colors.textSecondary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: TioSpacing.small),
              Expanded(
                child: Text(
                  'In the next steps, you can customize each target to fit your daily routine.',
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: colors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BridgeHighlightRow extends StatelessWidget {
  const _BridgeHighlightRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.colors,
    required this.textTheme,
  });

  final IconData icon;
  final String title;
  final String description;
  final TioColors colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 22,
            color: colors.primary,
          ),
        ),
        const SizedBox(width: TioSpacing.medium + 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  height: 1.35,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
