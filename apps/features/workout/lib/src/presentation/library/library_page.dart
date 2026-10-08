import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../domain/repositories/program_repository.dart';
import '../../domain/usecases/program_id_generator.dart';
import 'programs/programs_surface.dart';

enum _LibraryCategory {
  programs('Programs'),
  exercises('Exercises');

  const _LibraryCategory(this.label);

  final String label;
}

/// Canonical Workout Library root.
///
/// Library owns presentation/navigation state only. Program and Exercise truth
/// remain with their owning Workout capabilities.
class LibraryPage extends StatefulWidget {
  const LibraryPage({
    required this.programRepository,
    required this.onProgramsManagePressed,
    required this.onExercisesPressed,
    required this.onCreateExercisePressed,
    required this.canCreateExercise,
    required this.onSearchPressed,
    super.key,
    this.programIdGenerator,
  });

  final ProgramRepository? programRepository;
  final ProgramIdGenerator? programIdGenerator;
  final Future<void> Function() onProgramsManagePressed;
  final VoidCallback onExercisesPressed;
  final VoidCallback onCreateExercisePressed;

  /// Whether durable user-created Exercise persistence is available.
  ///
  /// Library fails closed by hiding the Create Exercise card when false.
  final bool canCreateExercise;

  /// Opens Exercises with its search field active and focused.
  final VoidCallback onSearchPressed;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  _LibraryCategory? _selectedCategory;

  _LibraryCategory get _contentCategory =>
      _selectedCategory ?? _LibraryCategory.programs;

  void _selectCategory(_LibraryCategory category) {
    if (_selectedCategory == category) return;
    setState(() => _selectedCategory = category);
  }

  void _clearCategorySelection() {
    if (_selectedCategory == null) return;
    setState(() => _selectedCategory = null);
  }

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
            onPressed: widget.onSearchPressed,
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
            _LibraryCategoryStrip(
              selectedCategory: _selectedCategory,
              onCategoryPressed: _selectCategory,
              onClearPressed: _clearCategorySelection,
            ),
            const SizedBox(height: TioSpacing.lg),
            switch (_contentCategory) {
              _LibraryCategory.programs => ProgramsSurface.library(
                  key: const ValueKey('library-programs-content'),
                  repository: widget.programRepository,
                  idGenerator: widget.programIdGenerator,
                  onManagePressed: widget.onProgramsManagePressed,
                ),
              _LibraryCategory.exercises => _ExercisesContent(
                  canCreateExercise: widget.canCreateExercise,
                  onCreateExercisePressed: widget.onCreateExercisePressed,
                  onExercisesPressed: widget.onExercisesPressed,
                ),
            },
          ],
        ),
      ),
    );
  }
}

class _LibraryCategoryStrip extends StatelessWidget {
  const _LibraryCategoryStrip({
    required this.selectedCategory,
    required this.onCategoryPressed,
    required this.onClearPressed,
  });

  final _LibraryCategory? selectedCategory;
  final ValueChanged<_LibraryCategory> onCategoryPressed;
  final VoidCallback onClearPressed;

  @override
  Widget build(BuildContext context) {
    final selected = selectedCategory;
    final children = selected == null
        ? [
            for (final category in _LibraryCategory.values)
              _LibraryCategoryPill(
                category: category,
                selected: false,
                onPressed: () => onCategoryPressed(category),
              ),
          ]
        : [
            _ClearCategoryButton(onPressed: onClearPressed),
            _LibraryCategoryPill(
              category: selected,
              selected: true,
              onPressed: () => onCategoryPressed(selected),
            ),
          ];

    return SingleChildScrollView(
      key: const ValueKey('library-category-strip'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const SizedBox(width: TioSpacing.sm),
            children[index],
          ],
        ],
      ),
    );
  }
}

class _LibraryCategoryPill extends StatelessWidget {
  const _LibraryCategoryPill({
    required this.category,
    required this.selected,
    required this.onPressed,
  });

  final _LibraryCategory category;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return ChoiceChip(
      key: ValueKey('library-category-${category.name}'),
      label: Text(category.label),
      selected: selected,
      showCheckmark: false,
      backgroundColor: colors.surfaceRaised,
      selectedColor: colors.primary,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        color: selected ? colors.onPrimary : colors.textPrimary,
        fontWeight: TioFontWeight.w700,
        fontSize: TioFontSize.size15,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: TioSpacing.md,
        vertical: TioSpacing.xs,
      ),
      onSelected: (_) => onPressed(),
    );
  }
}

class _ClearCategoryButton extends StatelessWidget {
  const _ClearCategoryButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return SizedBox.square(
      dimension: TioButtonTokens.height,
      child: IconButton(
        key: const ValueKey('library-category-clear'),
        tooltip: 'Show all Library categories',
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: colors.surfaceRaised,
          foregroundColor: colors.textPrimary,
          shape: const CircleBorder(),
        ),
        icon: const Icon(Icons.close_rounded),
      ),
    );
  }
}

class _ExercisesContent extends StatelessWidget {
  const _ExercisesContent({
    required this.canCreateExercise,
    required this.onCreateExercisePressed,
    required this.onExercisesPressed,
  });

  final bool canCreateExercise;
  final VoidCallback onCreateExercisePressed;
  final VoidCallback onExercisesPressed;

  @override
  Widget build(BuildContext context) => Column(
        key: const ValueKey('library-exercises-content'),
        children: [
          if (canCreateExercise) ...[
            TioCard(
              key: const ValueKey('library-create-exercise-card'),
              padding: EdgeInsets.zero,
              onTap: onCreateExercisePressed,
              child: const TioSettingsNavigationRow(
                key: ValueKey('library-create-exercise-entry'),
                leading: TioSettingsLeadingIcon(
                  icon: Icons.add_circle_outline_rounded,
                ),
                title: 'Create Exercise',
                supportingText: 'Create a custom exercise',
              ),
            ),
            const SizedBox(height: TioSpacing.md),
          ],
          TioCard(
            key: const ValueKey('library-exercises-card'),
            padding: EdgeInsets.zero,
            onTap: onExercisesPressed,
            child: const TioSettingsNavigationRow(
              key: ValueKey('library-exercises-entry'),
              leading: TioSettingsLeadingIcon(
                icon: Icons.fitness_center_rounded,
              ),
              title: 'Exercises',
              supportingText: 'Browse all exercises',
            ),
          ),
        ],
      );
}
