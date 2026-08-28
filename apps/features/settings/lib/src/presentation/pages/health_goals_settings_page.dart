import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

class HealthGoalsSettingsPage extends StatelessWidget {
  const HealthGoalsSettingsPage({
    required this.onDailyWellnessPressed,
    super.key,
  });

  final VoidCallback onDailyWellnessPressed;

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
            _HealthGoalsGroupCard(
              children: [
                _HealthGoalsTile(
                  key: const ValueKey('health-goals-daily-wellness-entry'),
                  icon: Icons.wb_sunny_outlined,
                  title: 'Daily Wellness',
                  subtitle: 'Steps, water, sleep & schedule',
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

class _HealthGoalsGroupCard extends StatelessWidget {
  const _HealthGoalsGroupCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Material(
      color: colors.surfaceRaised,
      borderRadius: BorderRadius.circular(TioRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _HealthGoalsTile extends StatelessWidget {
  const _HealthGoalsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TioSpacing.lg,
          vertical: TioSpacing.md + TioSize.dp4,
        ),
        child: Row(
          children: [
            Container(
              width: TioSize.dp40,
              height: TioSize.dp40,
              decoration: BoxDecoration(
                color: colors.primary.withAlpha(TioAlpha.alpha18),
                borderRadius: BorderRadius.circular(TioRadius.sm),
              ),
              child: Icon(
                icon,
                size: TioSize.dp22,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: TioSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: TioFontWeight.w700,
                      fontSize: TioFontSize.size15,
                    ),
                  ),
                  const SizedBox(height: TioSpacing.xxs),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: TioFontSize.size12,
                      fontWeight: TioFontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: TioSize.dp20,
              color: colors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
