import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

/// Compact resume/discard pill shown when a workout is running but Log Workout
/// is not on screen. Matches the tio-workspace mini-bar job: reopen or discard.
class ActiveWorkoutMiniBar extends StatelessWidget {
  const ActiveWorkoutMiniBar({
    required this.duration,
    required this.subtitle,
    required this.isPaused,
    required this.onResume,
    required this.onDiscard,
    super.key,
  });

  final Duration duration;
  final String subtitle;
  final bool isPaused;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  static String formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    String two(int value) => value.toString().padLeft(2, '0');
    return '$hours:${two(minutes)}:${two(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;
    final durationLabel = formatDuration(duration);

    return Material(
      key: const ValueKey('active-workout-mini-bar'),
      color: TioPalette.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: BorderRadius.circular(TioRadius.full),
          border: Border.all(
            color: colors.outlineStrong.withValues(alpha: TioOpacity.opacity40),
          ),
          boxShadow: context.tioShadows.soft,
        ),
        child: SizedBox(
          height: TioSize.dp56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: TioSpacing.sm),
            child: Row(
              children: [
                _CircleAction(
                  key: const ValueKey('active-workout-mini-bar-resume'),
                  icon: Icons.keyboard_arrow_up_rounded,
                  color: colors.textPrimary,
                  semanticLabel: 'Resume workout',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onResume();
                  },
                ),
                const SizedBox(width: TioSpacing.sm),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onResume();
                    },
                    borderRadius: BorderRadius.circular(TioRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TioSpacing.xs,
                        vertical: TioSpacing.xs,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _StatusDot(isPaused: isPaused),
                              const SizedBox(width: TioSpacing.sm),
                              Flexible(
                                child: Text(
                                  'Workout $durationLabel',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.titleSmall?.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: TioFontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: TioSize.dp2),
                          Padding(
                            padding: const EdgeInsets.only(left: TioSize.dp24),
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: TioSpacing.sm),
                _CircleAction(
                  key: const ValueKey('active-workout-mini-bar-discard'),
                  icon: Icons.delete_outline_rounded,
                  color: colors.danger,
                  semanticLabel: 'Discard workout',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onDiscard();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.color,
    required this.semanticLabel,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final Color color;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: colors.surfaceVariant,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: TioSize.dp44,
            height: TioSize.dp44,
            child: Icon(icon, color: color, size: TioSize.dp24),
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.isPaused});

  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    if (isPaused) {
      return Container(
        width: TioSize.dp8,
        height: TioSize.dp8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.textSecondary,
        ),
      );
    }
    return Container(
      width: TioSize.dp8,
      height: TioSize.dp8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.success,
        boxShadow: [
          BoxShadow(
            color: colors.success.withValues(alpha: TioOpacity.opacity40),
            blurRadius: TioSize.dp4,
            spreadRadius: TioSize.dp1,
          ),
        ],
      ),
    );
  }
}
