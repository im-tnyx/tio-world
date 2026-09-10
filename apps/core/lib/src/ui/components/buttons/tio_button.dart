import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// Semantic intent of a [TioButton], never a feature or a surface.
///
/// [destructive] is the shared contract for an action that removes or
/// permanently changes something. It renders on the same filled chassis as
/// [primary], with a translucent `danger` tint behind `danger` content and no
/// outline. This is the owner-approved canonical direction for the variant;
/// the Delete Account dialog already renders that treatment locally, which is
/// the evidence behind it, though it does not consume this variant yet.
///
/// Because the container is a translucent tint rather than an opaque danger
/// surface, the label reads against the surface beneath it and no `onDanger`
/// foreground role is needed.
///
/// Existing destructive confirmations have not all converged here:
/// `TioConfirmationCard` still routes confirm through [primary]. Those
/// migrations are separate #173 slices.
enum TioButtonVariant { primary, secondary, ghost, destructive }

class TioButton extends StatelessWidget {
  const TioButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = TioButtonVariant.primary,
    this.enabled = true,
    this.expand = false,
    this.loading = false,
    this.loadingLabel,
    this.semanticLabel,
    this.leading,
    this.trailing,
  });

  const TioButton.primary({
    required this.label,
    required this.onPressed,
    super.key,
    this.enabled = true,
    this.expand = false,
    this.loading = false,
    this.loadingLabel,
    this.semanticLabel,
    this.leading,
    this.trailing,
  }) : variant = TioButtonVariant.primary;

  const TioButton.secondary({
    required this.label,
    required this.onPressed,
    super.key,
    this.enabled = true,
    this.expand = false,
    this.loading = false,
    this.loadingLabel,
    this.semanticLabel,
    this.leading,
    this.trailing,
  }) : variant = TioButtonVariant.secondary;

  const TioButton.ghost({
    required this.label,
    required this.onPressed,
    super.key,
    this.enabled = true,
    this.expand = false,
    this.loading = false,
    this.loadingLabel,
    this.semanticLabel,
    this.leading,
    this.trailing,
  }) : variant = TioButtonVariant.ghost;

  /// The shared destructive action: remove, delete, discard.
  ///
  /// Same geometry, height, radius, typography and content gap as every
  /// other [TioButton] — only the colour role differs. Callers choose the
  /// intent; they do not rebuild destructive chrome locally.
  const TioButton.destructive({
    required this.label,
    required this.onPressed,
    super.key,
    this.enabled = true,
    this.expand = false,
    this.loading = false,
    this.loadingLabel,
    this.semanticLabel,
    this.leading,
    this.trailing,
  }) : variant = TioButtonVariant.destructive;

  final String label;
  final VoidCallback? onPressed;
  final TioButtonVariant variant;
  final bool enabled;
  final bool expand;
  final bool loading;
  final String? loadingLabel;
  final String? semanticLabel;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final motion = context.tioMotion;
    final callback = enabled && !loading ? onPressed : null;
    final indicatorColor = switch (variant) {
      TioButtonVariant.primary => colors.onPrimary,
      TioButtonVariant.destructive => colors.danger,
      _ => colors.primary,
    };
    // The destructive variant owns its colours in every state, so it styles
    // itself whether or not an action is in flight. The other three keep the
    // theme's own resting appearance and override it only while loading.
    final style = switch (variant) {
      TioButtonVariant.destructive =>
        _destructiveStyle(colors, loading: loading),
      _ => loading ? _loadingStyle(variant, colors) : null,
    };
    final content = AnimatedSwitcher(
      duration: motion.fast,
      child: loading
          ? _LoadingContent(
              key: const ValueKey('loading'),
              label: loadingLabel ?? label,
              indicatorColor: indicatorColor,
              reducedMotion: motion.reducedMotion,
            )
          : _ButtonContent(
              key: const ValueKey('content'),
              label: label,
              leading: leading,
              trailing: trailing,
            ),
    );
    final widthWrapper =
        expand ? SizedBox(width: double.infinity, child: content) : content;
    final button = switch (variant) {
      // Destructive shares primary's filled chassis, so it inherits the same
      // governed minimum height, pill radius, horizontal padding, typography
      // and tap-target behaviour. Only the colour roles differ.
      TioButtonVariant.primary || TioButtonVariant.destructive => FilledButton(
          onPressed: callback,
          style: style,
          child: widthWrapper,
        ),
      TioButtonVariant.secondary => OutlinedButton(
          onPressed: callback,
          style: style,
          child: widthWrapper,
        ),
      TioButtonVariant.ghost => TextButton(
          onPressed: callback,
          style: style,
          child: widthWrapper,
        ),
    };

    return Semantics(
      button: true,
      enabled: callback != null,
      label: semanticLabel ?? label,
      value: loading ? 'Loading' : null,
      liveRegion: loading,
      onTap: callback,
      child: ExcludeSemantics(child: button),
    );
  }
}

/// Destructive appearance for [TioButtonVariant.destructive].
///
/// Overrides colour roles only. Minimum height, pill radius, horizontal
/// padding and label typography still resolve from the shared
/// `filledButtonTheme`, which is what makes this the same button as every
/// other one rather than a destructive look-alike. No `side` is set, so the
/// variant carries no outline.
///
/// The container is a translucent `danger` tint rather than an opaque danger
/// surface, so `danger` content reads against the surface beneath it and no
/// `onDanger` role is needed.
///
/// Returning null for a genuinely disabled state is deliberate: the framework
/// resolves each property against the states first and only then falls back
/// to the theme, so null here lets the shared `disabledBackgroundColor` /
/// `disabledForegroundColor` apply instead of a second destructive-disabled
/// token family.
///
/// [loading] holds the danger colours while a destructive action is in
/// flight. A loading button is disabled, so without this carve-out that same
/// fall-through would grey out the spinner and label mid-delete.
ButtonStyle _destructiveStyle(TioColors colors, {required bool loading}) {
  bool governedDisabled(Set<WidgetState> states) =>
      !loading && states.contains(WidgetState.disabled);

  return ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) => governedDisabled(states)
          ? null
          : colors.danger.withAlpha(TioAlpha.alpha35),
    ),
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) => governedDisabled(states) ? null : colors.danger,
    ),
    overlayColor: _destructiveStateLayer(colors.danger),
  );
}

/// Pressed/focused/hovered wash for the destructive variant.
///
/// The shared `filledButtonTheme` tints its state layer with `onPrimary`,
/// which would put a light wash over a danger action. Same governed
/// opacities, danger colour.
WidgetStateProperty<Color?> _destructiveStateLayer(Color color) {
  return WidgetStateProperty.resolveWith((states) {
    // Transparent means no Material state overlay; it is an intentional
    // framework state, not a palette color role.
    if (states.contains(WidgetState.disabled)) return Colors.transparent;
    if (states.contains(WidgetState.pressed)) {
      return color.withValues(alpha: TioButtonTokens.pressedStateOpacity);
    }
    if (states.contains(WidgetState.focused)) {
      return color.withValues(alpha: TioButtonTokens.focusedStateOpacity);
    }
    if (states.contains(WidgetState.hovered)) {
      return color.withValues(alpha: TioButtonTokens.hoveredStateOpacity);
    }
    return Colors.transparent;
  });
}

ButtonStyle _loadingStyle(TioButtonVariant variant, TioColors colors) {
  return switch (variant) {
    TioButtonVariant.primary => ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(colors.primary),
        foregroundColor: WidgetStatePropertyAll(colors.onPrimary),
      ),
    TioButtonVariant.secondary => ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(colors.primary),
        side: WidgetStatePropertyAll(
          BorderSide(
            color: colors.primary,
            width: TioButtonTokens.outlineWidth,
          ),
        ),
      ),
    TioButtonVariant.ghost => ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(colors.primary),
      ),
    // Reached only if a caller routes destructive here; the build already
    // styles it directly. Delegating keeps one destructive appearance.
    TioButtonVariant.destructive => _destructiveStyle(colors, loading: true),
  };
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    super.key,
    this.leading,
    this.trailing,
  });

  final String label;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: TioButtonTokens.contentGap),
        ],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        if (trailing != null) ...[
          const SizedBox(width: TioButtonTokens.contentGap),
          trailing!,
        ],
      ],
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent({
    required this.label,
    required this.indicatorColor,
    required this.reducedMotion,
    super.key,
  });

  final String label;
  final Color indicatorColor;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (reducedMotion)
          Icon(
            Icons.hourglass_top,
            size: TioButtonTokens.loadingIndicatorSize,
            color: indicatorColor,
          )
        else
          SizedBox.square(
            dimension: TioButtonTokens.loadingIndicatorSize,
            child: CircularProgressIndicator(
              strokeWidth: TioButtonTokens.loadingIndicatorStrokeWidth,
              color: indicatorColor,
            ),
          ),
        const SizedBox(width: TioButtonTokens.contentGap),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
