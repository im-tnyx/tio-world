import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// Shared presentation-only pinned actions for [TioEditorSheet].
/// Leading/trailing controls, primary action, note and identifiers remain
/// feature-owned. Use with TioEditorSheet.flushActions: true.
class TioEditorActionFooter extends StatelessWidget {
  const TioEditorActionFooter({
    required this.leading,
    required this.trailing,
    required this.primary,
    super.key,
    this.note,
    this.dividerKey,
  });

  final Widget leading;
  final Widget trailing;
  final Widget primary;
  final Widget? note;
  final Key? dividerKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: TioStroke.width1,
          child: OverflowBox(
            maxWidth: double.infinity,
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width,
              child: Divider(
                key: dividerKey,
                height: TioStroke.width1,
                thickness: TioStroke.width1,
                color: colors.outlineStrong.withAlpha(TioAlpha.alpha20),
              ),
            ),
          ),
        ),
        Row(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width / 2,
              ),
              child: leading,
            ),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: trailing,
              ),
            ),
          ],
        ),
        if (note != null) ...[
          const SizedBox(height: TioSpacing.md),
          note!,
        ],
        const SizedBox(height: TioSpacing.xs),
        primary,
      ],
    );
  }
}

/// One control on the footer's top line.
///
/// The caller builds the content because the two differ: the category is a
/// word followed by its chevron, the date is a glyph followed by its value.
/// What is shared is the part that must not differ — the text and icon
/// treatment, and the fact that a null [onTap] means disabled, dimmed and
/// reported as such rather than merely inert.
class TioEditorFooterAction extends StatelessWidget {
  const TioEditorFooterAction({
    required this.controlKey,
    required this.semanticLabel,
    required this.builder,
    this.onTap,
    super.key,
  });

  final Key controlKey;
  final String semanticLabel;
  final Widget Function(
    BuildContext context,
    TextStyle textStyle,
    Color iconColor,
  ) builder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final isEnabled = onTap != null;
    final content = builder(
      context,
      TextStyle(
        color: colors.textPrimary,
        fontSize: TioFontSize.size15,
        fontWeight: TioFontWeight.w600,
      ),
      isEnabled ? colors.textPrimary : colors.textMuted,
    );

    return Semantics(
      key: controlKey,
      button: true,
      enabled: isEnabled,
      label: semanticLabel,
      onTap: onTap,
      child: ExcludeSemantics(
        child: isEnabled
            // A real target once this path is live. This compact footer keeps
            // its approved 44dp control height while retaining InkWell focus
            // and ripple behavior instead of relying on a bare detector.
            ? Material(
                color: TioPalette.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(TioRadius.sm),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: TioSize.dp44,
                      minWidth: TioSize.dp48,
                    ),
                    child: Padding(
                      // Keep the fixed target while reserving 2dp below its
                      // content, which shifts the visual baseline up by 1dp.
                      padding: const EdgeInsets.only(
                        left: TioSpacing.xs,
                        right: TioSpacing.xs,
                        bottom: TioSize.dp2,
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: 1,
                        child: content,
                      ),
                    ),
                  ),
                ),
              )
            : Opacity(
                opacity: TioOpacity.opacity64,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: TioSize.dp2),
                  child: content,
                ),
              ),
      ),
    );
  }
}
