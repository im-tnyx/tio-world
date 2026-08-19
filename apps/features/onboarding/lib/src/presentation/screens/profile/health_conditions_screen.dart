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
            const SizedBox(height: TioSpacing.md),
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
        if (mounted) {
          _focusNode.requestFocus();
          Scrollable.ensureVisible(
            context,
            alignment: 0.85,
            duration: const Duration(milliseconds: TioDuration.ms200),
            curve: Curves.easeOutCubic,
          );
        }
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
    final colors = context.tioColors;

    return Material(
      color: widget.isSelected
          ? colors.primary.withValues(
              alpha: TioCardTokens.selectedContainerAlpha,
            )
          : colors.surface,
      borderRadius: BorderRadius.circular(TioCardTokens.radius),
      child: InkWell(
        key: const ValueKey('health-other'),
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(TioCardTokens.radius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: TioDuration.ms150),
          padding: const EdgeInsets.all(TioSpacing.lg),
          decoration: BoxDecoration(
            // Transparent composition lets the Material surface above own the
            // visible selected/unselected card fill.
            color: TioPalette.transparent,
            borderRadius: BorderRadius.circular(TioCardTokens.radius),
            border: Border.all(
              color: widget.isSelected
                  ? colors.primary
                  : colors.outlineStrong.withValues(
                      alpha: TioOpacity.opacity35,
                    ),
              width: widget.isSelected
                  ? TioCardTokens.selectedBorderWidth
                  : TioCardTokens.unselectedBorderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Other',
                      style: TextStyle(
                        fontSize: TioFontSize.size16,
                        fontWeight: TioFontWeight.w700,
                        color: widget.isSelected
                            ? colors.primary
                            : colors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    widget.isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: TioSize.dp24,
                    color: widget.isSelected
                        ? colors.primary
                        : colors.outlineStrong,
                  ),
                ],
              ),
              if (widget.isSelected) ...[
                const SizedBox(height: TioSize.dp6),
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  minLines: 1,
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                  scrollPadding: const EdgeInsets.only(bottom: TioSize.dp110),
                  cursorColor: colors.primary,
                  style: TextStyle(
                    fontSize: TioFontSize.size14,
                    color: colors.textPrimary,
                    height: TioLineHeight.height130,
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
                      fontSize: TioFontSize.size13,
                      color: colors.textSecondary.withAlpha(TioAlpha.alpha140),
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
