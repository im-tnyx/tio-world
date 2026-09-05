import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// The Meal Diary's contextual `+`.
///
/// Kept here rather than promoted to `apps/core` on purpose. There is no
/// floating action affordance anywhere in the repository yet and `TioTheme`
/// configures no `FloatingActionButtonThemeData`, so a raw Material FAB would
/// draw colours the design system does not own. A core component, meanwhile,
/// needs reuse evidence this has none of: the Meal Diary is the only screen
/// that wants it, and its visibility rule — it steps aside for the expanded
/// month grid — is a Meal Diary concern the shell has no business knowing.
/// So this is a one-off composition built from governed core values, which is
/// exactly what `apps/features/AGENTS.md` asks for in that situation.
///
/// It lives in the page body rather than a `Scaffold` slot because `TioShell`
/// owns the `Scaffold` and exposes no action slot. The body sits above the
/// bottom navigation by construction, so nothing here has to reason about the
/// nav's height.
class MealDiaryLogAction extends StatelessWidget {
  const MealDiaryLogAction({required this.onPressed, super.key});

  static const _label = 'Add food';

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Semantics(
      button: true,
      // Stated rather than left implicit, so the node carries an enabled
      // state a screen reader can read out — the same contract TioButton and
      // the sheet's unavailable rows report.
      enabled: true,
      label: _label,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: Tooltip(
          message: _label,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: context.tioShadows.soft,
            ),
            child: Material(
              color: colors.primary,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPressed,
                child: SizedBox(
                  width: TioSize.dp56,
                  height: TioSize.dp56,
                  child: Icon(
                    Icons.add_rounded,
                    size: TioSize.dp28,
                    color: colors.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
