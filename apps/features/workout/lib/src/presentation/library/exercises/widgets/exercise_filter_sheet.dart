import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../exercises_state.dart';

/// Filter selection returned by [showExerciseFilterSheet]; null means any.
final class ExerciseFilterSelection {
  const ExerciseFilterSelection({
    this.muscleGroup,
    this.primaryEquipment,
    this.category,
  });

  final String? muscleGroup;
  final String? primaryEquipment;
  final String? category;
}

/// Opens the Muscle / Equipment / Category filter sheet.
///
/// Completes with the selection to apply on Show results, or null when the
/// sheet is dismissed without applying.
Future<ExerciseFilterSelection?> showExerciseFilterSheet({
  required BuildContext context,
  required ExercisesState state,
}) =>
    showTioEditorSheet<ExerciseFilterSelection>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (context) => ExerciseFilterSheet(state: state),
    );

/// Single-select draft of the three Exercise filters.
///
/// Choices stay a draft until Show results; Clear all empties the draft.
class ExerciseFilterSheet extends StatefulWidget {
  const ExerciseFilterSheet({required this.state, super.key});

  final ExercisesState state;

  @override
  State<ExerciseFilterSheet> createState() => _ExerciseFilterSheetState();
}

class _ExerciseFilterSheetState extends State<ExerciseFilterSheet> {
  late final Map<ExerciseFilterDimension, String?> _draft = {
    for (final dimension in ExerciseFilterDimension.values)
      dimension: widget.state.selectedValue(dimension),
  };

  static String _title(ExerciseFilterDimension dimension) =>
      switch (dimension) {
        ExerciseFilterDimension.muscle => 'Muscle',
        ExerciseFilterDimension.equipment => 'Equipment',
        ExerciseFilterDimension.category => 'Category',
      };

  void _toggle(ExerciseFilterDimension dimension, String value) {
    setState(() {
      _draft[dimension] = _draft[dimension] == value ? null : value;
    });
  }

  void _clearAll() {
    setState(() {
      for (final dimension in ExerciseFilterDimension.values) {
        _draft[dimension] = null;
      }
    });
  }

  void _showResults() {
    Navigator.of(context).pop(ExerciseFilterSelection(
      muscleGroup: _draft[ExerciseFilterDimension.muscle],
      primaryEquipment: _draft[ExerciseFilterDimension.equipment],
      category: _draft[ExerciseFilterDimension.category],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final dimensions = ExerciseFilterDimension.values
        .where((dimension) => widget.state.optionsFor(dimension).isNotEmpty)
        .toList(growable: false);

    return TioEditorSheet(
      key: const ValueKey('exercise-filter-sheet'),
      title: 'Filter exercises',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < dimensions.length; index++) ...[
            if (index > 0) const SizedBox(height: TioSpacing.lg),
            Semantics(
              header: true,
              child: Text(
                _title(dimensions[index]),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: TioFontWeight.w700,
                  fontSize: TioFontSize.size15,
                ),
              ),
            ),
            const SizedBox(height: TioSpacing.sm),
            Wrap(
              spacing: TioSpacing.sm,
              runSpacing: TioSpacing.sm,
              children: [
                for (final option in widget.state.optionsFor(dimensions[index]))
                  ChoiceChip(
                    key: ValueKey(
                      'exercise-filter-${dimensions[index].name}-'
                      '${option.value}',
                    ),
                    label: Text(option.label),
                    selected: _draft[dimensions[index]] == option.value,
                    selectedColor: colors.primary.withAlpha(TioAlpha.alpha24),
                    onSelected: (_) => _toggle(dimensions[index], option.value),
                  ),
              ],
            ),
          ],
        ],
      ),
      actions: Row(
        children: [
          Expanded(
            child: TioButton.secondary(
              key: const ValueKey('exercise-filter-clear-all'),
              label: 'Clear all',
              expand: true,
              onPressed: _clearAll,
            ),
          ),
          const SizedBox(width: TioSpacing.sm),
          Expanded(
            child: TioButton.primary(
              key: const ValueKey('exercise-filter-show-results'),
              label: 'Show results',
              expand: true,
              onPressed: _showResults,
            ),
          ),
        ],
      ),
    );
  }
}
