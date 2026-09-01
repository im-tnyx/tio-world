import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'workout_screen_components.dart';

class SpecialEventScreen extends StatefulWidget {
  const SpecialEventScreen({
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
  State<SpecialEventScreen> createState() => _SpecialEventScreenState();
}

class _SpecialEventScreenState extends State<SpecialEventScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant SpecialEventScreen oldWidget) {
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
      stepId: WorkoutStepId.specialEvent,
      flowPlan: widget.flowPlan,
      title: 'Are you training for a special event?',
      description:
          "Tell us about any competition, race, or event you're preparing for",
      errorText: widget.errorText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TioInput.multiline(
            key: const ValueKey('workout-special-event-input'),
            controller: _controller,
            onChanged: widget.onChanged,
            maxLines: 4,
            minLines: 3,
            textAlignVertical: TextAlignVertical.top,
            keyboardType: TextInputType.multiline,
            hint: 'e.g., Hyrox, Marathon, Triathlon, Spartan Race, Ironman...',
            hintStyle: textTheme.bodyLarge?.copyWith(
              fontSize: TioFontSize.size14,
              color: colors.textSecondary.withValues(
                alpha: TioOpacity.opacity50,
              ),
              height: TioLineHeight.height140,
            ),
            textStyle: textTheme.bodyLarge?.copyWith(
              fontSize: TioFontSize.size15,
              color: colors.textPrimary,
              height: TioLineHeight.height140,
            ),
          ),
          const SizedBox(height: TioSpacing.md),
          Text(
            "Leave blank if you're not training for a specific event",
            style: textTheme.bodyMedium?.copyWith(
              fontSize: TioFontSize.size13,
              fontStyle: FontStyle.italic,
              color: colors.textSecondary.withValues(
                alpha: TioOpacity.opacity70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
