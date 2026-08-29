import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Opens a Settings-owned Daily Wellness editor with one visible sheet surface.
///
/// The outer Material bottom sheet is transparent. This widget owns the only
/// visible `surfaceRaised` container so Settings can keep its editor family
/// visually consistent without changing Core's general-purpose [TioSheet].
Future<T?> showDailyWellnessEditorSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TioPalette.transparent,
      // Flutter's route-level drag can bypass a child PopScope. The local
      // handle below owns dismissal so Glass can disable it while saving.
      enableDrag: false,
      showDragHandle: false,
      builder: builder,
    );

/// Shared visual shell for the Settings-only Step, Water and Glass editors.
class DailyWellnessEditorSheet extends StatelessWidget {
  const DailyWellnessEditorSheet({
    required this.title,
    required this.content,
    super.key,
    this.supportingText,
    this.actions,
    this.canDismiss = true,
  });

  final String title;
  final String? supportingText;
  final Widget content;
  final Widget? actions;
  final bool canDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        key: const ValueKey('daily-wellness-editor-sheet'),
        color: colors.surfaceRaised,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(TioRadius.lg),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(TioSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: _DailyWellnessSheetHandle(
                    canDismiss: canDismiss,
                    color: colors.outlineStrong.withAlpha(TioAlpha.alpha50),
                  ),
                ),
                const SizedBox(height: TioSpacing.md),
                Flexible(
                  fit: FlexFit.loose,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: TioFontWeight.w700,
                            fontSize: TioFontSize.size18,
                          ),
                        ),
                        if (supportingText != null) ...[
                          const SizedBox(height: TioSpacing.sm),
                          Text(
                            supportingText!,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: TioFontSize.size13,
                            ),
                          ),
                        ],
                        const SizedBox(height: TioSpacing.lg),
                        content,
                        if (actions != null) ...[
                          const SizedBox(height: TioSpacing.md),
                          actions!,
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyWellnessSheetHandle extends StatefulWidget {
  const _DailyWellnessSheetHandle({
    required this.canDismiss,
    required this.color,
  });

  final bool canDismiss;
  final Color color;

  @override
  State<_DailyWellnessSheetHandle> createState() =>
      _DailyWellnessSheetHandleState();
}

class _DailyWellnessSheetHandleState extends State<_DailyWellnessSheetHandle> {
  var _dragDistance = 0.0;

  void _startDrag(DragStartDetails details) {
    _dragDistance = 0;
  }

  void _updateDrag(DragUpdateDetails details) {
    _dragDistance += details.primaryDelta ?? 0;
  }

  void _endDrag(DragEndDetails details) {
    if (widget.canDismiss && _dragDistance >= TioSize.dp36) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        key: const ValueKey('daily-wellness-editor-sheet-handle'),
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: _startDrag,
        onVerticalDragUpdate: _updateDrag,
        onVerticalDragEnd: _endDrag,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: TioSpacing.xs),
          child: Container(
            width: TioSize.dp36,
            height: TioSize.dp4,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(TioSize.dp2),
            ),
          ),
        ),
      );
}
