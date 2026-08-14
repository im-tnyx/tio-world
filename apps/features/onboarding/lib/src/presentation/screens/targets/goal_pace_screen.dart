import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'targets_screen_components.dart';

class GoalPaceScreen extends StatelessWidget {
  const GoalPaceScreen({
    required this.goalPaceKgPerWeek,
    required this.onPaceChanged,
    required this.profile,
    super.key,
    this.errorText,
    this.currentDate,
  });

  final double goalPaceKgPerWeek;
  final ValueChanged<double> onPaceChanged;
  final ProfileOnboardingDraft profile;
  final String? errorText;
  final DateTime? currentDate;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final primaryGoal = profile.goals.isNotEmpty ? profile.goals.first : null;
    final mode = GoalPaceResolver.resolveMode(
      currentWeightKg: profile.currentWeightKg,
      targetWeightKg: profile.targetWeightKg,
    );

    final title = GoalPaceResolver.screenTitle(
      primaryGoal: primaryGoal,
      mode: mode,
    );
    final cardHeader = GoalPaceResolver.cardHeader(
      mode: mode,
      primaryGoal: primaryGoal,
    );
    final paceTag = GoalPaceResolver.paceTag(goalPaceKgPerWeek);
    final warning = GoalPaceResolver.resolveWarning(
      mode: mode,
      paceKgPerWeek: goalPaceKgPerWeek,
    );

    final now = currentDate ?? DateTime.now();
    final targetDate = GoalPaceTargetDateCalculator.calculateTargetDate(
      currentWeightKg: profile.currentWeightKg,
      targetWeightKg: profile.targetWeightKg,
      paceKgPerWeek: goalPaceKgPerWeek,
      now: now,
    );

    final isMaintenance = mode == GoalPaceMode.maintenance;
    final currentWeightDisplay = profile.currentWeightKg != null
        ? '${profile.currentWeightKg!.toStringAsFixed(1)} kg'
        : '-- kg';
    final targetWeightDisplay = profile.targetWeightKg != null
        ? '${profile.targetWeightKg!.toStringAsFixed(1)} kg'
        : currentWeightDisplay;

    return TargetsScreenScaffold(
      stepId: TargetStepId.goalPace,
      title: title,
      description: isMaintenance
          ? 'Maintain your current weight and focus on body composition and energy balance.'
          : 'Choose a realistic weekly pace to reach your target weight sustainably.',
      errorText: errorText,
      child: Column(
        children: [
          TioCard(
            key: const ValueKey('targets-goal-pace-card'),
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
                          Icons.speed_outlined,
                          color: colors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: TioSpacing.small),
                        Text(
                          cardHeader,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    TargetsStatusChip(
                      label: isMaintenance ? 'Maintenance' : paceTag,
                      isRecommended: warning == GoalPaceWarning.none,
                    ),
                  ],
                ),
                if (!isMaintenance) ...[
                  const SizedBox(height: TioSpacing.medium),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '${goalPaceKgPerWeek.toStringAsFixed(1)} kg',
                          key: const ValueKey('targets-goal-pace-value-text'),
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'per week',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: colors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: TioSpacing.medium),
                  Slider(
                    key: const ValueKey('targets-goal-pace-slider'),
                    value: goalPaceKgPerWeek.clamp(
                      GoalPaceResolver.minPaceKgPerWeek,
                      GoalPaceResolver.maxPaceKgPerWeek,
                    ),
                    min: GoalPaceResolver.minPaceKgPerWeek, // 0.1
                    max: GoalPaceResolver.maxPaceKgPerWeek, // 1.5
                    divisions: 14, // 0.1 kg/week increments
                    activeColor: colors.primary,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      final rounded = (val * 10).round() / 10.0;
                      onPaceChanged(rounded);
                    },
                  ),
                  if (warning != GoalPaceWarning.none)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: TioSpacing.medium,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(TioRadius.extraLarge),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 16, color: colors.warning),
                            const SizedBox(width: 4),
                            Text(
                              warning == GoalPaceWarning.aggressiveLoss
                                  ? 'Aggressive Loss Pace'
                                  : 'Aggressive Gain Pace',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: colors.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ] else ...[
                  const SizedBox(height: TioSpacing.medium),
                  Center(
                    child: Text(
                      'Steady Energy Balance',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: TioSpacing.large),
          TioCard(
            key: const ValueKey('targets-projection-card'),
            variant: TioCardVariant.outlined,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Estimated target: ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                    Text(
                      targetWeightDisplay,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: TioSpacing.medium),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _DatePill(
                      text: targetDate.day.toString(),
                      label: 'DAY',
                    ),
                    const SizedBox(width: TioSpacing.small),
                    _DatePill(
                      text: _monthName(targetDate.month),
                      label: 'MONTH',
                    ),
                    const SizedBox(width: TioSpacing.small),
                    _DatePill(
                      text: targetDate.year.toString(),
                      label: 'YEAR',
                    ),
                  ],
                ),
                const SizedBox(height: TioSpacing.medium),
                SizedBox(
                  height: 90,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _TrajectoryPainter(
                      mode: mode,
                      primaryColor: colors.primary,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: mode == GoalPaceMode.loss
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.end,
                        children: [
                          _WeightBadge(
                            label: 'Now',
                            value: currentWeightDisplay,
                          ),
                          _WeightBadge(
                            label: 'Target',
                            value: targetWeightDisplay,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TioSpacing.large),
          Text(
            isMaintenance
                ? 'Maintaining your target weight supports consistent energy expenditure, routine recovery, and long-term habits.'
                : 'A steady pace of 0.4–0.7 kg/week is widely recommended for lasting fat loss or lean muscle development while protecting metabolic rate.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textMuted,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[(month - 1).clamp(0, 11)];
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({
    required this.text,
    required this.label,
  });

  final String text;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TioSpacing.medium,
        vertical: TioSpacing.small,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(TioRadius.medium),
      ),
      child: Column(
        children: [
          Text(
            text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textMuted,
                  fontSize: 9,
                ),
          ),
        ],
      ),
    );
  }
}

class _WeightBadge extends StatelessWidget {
  const _WeightBadge({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TioRadius.small),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textMuted,
                  fontSize: 9,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
          ),
        ],
      ),
    );
  }
}

class _TrajectoryPainter extends CustomPainter {
  _TrajectoryPainter({
    required this.mode,
    required this.primaryColor,
  });

  final GoalPaceMode mode;
  final Color primaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final startY = switch (mode) {
      GoalPaceMode.loss => 20.0,
      GoalPaceMode.gain => size.height - 20.0,
      GoalPaceMode.maintenance => size.height / 2.0,
    };
    final endY = switch (mode) {
      GoalPaceMode.loss => size.height - 20.0,
      GoalPaceMode.gain => 20.0,
      GoalPaceMode.maintenance => size.height / 2.0,
    };

    path.moveTo(0, startY);
    path.cubicTo(
      size.width * 0.4,
      startY,
      size.width * 0.6,
      endY,
      size.width,
      endY,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrajectoryPainter oldDelegate) {
    return oldDelegate.mode != mode || oldDelegate.primaryColor != primaryColor;
  }
}
