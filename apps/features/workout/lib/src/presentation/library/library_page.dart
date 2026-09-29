import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Canonical Workout Library root.
///
/// Lists only capabilities that are ready. Programs and Exercises are real
/// destinations in this slice; Routines remain owned by Program context and
/// Training Plans join only when their own capability lands.
class LibraryPage extends StatelessWidget {
  const LibraryPage({
    required this.onProgramsPressed,
    required this.onExercisesPressed,
    required this.onSearchPressed,
    super.key,
  });

  final VoidCallback onProgramsPressed;
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
                  key: const ValueKey('library-programs-entry'),
                  leading: const TioSettingsLeadingIcon(
                    icon: Icons.view_list_rounded,
                  ),
                  title: 'Programs',
                  supportingText: 'Create and manage programs',
                  onTap: onProgramsPressed,
                ),
                const _LibraryDivider(),
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

class _LibraryDivider extends StatelessWidget {
  const _LibraryDivider();

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Divider(
      height: TioSize.dp1,
      thickness: TioStroke.width1,
      indent: TioSize.dp64,
      color: colors.outlineStrong.withAlpha(TioAlpha.alpha20),
    );
  }
}
