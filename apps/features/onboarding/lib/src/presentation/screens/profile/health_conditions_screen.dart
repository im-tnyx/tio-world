import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'profile_screen_components.dart';

class HealthConditionsScreen extends StatelessWidget {
  const HealthConditionsScreen({
    required this.selectedConditions,
    required this.otherText,
    required this.onToggled,
    required this.onOtherTextChanged,
    super.key,
    this.errorText,
  });

  final Set<ProfileHealthCondition> selectedConditions;
  final String otherText;
  final ValueChanged<ProfileHealthCondition> onToggled;
  final ValueChanged<String> onOtherTextChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final otherSelected =
        selectedConditions.contains(ProfileHealthCondition.other);

    return ProfileScreenScaffold(
      stepId: ProfileStepId.healthConditions,
      title: 'Are you managing any health conditions?',
      description:
          'This step is optional. Select all that apply, or choose None.',
      errorText: errorText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final condition in ProfileHealthCondition.values) ...[
            if (condition == ProfileHealthCondition.other)
              _OtherConditionCard(
                isSelected: otherSelected,
                otherText: otherText,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onToggled(ProfileHealthCondition.other);
                },
                onTextChanged: onOtherTextChanged,
              )
            else
              ProfileChoiceCard(
                id: 'health-${condition.name}',
                title: _label(condition),
                selected: selectedConditions.contains(condition),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onToggled(condition);
                },
              ),
            const SizedBox(height: TioSpacing.medium),
          ],
        ],
      ),
    );
  }
}

class _OtherConditionCard extends StatefulWidget {
  const _OtherConditionCard({
    required this.isSelected,
    required this.otherText,
    required this.onTap,
    required this.onTextChanged,
  });

  final bool isSelected;
  final String otherText;
  final VoidCallback onTap;
  final ValueChanged<String> onTextChanged;

  @override
  State<_OtherConditionCard> createState() => _OtherConditionCardState();
}

class _OtherConditionCardState extends State<_OtherConditionCard> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.otherText);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _OtherConditionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.otherText != _controller.text) {
      _controller.text = widget.otherText;
    }
    if (widget.isSelected && !oldWidget.isSelected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);

    return Material(
      color: widget.isSelected
          ? colors.primary.withValues(alpha: TioCardTokens.selectedContainerAlpha)
          : colors.surface,
      borderRadius: BorderRadius.circular(TioCardTokens.radius),
      child: InkWell(
        key: const ValueKey('health-other'),
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(TioCardTokens.radius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(TioSpacing.large),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(TioCardTokens.radius),
            border: Border.all(
              color: widget.isSelected
                  ? colors.primary
                  : colors.outlineStrong.withValues(alpha: 0.35),
              width: widget.isSelected
                  ? TioCardTokens.selectedBorderWidth
                  : TioCardTokens.unselectedBorderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Title + Radio/Check Icon (Exact match with ProfileChoiceCard)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Other',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w700,
                        color: widget.isSelected ? colors.primary : colors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    widget.isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 24,
                    color: widget.isSelected ? colors.primary : colors.outlineStrong,
                  ),
                ],
              ),

              // Seamless Inline Input directly on the card surface (100% pure transparent background)
              if (widget.isSelected) ...[
                const SizedBox(height: 6),
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  minLines: 1,
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                  cursorColor: colors.primary,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textPrimary,
                    height: 1.3,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: 'e.g. Asthma, Thyroid, Joint pain...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary.withAlpha(140),
                    ),
                  ),
                  onChanged: widget.onTextChanged,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _label(ProfileHealthCondition condition) => switch (condition) {
      ProfileHealthCondition.none => 'None',
      ProfileHealthCondition.diabetes => 'Diabetes',
      ProfileHealthCondition.hypertension => 'Hypertension',
      ProfileHealthCondition.lowBloodPressure => 'Low blood pressure',
      ProfileHealthCondition.other => 'Other',
    };
