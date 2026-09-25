import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Canonical Workout Library root.
///
/// Lists only capability sections that are ready; today that is Exercises.
/// Programs, Routines and Training Plans join when their capabilities land,
/// never as placeholders. Library owns no Exercise, Program, Routine or
/// TrainingPlan truth: each section hands off to its owning route, which the
/// app shell supplies.
class LibraryPage extends StatelessWidget {
  const LibraryPage({
    required this.onExercisesPressed,
    required this.onSearchPressed,
    super.key,
  });

  final VoidCallback onExercisesPressed;

  /// Opens Exercises with its search field active and focused.
  final VoidCallback onSearchPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Scaffold(
      key: const ValueKey('library-page'),
      backgroundColor: colors.background,
      appBar: TioAppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          'Library',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: TioFontWeight.w800,
            fontSize: TioFontSize.size20,
          ),
        ),
        actions: [
          IconButton(
            key: const ValueKey('library-search'),
            tooltip: 'Search exercises',
            color: colors.textPrimary,
            onPressed: onSearchPressed,
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: TioSpacing.lg,
            vertical: TioSpacing.md,
          ),
          children: [
            TioGroupCard(
              children: [
                TioSettingsNavigationRow(
                  key: const ValueKey('library-exercises-entry'),
                  leading: const TioSettingsLeadingIcon(
                    icon: Icons.fitness_center_rounded,
                  ),
                  title: 'Exercises',
                  supportingText: 'Browse all exercises',
                  onTap: onExercisesPressed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
