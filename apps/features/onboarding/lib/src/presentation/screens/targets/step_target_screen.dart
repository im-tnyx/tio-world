import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'targets_screen_components.dart';

class StepTargetScreen extends StatelessWidget {
  const StepTargetScreen({
    required this.dailySteps,
    required this.onChanged,
    super.key,
    this.errorText,
  });

  final int dailySteps;
  final ValueChanged<int> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final isRecommended = dailySteps == 10000;

    return TargetsScreenScaffold(
      stepId: TargetStepId.stepTarget,
      title: 'Daily step target',
      description:
          'Setting a daily step goal keeps your baseline activity consistent.',
      errorText: errorText,
      child: Column(
        children: [
          TioCard(
            key: const ValueKey('targets-step-card'),
            variant: TioCardVariant.elevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.directions_walk,
                          color: colors.workout,
                          size: TioSize.dp24,
                        ),
                        const SizedBox(width: TioSpacing.sm),
                        Text(
                          'Step Target',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    IconButton(
                      key: const ValueKey('targets-step-edit-button'),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: TioSize.dp20,
                      ),
                      tooltip: 'Enter exact steps',
                      onPressed: () => _showEditDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: TioSpacing.md),
                Center(
                  child: Column(
                    children: [
                      Text(
                        '$dailySteps',
                        key: const ValueKey('targets-step-value-text'),
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(
                              fontWeight: TioFontWeight.w700,
                              color: colors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: TioSpacing.xs),
                      Text(
                        'steps/day',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colors.textSecondary,
                                ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TioSpacing.md),
                Slider(
                  key: const ValueKey('targets-step-slider'),
                  value: dailySteps
                      .clamp(
                        TargetStepValidator.minDailySteps,
                        TargetStepValidator.maxDailySteps,
                      )
                      .toDouble(),
                  min: TargetStepValidator.minDailySteps.toDouble(),
                  max: TargetStepValidator.maxDailySteps.toDouble(),
                  divisions: 16, // Program value: 1000-step increments.
                  activeColor: colors.primary,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    onChanged(val.round());
                  },
                ),
                if (isRecommended)
                  const Center(
                    child: TargetsStatusChip(
                      label: 'Recommended',
                      isRecommended: true,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: TioSpacing.lg),
          Text(
            '10,000 steps per day is a widely recommended baseline for cardiovascular health and daily energy expenditure.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textMuted,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final controller = TextEditingController(text: dailySteps.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter step target'),
        content: TextField(
          key: const ValueKey('targets-step-dialog-input'),
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            hintText: 'e.g. 10000',
            suffixText: 'steps',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text);
              if (parsed != null &&
                  parsed >= TargetStepValidator.minDailySteps &&
                  parsed <= TargetStepValidator.maxDailySteps) {
                Navigator.of(ctx).pop(parsed);
              } else {
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );

    if (result != null) {
      onChanged(result);
    }
  }
}
