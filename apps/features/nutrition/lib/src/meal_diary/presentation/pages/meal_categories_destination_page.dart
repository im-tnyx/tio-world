import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Route-only boundary for the future TNYX-67 Meal Categories management UI.
///
/// It intentionally renders no category data or controls. TNYX-67 Slice C
/// will own the management body, state, validation, and repository access.
class MealCategoriesDestinationPage extends StatelessWidget {
  const MealCategoriesDestinationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Scaffold(
      key: const ValueKey('meal-categories-destination-page'),
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          'Meal Categories',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: TioFontWeight.w800,
            fontSize: TioFontSize.size20,
          ),
        ),
      ),
      body: const SafeArea(child: SizedBox.expand()),
    );
  }
}
