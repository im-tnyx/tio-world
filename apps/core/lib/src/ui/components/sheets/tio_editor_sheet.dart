import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// Opens a [TioEditorSheet].
///
/// Route-level dragging and Flutter's own drag handle are both disabled: the
/// sheet's handle owns dismissal, because a route-level drag can bypass a
/// child `PopScope` and tear down a sheet mid-save.
///
/// [useRootNavigator] is forwarded unchanged and defaults to Flutter's own
/// `false`. A caller inside a nested navigator — a `StatefulShellRoute` branch,
/// say — passes true so the barrier covers the chrome outside that branch
/// rather than leaving it live behind the sheet. Core does not decide this:
/// only the caller knows which navigator its editor belongs above.
Future<T?> showTioEditorSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool useRootNavigator = false,
}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: useRootNavigator,
      backgroundColor: TioPalette.transparent,
      enableDrag: false,
      showDragHandle: false,
      builder: builder,
    );

/// The canonical editable modal surface.
///
/// Distinct from [TioSheet], which is the general/display sheet. This one owns
/// the chrome an editor needs — handle, header, scrollable content, pinned
/// actions, keyboard-safe insets — so features supply only content and
/// actions.
///
/// ## Actions are pinned, never scrolled
///
/// [actions] live outside the scroll view by construction. Inside it, a tall
/// sheet with the keyboard raised pushes the commit button below the fold, and
/// the user cannot save what they just typed without first discovering a
/// scroll. That defect was found on a real device once already; making the
/// structure prevent it is the reason this component exists.
class TioEditorSheet extends StatelessWidget {
  const TioEditorSheet({
    required this.title,
    required this.content,
    super.key,
    this.supportingText,
    this.actions,
    this.canDismiss = true,
    this.titleTrailing,
    this.flushActions = false,
  });

  final String title;

  /// Optional short explanation under the title.
  final String? supportingText;

  /// Optional affordance on the title row, right-aligned — for example a
  /// wheel/manual mode switch. Omitting it keeps a plain title row.
  final Widget? titleTrailing;

  /// The editor body. Scrolls independently of [actions].
  final Widget content;

  /// The commit region. Pinned below the scroll view; null renders no region
  /// at all rather than an empty gap.
  final Widget? actions;

  /// Whether [actions] begin immediately below the scroll view, with no gap.
  ///
  /// False by default, so the standard [TioEditorSheetTokens.actionGap] still
  /// separates the body from the commit region and no existing sheet moves.
  ///
  /// Pass true when the action region draws its own boundary — a rule across
  /// the sheet, say. The gap and a separator are two ways of saying the same
  /// thing, and doing both leaves a band of dead space above the line that
  /// reads as content having been cut off.
  final bool flushActions;

  /// Whether the handle may dismiss the sheet. Set false while a save is in
  /// flight so a drag cannot discard work mid-write.
  final bool canDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        key: const ValueKey('tio-editor-sheet'),
        color: colors.surfaceRaised,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(TioEditorSheetTokens.radius),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(TioEditorSheetTokens.padding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: _TioEditorSheetHandle(
                    canDismiss: canDismiss,
                    color: colors.outlineStrong.withAlpha(TioAlpha.alpha50),
                  ),
                ),
                const SizedBox(height: TioEditorSheetTokens.handleGap),
                Flexible(
                  fit: FlexFit.loose,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(colors),
                        SizedBox(
                          height: titleTrailing == null
                              ? TioEditorSheetTokens.headerGap
                              : TioEditorSheetTokens.headerGapWithTrailing,
                        ),
                        content,
                      ],
                    ),
                  ),
                ),
                if (actions != null) ...[
                  if (!flushActions)
                    const SizedBox(height: TioEditorSheetTokens.actionGap),
                  actions!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(TioColors colors) {
    final titleText = Text(
      title,
      style: TextStyle(
        color: colors.textPrimary,
        fontWeight: TioFontWeight.w700,
        fontSize: TioFontSize.size18,
      ),
    );

    final titleRow = titleTrailing == null
        ? titleText
        : Row(
            children: [
              Expanded(child: titleText),
              titleTrailing!,
            ],
          );

    if (supportingText == null) return titleRow;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        titleRow,
        const SizedBox(height: TioSpacing.sm),
        Text(
          supportingText!,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: TioFontSize.size13,
          ),
        ),
      ],
    );
  }
}

/// The sheet's only dismissal affordance.
///
/// Route-level drag is disabled by [showTioEditorSheet], so this handle is the
/// single place that decides whether a drag may close the sheet — which is what
/// lets [TioEditorSheet.canDismiss] hold it shut during a save.
class _TioEditorSheetHandle extends StatefulWidget {
  const _TioEditorSheetHandle({
    required this.canDismiss,
    required this.color,
  });

  final bool canDismiss;
  final Color color;

  @override
  State<_TioEditorSheetHandle> createState() => _TioEditorSheetHandleState();
}

class _TioEditorSheetHandleState extends State<_TioEditorSheetHandle> {
  var _dragDistance = 0.0;

  void _startDrag(DragStartDetails details) {
    _dragDistance = 0;
  }

  void _updateDrag(DragUpdateDetails details) {
    _dragDistance += details.primaryDelta ?? 0;
  }

  void _endDrag(DragEndDetails details) {
    if (widget.canDismiss &&
        _dragDistance >= TioEditorSheetTokens.handleDismissThreshold) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        key: const ValueKey('tio-editor-sheet-handle'),
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: _startDrag,
        onVerticalDragUpdate: _updateDrag,
        onVerticalDragEnd: _endDrag,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: TioEditorSheetTokens.handlePadding,
          ),
          child: Container(
            width: TioEditorSheetTokens.handleWidth,
            height: TioEditorSheetTokens.handleHeight,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(
                TioEditorSheetTokens.handleRadius,
              ),
            ),
          ),
        ),
      );
}
