import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../buttons/buttons.dart';
import '../cards/tio_card.dart';

enum TioConfirmationIntent { standard, destructive }

/// Presents the reusable confirmation interaction in the standard modal shell.
///
/// The presenter owns confirm/cancel result semantics and composes its visual
/// surface from the base [TioCard] and semantic [TioButton] variants. It does
/// not expose a workflow-shaped confirmation-card component.
Future<bool?> showTioConfirmationBottomSheet({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  Key? cardKey,
  Widget? icon,
  TioConfirmationIntent intent = TioConfirmationIntent.standard,
  ValueListenable<bool>? activeWhileOpen,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: TioPalette.transparent,
    builder: (sheetContext) => _TioConfirmationRouteGuard(
      activeWhileOpen: activeWhileOpen,
      child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(TioSpacing.lg),
        child: _TioConfirmationContent(
          key: cardKey,
          icon: icon,
          title: title,
          message: message,
          cancelLabel: cancelLabel,
          confirmLabel: confirmLabel,
          intent: intent,
          onCancel: () => Navigator.of(sheetContext).pop(false),
          onConfirm: () => Navigator.of(sheetContext).pop(true),
        ),
      ),
      ),
    ),
  );
}

/// Optional owner/session lifecycle binding for a modal presented over another
/// editor. It removes only this confirmation route, never an unrelated route.
class _TioConfirmationRouteGuard extends StatefulWidget {
  const _TioConfirmationRouteGuard({
    required this.child,
    this.activeWhileOpen,
  });

  final Widget child;
  final ValueListenable<bool>? activeWhileOpen;

  @override
  State<_TioConfirmationRouteGuard> createState() =>
      _TioConfirmationRouteGuardState();
}

class _TioConfirmationRouteGuardState
    extends State<_TioConfirmationRouteGuard> {
  ModalRoute<dynamic>? _route;
  NavigatorState? _navigator;
  bool _dismissQueued = false;

  @override
  void initState() {
    super.initState();
    widget.activeWhileOpen?.addListener(_onActiveChanged);
  }

  @override
  void didUpdateWidget(covariant _TioConfirmationRouteGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.activeWhileOpen, widget.activeWhileOpen)) {
      oldWidget.activeWhileOpen?.removeListener(_onActiveChanged);
      widget.activeWhileOpen?.addListener(_onActiveChanged);
      _onActiveChanged();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    _navigator = Navigator.of(context);
    _onActiveChanged();
  }

  void _onActiveChanged() {
    if (widget.activeWhileOpen?.value != false || _dismissQueued) return;
    _dismissQueued = true;
    final route = _route;
    final navigator = _navigator;
    // The enclosing editor may itself be removed during an owner switch.
    // Capture this exact route before deactivation; do not pop top-of-stack.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator == null || !navigator.mounted ||
          route == null || !route.isActive) {
        return;
      }
      navigator.removeRoute(route);
    });
  }

  @override
  void dispose() {
    widget.activeWhileOpen?.removeListener(_onActiveChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.activeWhileOpen;
    if (active == null) return widget.child;
    return ValueListenableBuilder<bool>(
      valueListenable: active,
      builder: (context, isActive, _) =>
          isActive ? widget.child : const SizedBox.shrink(),
    );
  }
}

class _TioConfirmationContent extends StatelessWidget {
  const _TioConfirmationContent({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
    required this.onCancel,
    required this.intent,
    super.key,
    this.icon,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final Widget? icon;
  final TioConfirmationIntent intent;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    final confirmButton = switch (intent) {
      TioConfirmationIntent.standard => TioButton.primary(
          label: confirmLabel,
          onPressed: onConfirm,
          expand: true,
        ),
      TioConfirmationIntent.destructive => TioButton.destructive(
          label: confirmLabel,
          onPressed: onConfirm,
          expand: true,
        ),
    };

    return TioCard(
      variant: TioCardVariant.elevated,
      padding: const EdgeInsets.all(TioSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            IconTheme(
              data: IconThemeData(
                color: colors.textPrimary,
                size: TioSize.dp24,
              ),
              child: icon!,
            ),
            const SizedBox(height: TioSpacing.md),
          ],
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              color: colors.textPrimary,
              fontWeight: TioFontWeight.w700,
            ),
          ),
          const SizedBox(height: TioSpacing.sm),
          Text(
            message,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              height: TioLineHeight.height140,
            ),
          ),
          const SizedBox(height: TioSpacing.xl),
          Row(
            children: [
              Expanded(
                child: TioButton.secondary(
                  label: cancelLabel,
                  onPressed: onCancel,
                  expand: true,
                ),
              ),
              const SizedBox(width: TioSpacing.md),
              Expanded(child: confirmButton),
            ],
          ),
        ],
      ),
    );
  }
}
