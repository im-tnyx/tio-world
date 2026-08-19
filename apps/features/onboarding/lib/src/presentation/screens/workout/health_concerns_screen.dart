import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'workout_screen_components.dart';

class HealthConcernsScreen extends StatefulWidget {
  const HealthConcernsScreen({
    required this.value,
    required this.flowPlan,
    required this.onChanged,
    super.key,
    this.errorText,
  });

  final String value;
  final WorkoutFlowPlan flowPlan;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  State<HealthConcernsScreen> createState() => _HealthConcernsScreenState();
}

class _HealthConcernsScreenState extends State<HealthConcernsScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant HealthConcernsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return WorkoutScreenScaffold(
      stepId: WorkoutStepId.healthConcerns,
      flowPlan: widget.flowPlan,
      title: 'Any health concerns?',
      description:
          'Share any injuries, pain, or conditions so Tio can adapt your workouts safely.',
      errorText: widget.errorText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONCERNS & LIMITATIONS',
            style: textTheme.labelSmall?.copyWith(
              fontSize: TioFontSize.size12,
              fontWeight: TioFontWeight.w700,
              letterSpacing: TioLetterSpacing.positive08,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: TioSpacing.sm),
          Container(
            key: const ValueKey('workout-health-concerns-input'),
            child: TextFormField(
              controller: _controller,
              onChanged: widget.onChanged,
              maxLines: 6,
              minLines: 4,
              textAlignVertical: TextAlignVertical.top,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
              style: textTheme.bodyLarge?.copyWith(
                fontSize: TioFontSize.size15,
                color: colors.textPrimary,
                height: TioLineHeight.height140,
              ),
              decoration: InputDecoration(
                hintText: 'E.g. Knee pain, back ache, asthma...',
                hintStyle: textTheme.bodyLarge?.copyWith(
                  fontSize: TioFontSize.size14,
                  color: colors.textSecondary.withValues(
                    alpha: TioOpacity.opacity50,
                  ),
                  height: TioLineHeight.height140,
                ),
                contentPadding: const EdgeInsets.all(TioSpacing.lg),
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TioRadius.lg),
                  borderSide: BorderSide(
                    color: colors.outlineStrong.withValues(
                      alpha: TioCardTokens.unselectedOutlineAlpha,
                    ),
                    width: TioCardTokens.unselectedBorderWidth,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TioRadius.lg),
                  borderSide: BorderSide(
                    color: colors.outlineStrong.withValues(
                      alpha: TioCardTokens.unselectedOutlineAlpha,
                    ),
                    width: TioCardTokens.unselectedBorderWidth,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TioRadius.lg),
                  borderSide: BorderSide(
                    color: colors.primary,
                    width: TioCardTokens.selectedBorderWidth,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: TioSpacing.sm),
          Text(
            '(OPTIONAL)',
            style: textTheme.labelSmall?.copyWith(
              fontSize: TioFontSize.size11,
              fontWeight: TioFontWeight.w600,
              letterSpacing: TioLetterSpacing.positive06,
              color: colors.textSecondary.withValues(
                alpha: TioOpacity.opacity60,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
