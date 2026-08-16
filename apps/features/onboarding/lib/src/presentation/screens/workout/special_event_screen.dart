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
    final colors = TioTheme.colors(context);
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
          Container(
            key: const ValueKey('workout-special-event-input'),
            child: TextFormField(
              controller: _controller,
              onChanged: widget.onChanged,
              maxLines: 4,
              minLines: 3,
              textAlignVertical: TextAlignVertical.top,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
              style: textTheme.bodyLarge?.copyWith(
                fontSize: 15,
                color: colors.textPrimary,
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText:
                    'e.g., Hyrox, Marathon, Triathlon, Spartan Race, Ironman...',
                hintStyle: textTheme.bodyLarge?.copyWith(
                  fontSize: 14,
                  color: colors.textSecondary.withValues(alpha: 0.5),
                  height: 1.4,
                ),
                contentPadding: const EdgeInsets.all(TioSpacing.large),
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TioRadius.large),
                  borderSide: BorderSide(
                    color: colors.outlineStrong.withValues(
                      alpha: TioCardTokens.unselectedOutlineAlpha,
                    ),
                    width: TioCardTokens.unselectedBorderWidth,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TioRadius.large),
                  borderSide: BorderSide(
                    color: colors.outlineStrong.withValues(
                      alpha: TioCardTokens.unselectedOutlineAlpha,
                    ),
                    width: TioCardTokens.unselectedBorderWidth,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TioRadius.large),
                  borderSide: BorderSide(
                    color: colors.primary,
                    width: TioCardTokens.selectedBorderWidth,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: TioSpacing.medium),
          Text(
            "Leave blank if you're not training for a specific event",
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: colors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
