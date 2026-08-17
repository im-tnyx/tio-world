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
    super.key,
    this.stepTarget = 10000,
    this.errorText,
    this.currentDate,
  });

  final double goalPaceKgPerWeek;
  final ValueChanged<double> onPaceChanged;
  final ProfileOnboardingDraft profile;
  final int stepTarget;
  final String? errorText;
  final DateTime? currentDate;

  @override
  State<GoalPaceScreen> createState() => _GoalPaceScreenState();
}

class _GoalPaceScreenState extends State<GoalPaceScreen> {
  static const _monthsFull = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  static const _monthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  late double _paceValue;
  double _lastVibratedPace = 0.5;

  @override
  void initState() {
    super.initState();
    _paceValue = widget.goalPaceKgPerWeek.clamp(0.1, 1.5);
    _lastVibratedPace = _paceValue;
  }

  @override
  void didUpdateWidget(covariant GoalPaceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.goalPaceKgPerWeek != widget.goalPaceKgPerWeek) {
      _paceValue = widget.goalPaceKgPerWeek.clamp(0.1, 1.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);
    final textTheme = Theme.of(context).textTheme;

    final currentWeightKg = widget.profile.currentWeightKg ?? 70.0;
    final targetWeightKg = widget.profile.targetWeightKg ?? 63.6;
    final primaryGoal = widget.profile.goals.isNotEmpty
        ? widget.profile.goals.first
        : ProfileGoal.loseWeight;

    final mode = GoalPaceResolver.resolveMode(
      currentWeightKg: widget.profile.currentWeightKg,
      targetWeightKg: widget.profile.targetWeightKg,
    );

    final isLoss = mode == GoalPaceMode.loss;
    final isMaintenance = mode == GoalPaceMode.maintenance;

    // Calorie calculation matching Compose logic
    final baseBmrValue = currentWeightKg > 0 ? (24.0 * currentWeightKg) : 1600.0;
    final stepCalories = widget.stepTarget * 0.04;
    final tdee = baseBmrValue + stepCalories;

    final int rawTargetKcal;
    switch (mode) {
      case GoalPaceMode.loss:
        final deficit = (_paceValue * 7700.0) / 7.0;
        rawTargetKcal = (tdee - deficit).toInt();
        break;
      case GoalPaceMode.gain:
        final surplus = (_paceValue * 5000.0) / 7.0;
        rawTargetKcal = (tdee + surplus).toInt();
        break;
      case GoalPaceMode.maintenance:
        rawTargetKcal = tdee.toInt();
        break;
    }

    final displayTargetKcal = rawTargetKcal;

    final warning = GoalPaceResolver.resolveWarning(
      mode: mode,
      paceKgPerWeek: _paceValue,
    );

    // Timeline calculation
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
    final titleText = GoalPaceResolver.screenTitle(
      primaryGoal: primaryGoal,
      mode: mode,
    );
    final headerLabel = _resolveHeader(primaryGoal, mode, isLoss, isMaintenance);

    return TargetsScreenScaffold(
      stepId: TargetStepId.goalPace,
      title: titleText,
      description: isMaintenance
          ? 'Maintain your current weight and focus on body composition and energy balance.'
          : 'Choose a realistic weekly pace to reach your target weight sustainably.',
      errorText: widget.errorText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card 1: Pace & Calories
          TioCard(
            key: const ValueKey('targets-goal-pace-card'),
            variant: TioCardVariant.elevated,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Flame Icon + Goal Label + Info Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department_outlined,
                          color: colors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: TioSpacing.small),
                        Text(
                          headerLabel,
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    InkResponse(
                      onTap: () => _showCalorieInfoSheet(context),
                      radius: 16,
                      child: Icon(
                        Icons.info_outline,
                        size: 20,
                        color: colors.textSecondary.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),

                if (!isMaintenance) ...[
                  const SizedBox(height: TioSpacing.medium),
                  // Centered Big Pace text (e.g. 0.5 kg / week)
                  Center(
                    child: Text(
                      '${_paceValue.toStringAsFixed(1)} kg / week',
                      key: const ValueKey('targets-goal-pace-value-text'),
                      style: textTheme.headlineMedium?.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Slider
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: colors.primary,
                      inactiveTrackColor: colors.surfaceVariant,
                      thumbColor: colors.primary,
                      overlayColor: colors.primary.withValues(alpha: 0.2),
                      trackHeight: 6,
                      trackShape: const RectangularSliderTrackShape(),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 9,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16,
                      ),
                    ),
                    child: Slider(
                      key: const ValueKey('targets-goal-pace-slider'),
                      value: _paceValue,
                      min: 0.1,
                      max: 1.5,
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
                ],

                const SizedBox(height: TioSpacing.medium),

                // Bottom Chips Row (Fixed height in all states - never jumps)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Pill: Pace tag or Warning chip
                    if (warning != GoalPaceWarning.none)
                      InkWell(
                        onTap: () => _showAttentionSheet(context, warning),
                        borderRadius: BorderRadius.circular(TioRadius.medium),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.danger.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(TioRadius.medium),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 15,
                                color: colors.danger,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                warning == GoalPaceWarning.aggressiveLoss
                                    ? 'Aggressive Loss Pace'
                                    : 'Aggressive Gain Pace',
                                style: textTheme.labelMedium?.copyWith(
                                  fontSize: 13,
                                  color: colors.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(TioRadius.medium),
                        ),
                        child: Text(
                          isMaintenance ? 'Maintenance' : paceTag,
                          style: textTheme.labelMedium?.copyWith(
                            fontSize: 13,
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    // Right Calories Pill with Info
                    InkWell(
                      onTap: () => _showCalorieInfoSheet(context),
                      borderRadius: BorderRadius.circular(TioRadius.medium),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(TioRadius.medium),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$displayTargetKcal kcal',
                              style: textTheme.labelMedium?.copyWith(
                                fontSize: 13,
                                color: colors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: colors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: TioSpacing.medium),

          // Card 2: Projection & Timeline Graph
          TioCard(
            key: const ValueKey('targets-projection-card'),
            variant: TioCardVariant.elevated,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Rich Text: You'll be 63.6 kg by
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: "You'll be ",
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.textSecondary,
                      fontSize: 16,
                    ),
                    children: [
                      TextSpan(
                        text: '${targetWeightKg.toStringAsFixed(1)} kg',
                        style: textTheme.titleLarge?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const TextSpan(text: ' by'),
                    ],
                  ),
                ),

                const SizedBox(height: TioSpacing.small + 2),

                // Date Pills Row (Day, Month, Year)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _DatePill(
                      text: targetDay,
                      width: 56,
                      colors: colors,
                      textTheme: textTheme,
                    ),
                    const SizedBox(width: TioSpacing.small),
                    _DatePill(
                      text: targetMonthFull,
                      width: 114,
                      colors: colors,
                      textTheme: textTheme,
                    ),
                    const SizedBox(width: TioSpacing.small),
                    _DatePill(
                      text: targetYear,
                      width: 76,
                      colors: colors,
                      textTheme: textTheme,
                    ),
                  ],
                ),

                const SizedBox(height: TioSpacing.small),

                Text(
                  'And achieve lasting results!',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: TioSpacing.medium),

                // Graph Canvas Area with Bezier curve and Weight Badges
                SizedBox(
                  height: 135,
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

                      // Top/Bottom Labels: Today & Target Month
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          'Today',
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.textSecondary.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          targetMonthShort,
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.textSecondary.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ),

                      // Start Weight Badge (Now)
                      Positioned(
                        left: 0,
                        top: isLoss ? 4 : null,
                        bottom: isLoss ? null : 20,
                        child: _WeightBadge(
                          text: '${currentWeightKg.toStringAsFixed(1)} kg',
                          colors: colors,
                          textTheme: textTheme,
                        ),
                      ),

                      // Target Weight Badge (Target)
                      Positioned(
                        right: 0,
                        bottom: isLoss ? 20 : null,
                        top: isLoss ? null : 4,
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

  void _showCalorieInfoSheet(BuildContext context) {
    final colors = TioTheme.colors(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surfaceRaised,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(TioRadius.extraLarge),
            ),
            border: Border.all(
              color: colors.outlineStrong.withAlpha(25),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                TioSpacing.large,
                TioSpacing.large,
                TioSpacing.large,
                TioSpacing.extraLarge,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Stack: Title & Close Button
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Text(
                          'Target Calories',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.outlineStrong.withAlpha(50),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close_rounded,
                              color: colors.textSecondary,
                              size: 18,
                            ),
                            splashRadius: 16,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Description
                  Text(
                    'Your daily calorie target is dynamically calculated using your Basal Metabolic Rate (BMR), daily activity level, and chosen weekly pace.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Action Button
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

  void _showAttentionSheet(
    BuildContext context,
    GoalPaceWarning warning,
  ) {
    final colors = TioTheme.colors(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surfaceRaised,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(TioRadius.extraLarge),
            ),
            border: Border.all(
              color: colors.outlineStrong.withAlpha(25),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                TioSpacing.large,
                TioSpacing.large,
                TioSpacing.large,
                TioSpacing.extraLarge,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Stack: Icon + Title & Close Button
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: colors.danger,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Attention',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.outlineStrong.withAlpha(50),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close_rounded,
                              color: colors.textSecondary,
                              size: 18,
                            ),
                            splashRadius: 16,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Description
                  Text(
                    warning == GoalPaceWarning.aggressiveLoss
                        ? 'Losing more than 1.0 kg per week may cause fatigue, muscle loss, and lower adherence. A steady pace of 0.4–0.7 kg/week is recommended.'
                        : 'Gaining more than 1.0 kg per week may increase unwanted fat accumulation rather than lean muscle tissue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Action Button
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

  String _resolveHeader(
    ProfileGoal primaryGoal,
    GoalPaceMode mode,
    bool isLoss,
    bool isMaintenance,
  ) {
    if (primaryGoal == ProfileGoal.buildMuscle) {
      return mode == GoalPaceMode.loss
          ? 'Recomposition'
          : mode == GoalPaceMode.maintenance
              ? 'Body Recomposition'
              : 'Muscle Gain';
    }
    if (primaryGoal == ProfileGoal.loseWeight) {
      return mode == GoalPaceMode.loss ? 'Fat Loss' : 'Healthy Target';
    }
    return isMaintenance
        ? 'Maintenance'
        : isLoss
            ? 'Fat Loss'
            : 'Muscle Gain';
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(TioRadius.medium),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: colors.textPrimary,
          fontSize: 16,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(TioRadius.medium),
      ),
      child: Text(
        text,
        style: textTheme.labelSmall?.copyWith(
          color: colors.onPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
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

    final startY = isLoss ? 12.0 : h - 24.0;
    final endY = isLoss ? h - 24.0 : 12.0;

    final path = Path();
    path.moveTo(0, startY);
    path.cubicTo(w * 0.4, startY, w * 0.6, endY, w, endY);

    // Gradient fill below/above curve
    final fillPath = Path.from(path);
    fillPath.lineTo(w, h);
    fillPath.lineTo(0, h);
    fillPath.close();

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isLoss
            ? [
                graphColor.withValues(alpha: 0.28),
                graphColor.withValues(alpha: 0.02),
              ]
            : [
                graphColor.withValues(alpha: 0.28),
                graphColor.withValues(alpha: 0.02),
              ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, gradientPaint);

    // Smooth stroke
    final strokePaint = Paint()
      ..color = graphColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    // Endpoint dots
    final dotPaint = Paint()
      ..color = graphColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(0, startY), 5.0, dotPaint);
    canvas.drawCircle(Offset(w, endY), 5.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _ProjectionGraphPainter oldDelegate) {
    return oldDelegate.isLoss != isLoss || oldDelegate.graphColor != graphColor;
  }
}
