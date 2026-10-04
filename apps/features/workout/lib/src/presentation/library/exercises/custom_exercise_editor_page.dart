import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/exercises/user_exercise_definition.dart';
import 'custom_exercise_editor_options.dart';
import 'custom_exercises_controller.dart';
import 'exercise_taxonomy_labels.dart';

class CustomExerciseEditorPage extends StatefulWidget {
  const CustomExerciseEditorPage({
    required this.controller,
    this.exercise,
    super.key,
  });
  final CustomExercisesController controller;
  final Exercise? exercise;

  @override
  State<CustomExerciseEditorPage> createState() =>
      _CustomExerciseEditorPageState();
}

class _CustomExerciseEditorPageState extends State<CustomExerciseEditorPage> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  ExerciseType? _type;
  String? _primaryMuscle;
  late Set<String> _secondaryMuscles;
  String? _equipment;
  bool _saving = false;
  String? _error;
  final Object _createDraftIdentity = Object();

  bool get _editing => widget.exercise != null;

  String get _primaryMuscleSummary {
    final muscle = _primaryMuscle;
    if (muscle == null) return 'None';
    final label = exerciseTaxonomyLabel(muscle);
    final bodyPart = customExerciseBodyPartForMuscle(muscle);
    return bodyPart == null ? label : '${bodyPart.label} · $label';
  }

  String get _secondaryMuscleSummary {
    if (_secondaryMuscles.isEmpty) return 'None';
    final labels = _secondaryMuscles.map(exerciseTaxonomyLabel).toList()
      ..sort();
    if (labels.length <= 2) return labels.join(', ');
    return '${labels.length} selected';
  }

  @override
  void initState() {
    super.initState();
    final exercise = widget.exercise;
    _name = TextEditingController(text: exercise?.displayName ?? '');
    _description = TextEditingController(text: exercise?.description ?? '');
    _type = exercise?.exerciseType;
    _primaryMuscle = exercise != null && exercise.primaryMuscles.isNotEmpty
        ? exercise.primaryMuscles.first
        : null;
    _secondaryMuscles = {...?exercise?.secondaryMuscles};
    _equipment = exercise?.primaryEquipment;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _selectExerciseType() async {
    final result = await showTioEditorSheet<_SelectionResult<ExerciseType>>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => TioEditorSheet(
        title: 'Exercise Type',
        supportingText: 'Choose how this exercise is measured during workouts.',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TioSelectableCard(
              key: const ValueKey('custom-exercise-type-none'),
              selected: _type == null,
              semanticLabel: 'No Exercise Type',
              onTap: () => Navigator.of(sheetContext).pop(
                const _SelectionResult<ExerciseType>.clear(),
              ),
              child: const Text('None'),
            ),
            const SizedBox(height: TioSpacing.sm),
            for (final option in customExerciseTypeOptions) ...[
              _ExerciseTypeOptionCard(
                option: option,
                selected: _type == option.type,
                onTap: () => Navigator.of(sheetContext).pop(
                  _SelectionResult<ExerciseType>.value(option.type),
                ),
              ),
              const SizedBox(height: TioSpacing.sm),
            ],
          ],
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _type = result.clear ? null : result.value);
  }

  Future<void> _selectPrimaryMuscle() async {
    final bodyParts = <CustomExerciseBodyPartOption>[
      ...customExercisePrimaryBodyParts,
      CustomExerciseBodyPartOption(
        id: 'full_body',
        label: 'Full Body',
        muscles: customExerciseAllMuscles(),
      ),
    ];
    final bodyPartResult =
        await showTioEditorSheet<_SelectionResult<CustomExerciseBodyPartOption>>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => TioEditorSheet(
        title: 'Primary muscle',
        supportingText: 'Choose a Body Part first.',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TioSelectableCard(
              key: const ValueKey('custom-exercise-primary-none'),
              selected: _primaryMuscle == null,
              semanticLabel: 'No Primary muscle',
              onTap: () => Navigator.of(sheetContext).pop(
                const _SelectionResult<CustomExerciseBodyPartOption>.clear(),
              ),
              child: const Text('None'),
            ),
            const SizedBox(height: TioSpacing.sm),
            TioGroupCard(
              children: [
                for (final bodyPart in bodyParts)
                  TioSettingsNavigationRow(
                    key: ValueKey(
                      'custom-exercise-primary-group-${bodyPart.id}',
                    ),
                    leading: const TioSettingsLeadingIcon(
                      icon: Icons.accessibility_new_rounded,
                    ),
                    title: bodyPart.label,
                    supportingText: bodyPart.id == 'full_body'
                        ? 'All muscles'
                        : '${bodyPart.muscles.length} muscles',
                    onTap: () => Navigator.of(sheetContext).pop(
                      _SelectionResult<CustomExerciseBodyPartOption>.value(
                        bodyPart,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    if (!mounted || bodyPartResult == null) return;
    if (bodyPartResult.clear) {
      setState(() => _primaryMuscle = null);
      return;
    }

    final bodyPart = bodyPartResult.value!;
    final selectedMuscle = await showTioEditorSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => TioEditorSheet(
        title: bodyPart.label,
        supportingText: 'Choose one Primary muscle.',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final muscle in bodyPart.muscles) ...[
              TioSelectableCard(
                key: ValueKey('custom-exercise-primary-muscle-$muscle'),
                selected: _primaryMuscle == muscle,
                semanticLabel: exerciseTaxonomyLabel(muscle),
                onTap: () => Navigator.of(sheetContext).pop(muscle),
                child: Text(exerciseTaxonomyLabel(muscle)),
              ),
              const SizedBox(height: TioSpacing.sm),
            ],
          ],
        ),
      ),
    );
    if (!mounted || selectedMuscle == null) return;
    setState(() {
      _primaryMuscle = selectedMuscle;
      _secondaryMuscles.remove(selectedMuscle);
    });
  }

  Future<void> _selectSecondaryMuscles() async {
    final available = customExerciseAllMuscles()
        .where((muscle) => muscle != _primaryMuscle)
        .toList(growable: false);
    final draft = <String>{..._secondaryMuscles}
      ..remove(_primaryMuscle);

    final selected = await showTioEditorSheet<Set<String>>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => TioEditorSheet(
          title: 'Secondary muscles',
          supportingText: 'Choose any supporting muscles.',
          content: TioGroupCard(
            children: [
              for (final muscle in available)
                CheckboxListTile(
                  key: ValueKey('custom-exercise-secondary-$muscle'),
                  value: draft.contains(muscle),
                  title: Text(exerciseTaxonomyLabel(muscle)),
                  controlAffinity: ListTileControlAffinity.trailing,
                  onChanged: (checked) => setSheetState(() {
                    if (checked ?? false) {
                      draft.add(muscle);
                    } else {
                      draft.remove(muscle);
                    }
                  }),
                ),
            ],
          ),
          actions: Row(
            children: [
              Expanded(
                child: TioButton.secondary(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  expand: true,
                ),
              ),
              const SizedBox(width: TioSpacing.md),
              Expanded(
                child: TioButton.primary(
                  key: const ValueKey('custom-exercise-secondary-done'),
                  label: 'Done',
                  onPressed: () => Navigator.of(sheetContext).pop(draft),
                  expand: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _secondaryMuscles
        ..clear()
        ..addAll(selected);
    });
  }

  Future<void> _selectEquipment() async {
    final equipment = UserExerciseDefinition.equipmentTokens.toList()
      ..sort((a, b) =>
          exerciseTaxonomyLabel(a).compareTo(exerciseTaxonomyLabel(b)));
    final result = await showTioEditorSheet<_SelectionResult<String>>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => TioEditorSheet(
        title: 'Equipment',
        supportingText: 'Choose one equipment option.',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TioSelectableCard(
              key: const ValueKey('custom-exercise-equipment-none'),
              selected: _equipment == null,
              semanticLabel: 'No Equipment',
              onTap: () => Navigator.of(sheetContext).pop(
                const _SelectionResult<String>.clear(),
              ),
              child: const Text('None'),
            ),
            const SizedBox(height: TioSpacing.sm),
            for (final item in equipment) ...[
              TioSelectableCard(
                key: ValueKey('custom-exercise-equipment-$item'),
                selected: _equipment == item,
                semanticLabel: exerciseTaxonomyLabel(item),
                onTap: () => Navigator.of(sheetContext).pop(
                  _SelectionResult<String>.value(item),
                ),
                child: Text(exerciseTaxonomyLabel(item)),
              ),
              const SizedBox(height: TioSpacing.sm),
            ],
          ],
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _equipment = result.clear ? null : result.value);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Enter an exercise name.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final definition = UserExerciseDefinition(
        description: _description.text,
        exerciseType: _type,
        primaryMuscle: _primaryMuscle,
        secondaryMuscles: _secondaryMuscles.toList(growable: false),
        primaryEquipment: _equipment,
      );
      final exercise = widget.exercise;
      final success = exercise == null
          ? await widget.controller.create(
              _name.text,
              draftIdentity: _createDraftIdentity,
              definition: definition,
            )
          : await widget.controller.edit(
              id: exercise.ref as UserCreatedExerciseRef,
              displayName: _name.text,
              definition: definition,
            );
      if (!mounted) return;
      if (success) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _saving = false;
          _error = widget.controller.state.actionError ??
              'Could not save exercise. Please try again.';
        });
      }
    } on ArgumentError {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Review the selected exercise details.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
      key: const ValueKey('custom-exercise-editor'),
      backgroundColor: colors.background,
      appBar: TioAppBar(
        leading: BackButton(
          color: colors.textPrimary,
          onPressed: _saving ? () {} : null,
        ),
        title: Text(_editing ? 'Edit Exercise' : 'Create Exercise'),
        actions: [
          TextButton(
            key: const ValueKey('custom-exercise-save'),
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(TioSpacing.lg),
          children: [
            TioInput(
              key: const ValueKey('custom-exercise-name'),
              controller: _name,
              hint: 'Exercise name',
              enabled: !_saving,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: TioSpacing.md),
            TioInput.multiline(
              key: const ValueKey('custom-exercise-description'),
              controller: _description,
              hint: 'Description (optional)',
              enabled: !_saving,
              minLines: 3,
              maxLines: 4,
              onChanged: (_) {},
            ),
            if (_error != null) ...[
              const SizedBox(height: TioSpacing.sm),
              Text(_error!, style: TextStyle(color: colors.danger)),
            ],
            const SizedBox(height: TioSpacing.lg),
            _EditorSelectorField(
              key: const ValueKey('custom-exercise-type-field'),
              label: 'Exercise Type',
              icon: Icons.straighten_rounded,
              value: _type == null
                  ? 'None'
                  : [
                      customExerciseTypeLabel(_type!),
                      ...customExerciseTypeOptionFor(_type!).hints,
                    ].join(' · '),
              onTap: _saving ? null : _selectExerciseType,
            ),
            _EditorSelectorField(
              key: const ValueKey('custom-exercise-primary-field'),
              label: 'Primary muscle',
              icon: Icons.accessibility_new_rounded,
              value: _primaryMuscleSummary,
              onTap: _saving ? null : _selectPrimaryMuscle,
            ),
            _EditorSelectorField(
              key: const ValueKey('custom-exercise-secondary-field'),
              label: 'Secondary muscles',
              icon: Icons.checklist_rounded,
              value: _secondaryMuscleSummary,
              onTap: _saving ? null : _selectSecondaryMuscles,
            ),
            _EditorSelectorField(
              key: const ValueKey('custom-exercise-equipment-field'),
              label: 'Equipment',
              icon: Icons.fitness_center_rounded,
              value: _equipment == null
                  ? 'None'
                  : exerciseTaxonomyLabel(_equipment!),
              onTap: _saving ? null : _selectEquipment,
            ),
            if (_editing) ...[
              const SizedBox(height: TioSpacing.xl),
              TioButton.secondary(
                key: const ValueKey('custom-exercise-archive'),
                label: 'Archive Exercise',
                onPressed: _saving
                    ? null
                    : () async {
                        final confirmed = await showTioConfirmationBottomSheet(
                          context: context,
                          title: 'Archive exercise?',
                          message:
                              'This exercise will be removed from your active Custom Exercises.',
                          confirmLabel: 'Archive',
                          cancelLabel: 'Cancel',
                          intent: TioConfirmationIntent.destructive,
                        );
                        if (confirmed != true || !context.mounted) return;
                        setState(() => _saving = true);
                        final ok = await widget.controller.archive(
                          widget.exercise!.ref as UserCreatedExerciseRef,
                        );
                        if (!mounted) return;
                        if (ok) {
                          Navigator.of(this.context).pop();
                        } else {
                          setState(() {
                            _saving = false;
                            _error = widget.controller.state.actionError;
                          });
                        }
                      },
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}

final class _SelectionResult<T> {
  const _SelectionResult.value(this.value) : clear = false;
  const _SelectionResult.clear()
      : value = null,
        clear = true;

  final T? value;
  final bool clear;
}

class _EditorSelectorField extends StatelessWidget {
  const _EditorSelectorField({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: TioSpacing.md),
        child: TioGroupCard(
          children: [
            TioSettingsNavigationRow(
              leading: TioSettingsLeadingIcon(icon: icon),
              title: label,
              supportingText: value,
              onTap: onTap,
            ),
          ],
        ),
      );
}

class _ExerciseTypeOptionCard extends StatelessWidget {
  const _ExerciseTypeOptionCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final CustomExerciseTypeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return TioSelectableCard(
      key: ValueKey('custom-exercise-type-${option.type.storageValue}'),
      selected: selected,
      semanticLabel:
          '${option.label}. ${option.hints.join(', ')}. ${option.example}',
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(option.label, style: textTheme.titleSmall),
          const SizedBox(height: TioSpacing.xs),
          Text(
            option.example,
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: TioSpacing.sm),
          Wrap(
            spacing: TioSpacing.xs,
            runSpacing: TioSpacing.xs,
            children: [
              for (final hint in option.hints)
                Chip(
                  label: Text(hint),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
