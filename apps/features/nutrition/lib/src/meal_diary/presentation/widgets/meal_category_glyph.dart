import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/models/meal_category.dart';

/// What a meal category shows in the leading column of its row.
///
/// Decorative, and deliberately carries no `semanticLabel`: it announces
/// nothing the row's own name does not already say. It exists so that column
/// is occupied on every row — an empty one beside a neighbour's glyph reads as
/// something missing rather than as something deliberately absent.
///
/// Shared by the two screens that list categories so one mapping decides. The
/// active list gives it to the canonical four only, because its custom rows
/// carry a drag grip in the same column; the archived list gives it to every
/// row, where nothing is draggable and the column has nothing else to hold.
class MealCategoryGlyph extends StatelessWidget {
  const MealCategoryGlyph({required this.item, super.key, this.enabled = true});

  /// The width the leading column reserves. Rows that show a grip instead
  /// reserve the same, so names sit in one vertical alignment either way.
  static const double columnWidth = TioSize.dp20;

  /// Keyed on the durable [MealCategoryDefaultKey], never on the display name:
  /// a reader can rename Lunch and the row keeps its own glyph. The domain has
  /// no opinion about icons, so the mapping belongs here.
  static const _glyphs = <MealCategoryDefaultKey, IconData>{
    MealCategoryDefaultKey.breakfast: Icons.free_breakfast_outlined,
    MealCategoryDefaultKey.lunch: Icons.lunch_dining_outlined,
    MealCategoryDefaultKey.dinner: Icons.dinner_dining_outlined,
    MealCategoryDefaultKey.snacks: Icons.cookie_outlined,
  };

  /// What a custom category shows. It has no canonical identity to draw on, so
  /// it takes the generic food glyph the rest of the app already uses for
  /// Nutrition rather than leaving the column empty.
  static const IconData customGlyph = Icons.restaurant_outlined;

  final MealCategory item;

  /// Dimmed while a write is in flight, alongside the rest of the row.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final defaultKey = item.defaultKey;

    return Icon(
      defaultKey == null ? customGlyph : _glyphs[defaultKey],
      key: ValueKey('meal-category-glyph-${item.id}'),
      size: columnWidth,
      color: enabled ? colors.textMuted : colors.outlineStrong,
    );
  }
}
