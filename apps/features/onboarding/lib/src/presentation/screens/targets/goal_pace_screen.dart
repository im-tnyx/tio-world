import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'targets_screen_components.dart';

class GoalPaceScreen extends StatefulWidget {
  const GoalPaceScreen({
    required this.goalPaceKgPerWeek,
    required this.onPaceChanged,
    required this.profile,
    required this.weightGoalDirection,
    super.key,
    this.errorText,
    this.currentDate,
  });

  final double goalPaceKgPerWeek;
  final ValueChanged<double> onPaceChanged;
  final ProfileOnboardingDraft profile;
  final GoalWeightDirection weightGoalDirection;
  final String? errorText;
  final DateTime? currentDate;

  @override
  State<GoalPaceScreen> createState() => _GoalPaceScreenState();
}

class _GoalPaceScreenState extends State<GoalPaceScreen> {
  static const _monthsFull = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _monthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  late double _paceValue;
  double _lastVibratedPace = GoalPaceResolver.defaultPaceKgPerWeek;

  @override
  void initState() {
    super.initState();
    _paceValue = widget.goalPaceKgPerWeek.clamp(
      GoalPaceResolver.minPaceKgPerWeek,
      GoalPaceResolver.maxPaceKgPerWeek,
    );
    _lastVibratedPace = _paceValue;
  }

  @override
  void didUpdateWidget(covariant GoalPaceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.goalPaceKgPerWeek != widget.goalPaceKgPerWeek) {
      _paceValue = widget.goalPaceKgPerWeek.clamp(
        GoalPaceResolver.minPaceKgPerWeek,
        GoalPaceResolver.maxPaceKgPerWeek,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    final currentWeightKg = widget.profile.currentWeightKg ?? 70.0;
    final targetWeightKg = widget.profile.targetWeightKg ?? currentWeightKg;
    final mode = GoalPaceResolver.resolveModeForDirection(
      widget.weightGoalDirection,
    );
    final isLoss = mode == GoalPaceMode.loss;

    final warning = GoalPaceResolver.resolveWarning(
      mode: mode,
      paceKgPerWeek: _paceValue,
    );

    final weightDiff = (currentWeightKg - targetWeightKg).abs();
    final weeksNeeded = _paceValue > 0 ? weightDiff / _paceValue : 0.0;
    final daysNeeded = (weeksNeeded * 7).round();

    final now = widget.currentDate ?? DateTime.now();
    final targetDate = now.add(Duration(days: daysNeeded));
    final targetDay = targetDate.day.toString();
    final targetMonthIndex = (targetDate.month - 1).clamp(0, 11);
    final targetMonthFull = _monthsFull[targetMonthIndex];
    final targetMonthShort = _monthsShort[targetMonthIndex];
    final targetYear = targetDate.year.toString();

    final paceTag = GoalPaceResolver.paceTag(_paceValue);
    final titleText = GoalPaceResolver.screenTitleForDirection(
      widget.weightGoalDirection,
    );
    final headerLabel = GoalPaceResolver.cardHeaderForDirection(
      widget.weightGoalDirection,
    );

    return TargetsScreenScaffold(
      stepId: TargetStepId.goalPace,
      title: titleText,
      description:
          'Choose a realistic weekly pace to reach your target weight sustainably.',
      errorText: widget.errorText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TioCard(
            key: const ValueKey('targets-goal-pace-card'),
            variant: TioCardVariant.elevated,
            padding: const EdgeInsets.all(TioSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_outlined,
                      color: colors.primary,
                      size: TioSize.dp22,
                    ),
                    const SizedBox(width: TioSpacing.sm),
                    Text(
                      headerLabel,
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: TioFontSize.size16,
                        fontWeight: TioFontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TioSpacing.md),
                Center(
                  child: Text(
                    '${_paceValue.toStringAsFixed(1)} kg / week',
                    key: const ValueKey('targets-goal-pace-value-text'),
                    style: textTheme.headlineMedium?.copyWith(
                      fontSize: TioFontSize.size32,
                      fontWeight: TioFontWeight.w800,
                      color: colors.textPrimary,
                      letterSpacing: TioLetterSpacing.negative05,
                    ),
                  ),
                ),
                const SizedBox(height: TioSpacing.sm),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: colors.primary,
                    inactiveTrackColor: colors.surfaceVariant,
                    thumbColor: colors.primary,
                    overlayColor: colors.primary.withValues(
                      alpha: TioOpacity.opacity20,
                    ),
                    trackHeight: TioSize.dp6,
                    trackShape: const RectangularSliderTrackShape(),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: TioSize.dp9,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: TioSize.dp16,
                    ),
                  ),
                  child: Slider(
                    key: const ValueKey('targets-goal-pace-slider'),
                    value: _paceValue,
                    min: GoalPaceResolver.minPaceKgPerWeek,
                    max: GoalPaceResolver.maxPaceKgPerWeek,
                    divisions: 14,
                    onChanged: (val) {
                      final rounded = (val * 10).round() / 10.0;
                      setState(() {
                        _paceValue = rounded;
                      });
                      widget.onPaceChanged(rounded);

                      if ((rounded - _lastVibratedPace).abs() >= 0.09) {
                        HapticFeedback.selectionClick();
                        _lastVibratedPace = rounded;
                      }
                    },
                  ),
                ),
                const SizedBox(height: TioSpacing.md),
                if (warning != GoalPaceWarning.none)
                  InkWell(
                    onTap: () => _showAttentionSheet(context, warning),
                    borderRadius: BorderRadius.circular(TioRadius.md),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TioSpacing.md,
                        vertical: TioSize.dp6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.danger.withValues(
                          alpha: TioOpacity.opacity15,
                        ),
                        borderRadius: BorderRadius.circular(TioRadius.md),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: TioFontSize.size15,
                            color: colors.danger,
                          ),
                          const SizedBox(width: TioSpacing.xs),
                          Text(
                            warning == GoalPaceWarning.aggressiveLoss
                                ? 'Aggressive Loss Pace'
                                : 'Aggressive Gain Pace',
                            style: textTheme.labelMedium?.copyWith(
                              fontSize: TioFontSize.size13,
                              color: colors.danger,
                              fontWeight: TioFontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TioSize.dp14,
                      vertical: TioSize.dp6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(
                        alpha: TioOpacity.opacity15,
                      ),
                      borderRadius: BorderRadius.circular(TioRadius.md),
                    ),
                    child: Text(
                      paceTag,
                      style: textTheme.labelMedium?.copyWith(
                        fontSize: TioFontSize.size13,
                        color: colors.primary,
                        fontWeight: TioFontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: TioSpacing.md),
          TioCard(
            key: const ValueKey('targets-projection-card'),
            variant: TioCardVariant.elevated,
            padding: const EdgeInsets.symmetric(
              horizontal: TioSpacing.lg,
              vertical: TioSize.dp14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: "You'll be ",
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.textSecondary,
                      fontSize: TioFontSize.size16,
                    ),
                    children: [
                      TextSpan(
                        text: '${targetWeightKg.toStringAsFixed(1)} kg',
                        style: textTheme.titleLarge?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: TioFontWeight.w700,
                          fontSize: TioFontSize.size18,
                        ),
                      ),
                      const TextSpan(text: ' by'),
                    ],
                  ),
                ),
                const SizedBox(height: TioSize.dp10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _DatePill(
                      text: targetDay,
                      width: TioSize.dp56,
                      colors: colors,
                      textTheme: textTheme,
                    ),
                    const SizedBox(width: TioSpacing.sm),
                    _DatePill(
                      text: targetMonthFull,
                      width: TioSize.dp114,
                      colors: colors,
                      textTheme: textTheme,
                    ),
                    const SizedBox(width: TioSpacing.sm),
                    _DatePill(
                      text: targetYear,
                      width: TioSize.dp76,
                      colors: colors,
                      textTheme: textTheme,
                    ),
                  ],
                ),
                const SizedBox(height: TioSpacing.sm),
                Text(
                  'And achieve lasting results!',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary.withValues(
                      alpha: TioOpacity.opacity70,
                    ),
                    fontSize: TioFontSize.size13,
                  ),
                ),
                const SizedBox(height: TioSpacing.md),
                SizedBox(
                  height: TioSize.dp135,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _ProjectionGraphPainter(
                            isLoss: isLoss,
                            graphColor: colors.primary,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          'Today',
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.textSecondary.withValues(
                              alpha: TioOpacity.opacity70,
                            ),
                            fontSize: TioFontSize.size11,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          targetMonthShort,
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.textSecondary.withValues(
                              alpha: TioOpacity.opacity70,
                            ),
                            fontSize: TioFontSize.size11,
                          ),
                        ),
                      ),
                      Positioned(
                        left: TioSize.dp0,
                        top: isLoss ? TioSize.dp4 : null,
                        bottom: isLoss ? null : TioSize.dp20,
                        child: _WeightBadge(
                          text: '${currentWeightKg.toStringAsFixed(1)} kg',
                          colors: colors,
                          textTheme: textTheme,
                        ),
                      ),
                      Positioned(
                        right: TioSize.dp0,
                        bottom: isLoss ? TioSize.dp20 : null,
                        top: isLoss ? null : TioSize.dp4,
                        child: _WeightBadge(
                          text: '${targetWeightKg.toStringAsFixed(1)} kg',
                          colors: colors,
                          textTheme: textTheme,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAttentionSheet(
    BuildContext context,
    GoalPaceWarning warning,
  ) {
    final colors = context.tioColors;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TioPalette.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surfaceRaised,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(TioRadius.xl),
            ),
            border: Border.all(
              color: colors.outlineStrong.withAlpha(TioAlpha.alpha25),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                TioSpacing.lg,
                TioSpacing.lg,
                TioSpacing.lg,
                TioSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: colors.danger,
                            size: TioSize.dp22,
                          ),
                          const SizedBox(width: TioSpacing.sm),
                          Text(
                            'Attention',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: TioFontWeight.w700,
                              fontSize: TioFontSize.size20,
                              letterSpacing: TioLetterSpacing.negative03,
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: TioSize.dp32,
                          height: TioSize.dp32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.outlineStrong.withAlpha(
                              TioAlpha.alpha50,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close_rounded,
                              color: colors.textSecondary,
                              size: TioSize.dp18,
                            ),
                            splashRadius: TioSize.dp16,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TioSize.dp14),
                  Text(
                    warning == GoalPaceWarning.aggressiveLoss
                        ? 'Losing more than 1.0 kg per week may cause fatigue, muscle loss, and lower adherence. A steady pace of 0.4–0.7 kg/week is recommended.'
                        : 'Gaining more than 1.0 kg per week may increase unwanted fat accumulation rather than lean muscle tissue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: TioFontSize.size14,
                      height: TioLineHeight.height140,
                      fontWeight: TioFontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: TioSize.dp28),
                  TioButton.primary(
                    label: 'Understood',
                    expand: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({
    required this.text,
    required this.width,
    required this.colors,
    required this.textTheme,
  });

  final String text;
  final double width;
  final TioColors colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: TioSize.dp10),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withValues(
          alpha: TioOpacity.opacity50,
        ),
        borderRadius: BorderRadius.circular(TioRadius.md),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: textTheme.titleMedium?.copyWith(
          fontWeight: TioFontWeight.w700,
          color: colors.textPrimary,
          fontSize: TioFontSize.size16,
        ),
      ),
    );
  }
}

class _WeightBadge extends StatelessWidget {
  const _WeightBadge({
    required this.text,
    required this.colors,
    required this.textTheme,
  });

  final String text;
  final TioColors colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TioSize.dp10,
        vertical: TioSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(TioRadius.md),
      ),
      child: Text(
        text,
        style: textTheme.labelSmall?.copyWith(
          color: colors.onPrimary,
          fontWeight: TioFontWeight.w700,
          fontSize: TioFontSize.size12,
        ),
      ),
    );
  }
}

class _ProjectionGraphPainter extends CustomPainter {
  _ProjectionGraphPainter({
    required this.isLoss,
    required this.graphColor,
  });

  final bool isLoss;
  final Color graphColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final startY = isLoss ? TioSize.dp12 : h - TioSize.dp24;
    final endY = isLoss ? h - TioSize.dp24 : TioSize.dp12;

    final path = Path();
    path.moveTo(0, startY);
    path.cubicTo(w * 0.4, startY, w * 0.6, endY, w, endY);

    final fillPath = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          graphColor.withValues(alpha: TioOpacity.opacity28),
          graphColor.withValues(alpha: TioOpacity.opacity02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, gradientPaint);

    final strokePaint = Paint()
      ..color = graphColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = TioStroke.width3
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    final dotPaint = Paint()
      ..color = graphColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(0, startY), TioSize.dp5, dotPaint);
    canvas.drawCircle(Offset(w, endY), TioSize.dp5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _ProjectionGraphPainter oldDelegate) {
    return oldDelegate.isLoss != isLoss || oldDelegate.graphColor != graphColor;
  }
}
