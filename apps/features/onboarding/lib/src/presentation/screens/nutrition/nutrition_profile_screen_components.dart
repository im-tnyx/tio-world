import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import '../profile/profile_screen_components.dart';

class NutritionProfileScreenScaffold extends StatelessWidget {
  const NutritionProfileScreenScaffold({
    required this.stepId,
    required this.title,
    required this.description,
    required this.child,
    super.key,
    this.errorText,
  });

  final NutritionProfileStepId stepId;
  final String title;
  final String description;
  final Widget child;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    const flow = NutritionProfileFlowPlan();
    final stepNumber = flow.indexOf(stepId) + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label:
              'Nutrition profile step $stepNumber of ${flow.stepCount}, $title',
          value: '$stepNumber of ${flow.stepCount}',
          header: true,
          container: true,
          explicitChildNodes: true,
          child: TioScreenHeader(title: title, subtitle: description),
        ),
        const SizedBox(height: TioSpacing.lg),
        child,
        if (errorText case final message?) ...[
          const SizedBox(height: TioSpacing.md),
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              key: ValueKey('nutrition-profile-${stepId.name}-error'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}

class NutritionProfileChoiceCard extends StatelessWidget {
  const NutritionProfileChoiceCard({
    required this.id,
    required this.title,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String id;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ProfileChoiceCard(
      id: id,
      title: title,
      selected: selected,
      onTap: onTap,
    );
  }
}

/// Health-style `Other` choice card used by Nutrition Profile child screens.
///
/// The input is intentionally optional, matching Health Conditions. Selection
/// ownership remains with the parent screen/controller while this widget owns
/// only focus and local TextEditingController lifecycle.
class NutritionProfileOtherChoiceCard extends StatefulWidget {
  const NutritionProfileOtherChoiceCard({
    required this.id,
    required this.selected,
    required this.value,
    required this.hintText,
    required this.onTap,
    required this.onTextChanged,
    super.key,
  });

  final String id;
  final bool selected;
  final String value;
  final String hintText;
  final VoidCallback onTap;
  final ValueChanged<String> onTextChanged;

  @override
  State<NutritionProfileOtherChoiceCard> createState() =>
      _NutritionProfileOtherChoiceCardState();
}

class _NutritionProfileOtherChoiceCardState
    extends State<NutritionProfileOtherChoiceCard> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant NutritionProfileOtherChoiceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
    if (widget.selected && !oldWidget.selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focusNode.requestFocus();
        Scrollable.ensureVisible(
          context,
          alignment: 0.85,
          duration: const Duration(milliseconds: TioDuration.ms200),
          curve: Curves.easeOutCubic,
        );
      });
    } else if (!widget.selected && oldWidget.selected) {
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
      color: widget.selected
          ? colors.primary.withValues(
              alpha: TioCardTokens.selectedContainerAlpha,
            )
          : colors.surface,
      borderRadius: BorderRadius.circular(TioCardTokens.radius),
      child: InkWell(
        key: ValueKey(widget.id),
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(TioCardTokens.radius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: TioDuration.ms150),
          padding: const EdgeInsets.all(TioSpacing.lg),
          decoration: BoxDecoration(
            color: TioPalette.transparent,
            borderRadius: BorderRadius.circular(TioCardTokens.radius),
            border: Border.all(
              color: widget.selected
                  ? colors.primary
                  : colors.outlineStrong.withValues(
                      alpha: TioOpacity.opacity35,
                    ),
              width: widget.selected
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
                        color: widget.selected
                            ? colors.primary
                            : colors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    widget.selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: TioSize.dp24,
                    color: widget.selected
                        ? colors.primary
                        : colors.outlineStrong,
                  ),
                ],
              ),
              if (widget.selected) ...[
                const SizedBox(height: TioSize.dp6),
                TextField(
                  key: ValueKey('${widget.id}-text-field'),
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
                    hintText: widget.hintText,
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
