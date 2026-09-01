import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

class HealthGoalsSettingsPage extends StatelessWidget {
  const HealthGoalsSettingsPage({
    required this.onDailyWellnessPressed,
    required this.onBodyWeightPressed,
    super.key,
  });

  final VoidCallback onDailyWellnessPressed;
  final VoidCallback onBodyWeightPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          'Health & Goals',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: TioFontWeight.w800,
            fontSize: TioFontSize.size20,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: TioSpacing.lg,
            vertical: TioSpacing.md,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: TioSpacing.sm,
                right: TioSpacing.sm,
                bottom: TioSpacing.lg,
              ),
              child: Text(
                'Manage your daily wellness and lifestyle targets.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: TioFontSize.size14,
                  height: TioLineHeight.height145,
                ),
              ),
            ),
            const _HealthGoalsSectionHeader(title: 'DAILY TARGETS'),
            TioGroupCard(
              children: [
                TioSettingsNavigationRow(
                  key: const ValueKey('health-goals-body-weight-entry'),
                  leading: const TioSettingsLeadingIcon(
                    icon: Icons.monitor_weight_outlined,
                  ),
                  title: 'Body & Weight',
                  supportingText: 'Current weight, Body Goal & pace',
                  onTap: onBodyWeightPressed,
                ),
                const _HealthGoalsDivider(),
                TioSettingsNavigationRow(
                  key: const ValueKey('health-goals-daily-wellness-entry'),
                  leading: const TioSettingsLeadingIcon(
                    icon: Icons.wb_sunny_outlined,
                  ),
                  title: 'Daily Wellness',
                  supportingText: 'Steps, water, sleep & schedule',
                  onTap: onDailyWellnessPressed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthGoalsSectionHeader extends StatelessWidget {
  const _HealthGoalsSectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Padding(
      padding: const EdgeInsets.only(
        left: TioSpacing.sm,
        bottom: TioSpacing.sm,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: colors.textMuted,
          fontWeight: TioFontWeight.w700,
          fontSize: TioFontSize.size11,
          letterSpacing: TioLetterSpacing.positive08,
        ),
      ),
    );
  }
}

class _HealthGoalsDivider extends StatelessWidget {
  const _HealthGoalsDivider();

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Divider(
      height: TioSize.dp1,
      thickness: TioSize.dp1,
      indent: TioSize.dp72,
      color: colors.outlineStrong.withAlpha(TioAlpha.alpha24),
    );
  }
}
