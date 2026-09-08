import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Meal Diary-owned contextual actions for the shell top bar.
///
/// App composition supplies navigation while Nutrition owns the visible menu
/// contract. Keeping this separate from the shell means Core never learns
/// about Meal Diary routes or settings semantics.
class MealDiaryMoreMenu extends StatelessWidget {
  const MealDiaryMoreMenu({
    required this.onMealDiarySettingsPressed,
    super.key,
  });

  final VoidCallback onMealDiarySettingsPressed;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      // The panel is transparent and `TioCard` paints the menu, so the panel's
      // padding is the card's margin. It is not decoration: the trigger sits
      // at the right edge, so without it the framework clamps the panel flush
      // against the screen and the card's rounded corner reads as clipped.
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(TioPalette.transparent),
        elevation: WidgetStatePropertyAll(TioElevation.none),
        shadowColor: WidgetStatePropertyAll(TioPalette.transparent),
        surfaceTintColor: WidgetStatePropertyAll(TioPalette.transparent),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: TioSpacing.sm,
            vertical: TioSpacing.xs,
          ),
        ),
      ),
      menuChildren: [
        TioCard(
          key: const ValueKey('meal-diary-settings-menu-card'),
          variant: TioCardVariant.elevated,
          padding: EdgeInsets.zero,
          child: MenuItemButton(
            key: const ValueKey('meal-diary-settings-menu-item'),
            onPressed: onMealDiarySettingsPressed,
            child: const Text('Meal Diary Settings'),
          ),
        ),
      ],
      // `MergeSemantics` + `Semantics(expanded:)` is the framework's own
      // treatment for a menu trigger (see `SubmenuButton`). Without it the
      // button announces itself as an ordinary button and a screen reader
      // never learns the menu is open, so the state has to be stated here:
      // `IconButton` exposes no expanded flag of its own.
      builder: (context, controller, child) => MergeSemantics(
        child: Semantics(
          expanded: controller.isOpen,
          child: IconButton(
            key: const ValueKey('meal-diary-more-menu'),
            tooltip: 'More',
            onPressed: controller.isOpen ? controller.close : controller.open,
            icon: const Icon(Icons.more_vert),
          ),
        ),
      ),
    );
  }
}
