import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/exercises/user_exercise_definition.dart';
import '../../../domain/exercises/user_exercise_repository.dart';
import 'custom_exercises_controller.dart';
import 'custom_exercises_state.dart';
import 'exercise_taxonomy_labels.dart';

class CustomExercisesPage extends StatefulWidget {
  const CustomExercisesPage({required this.repository, super.key});
  final UserExerciseRepository? repository;

  @override
  State<CustomExercisesPage> createState() => _CustomExercisesPageState();
}

class _CustomExercisesPageState extends State<CustomExercisesPage> {
  CustomExercisesController? _controller;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void didUpdateWidget(covariant CustomExercisesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.repository, widget.repository)) _bind();
  }

  void _bind() {
    _controller?..removeListener(_changed);
    _controller?.dispose();
    final repository = widget.repository;
    if (repository == null) {
      _controller = null;
      return;
    }
    final controller = CustomExercisesController(repository: repository);
    _controller = controller;
    controller.addListener(_changed);
    controller.load();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?..removeListener(_changed);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _openEditor([Exercise? exercise]) async {
    final controller = _controller;
    if (controller == null || controller.state.actionInProgress) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CustomExerciseEditorPage(
          controller: controller,
          exercise: exercise,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final controller = _controller;
    return Scaffold(
      key: const ValueKey('custom-exercises-page'),
      backgroundColor: colors.background,
      appBar: TioAppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        leading: BackButton(color: colors.textPrimary),
        title: Text('Custom Exercises',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: TioFontWeight.w800,
              fontSize: TioFontSize.size20,
            )),
        actions: [
          IconButton(
            key: const ValueKey('custom-exercise-create'),
            tooltip: 'Create custom exercise',
            onPressed: controller?.state.status == CustomExercisesStatus.ready &&
                    !controller!.state.actionInProgress
                ? () => _openEditor()
                : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    final controller = _controller;
    if (controller == null) {
      return const _Message(
        key: ValueKey('custom-exercises-unavailable'),
        text: 'Custom Exercises are unavailable right now.',
      );
    }
    final state = controller.state;
    return switch (state.status) {
      CustomExercisesStatus.loading => const Center(
          key: ValueKey('custom-exercises-loading'),
          child: CircularProgressIndicator(
            semanticsLabel: 'Loading custom exercises',
          ),
        ),
      CustomExercisesStatus.loadFailed => _Failure(
          message: state.loadError ??
              'Could not load custom exercises. Please try again.',
          onRetry: controller.retryLoad,
        ),
      CustomExercisesStatus.ready => state.exercises.isEmpty
          ? _Empty(onCreate: () => _openEditor())
          : _List(
              exercises: state.exercises,
              onEdit: _openEditor,
            ),
    };
  }
}

class _List extends StatelessWidget {
  const _List({required this.exercises, required this.onEdit});
  final List<Exercise> exercises;
  final ValueChanged<Exercise> onEdit;

  @override
  Widget build(BuildContext context) => ListView.separated(
        key: const ValueKey('custom-exercises-list'),
        padding: const EdgeInsets.symmetric(
          horizontal: TioSpacing.lg,
          vertical: TioSpacing.md,
        ),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          final details = [
            if (exercise.exerciseType != null)
              _exerciseTypeLabel(exercise.exerciseType!),
            if (exercise.primaryMuscles.isNotEmpty)
              exerciseTaxonomyLabel(exercise.primaryMuscles.first),
            if (exercise.primaryEquipment != null)
              exerciseTaxonomyLabel(exercise.primaryEquipment!),
          ].join(' · ');
          return TioGroupCard(children: [
            TioSettingsNavigationRow(
              key: ValueKey('custom-exercise-row-${exercise.ref.value}'),
              leading: const TioSettingsLeadingIcon(
                icon: Icons.fitness_center_rounded,
              ),
              title: exercise.displayName,
              supportingText:
                  details.isEmpty ? 'Custom exercise' : details,
              onTap: () => onEdit(exercise),
            ),
          ]);
        },
        separatorBuilder: (_, __) => const SizedBox(height: TioSpacing.sm),
      );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
        key: const ValueKey('custom-exercises-empty'),
        child: Padding(
          padding: const EdgeInsets.all(TioSpacing.xl),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('No custom exercises yet'),
            const SizedBox(height: TioSpacing.lg),
            TioButton.primary(
              key: const ValueKey('custom-exercises-empty-create'),
              label: 'Create Exercise',
              onPressed: onCreate,
            ),
          ]),
        ),
      );
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        key: const ValueKey('custom-exercises-load-failure'),
        child: Padding(
          padding: const EdgeInsets.all(TioSpacing.xl),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: TioSpacing.lg),
            TioButton.secondary(label: 'Try again', onPressed: onRetry),
          ]),
        ),
      );
}

class _Message extends StatelessWidget {
  const _Message({required this.text, super.key});
  final String text;
  @override
  Widget build(BuildContext context) =>
      Center(child: Padding(padding: const EdgeInsets.all(TioSpacing.xl), child: Text(text)));
}

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

  bool get _editing => widget.exercise != null;

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
          ? await widget.controller.create(_name.text, definition: definition)
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
    return Scaffold(
      key: const ValueKey('custom-exercise-editor'),
      backgroundColor: colors.background,
      appBar: TioAppBar(
        leading: BackButton(color: colors.textPrimary),
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
            _ChoiceField<ExerciseType>(
              label: 'Exercise Type',
              value: _type,
              values: ExerciseType.values,
              display: _exerciseTypeLabel,
              onChanged: _saving ? null : (value) => setState(() => _type = value),
            ),
            _ChoiceField<String>(
              label: 'Primary muscle',
              value: _primaryMuscle,
              values: UserExerciseDefinition.muscleTokens.toList()..sort(),
              display: exerciseTaxonomyLabel,
              onChanged: _saving
                  ? null
                  : (value) => setState(() {
                        _primaryMuscle = value;
                        _secondaryMuscles.remove(value);
                      }),
            ),
            _MultiChoiceField(
              label: 'Secondary muscles',
              values: UserExerciseDefinition.muscleTokens
                  .where((token) => token != _primaryMuscle)
                  .toList()
                ..sort(),
              selected: _secondaryMuscles,
              enabled: !_saving,
              onChanged: (value, selected) => setState(() {
                selected
                    ? _secondaryMuscles.add(value)
                    : _secondaryMuscles.remove(value);
              }),
            ),
            _ChoiceField<String>(
              label: 'Equipment',
              value: _equipment,
              values: UserExerciseDefinition.equipmentTokens.toList()..sort(),
              display: exerciseTaxonomyLabel,
              onChanged:
                  _saving ? null : (value) => setState(() => _equipment = value),
            ),
            if (_editing) ...[
              const SizedBox(height: TioSpacing.xl),
              TioButton.secondary(
                key: const ValueKey('custom-exercise-archive'),
                label: 'Archive Exercise',
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        final ok = await widget.controller.archive(
                          widget.exercise!.ref as UserCreatedExerciseRef,
                        );
                        if (!mounted) return;
                        if (ok) {
                          Navigator.of(context).pop();
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
    );
  }
}

class _ChoiceField<T> extends StatelessWidget {
  const _ChoiceField({
    required this.label,
    required this.value,
    required this.values,
    required this.display,
    required this.onChanged,
  });
  final String label;
  final T? value;
  final List<T> values;
  final String Function(T) display;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: TioSpacing.md),
        child: DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(labelText: label),
          items: values
              .map((item) =>
                  DropdownMenuItem(value: item, child: Text(display(item))))
              .toList(growable: false),
          onChanged: onChanged,
        ),
      );
}

class _MultiChoiceField extends StatelessWidget {
  const _MultiChoiceField({
    required this.label,
    required this.values,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });
  final String label;
  final List<String> values;
  final Set<String> selected;
  final bool enabled;
  final void Function(String, bool) onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: TioSpacing.md),
        child: ExpansionTile(
          title: Text(label),
          subtitle: Text(selected.isEmpty
              ? 'None'
              : selected.map(exerciseTaxonomyLabel).join(', ')),
          children: values
              .map((value) => CheckboxListTile(
                    value: selected.contains(value),
                    onChanged: enabled
                        ? (checked) => onChanged(value, checked ?? false)
                        : null,
                    title: Text(exerciseTaxonomyLabel(value)),
                  ))
              .toList(growable: false),
        ),
      );
}

String _exerciseTypeLabel(ExerciseType type) => switch (type) {
      ExerciseType.weightReps => 'Weight & reps',
      ExerciseType.distanceDuration => 'Distance & duration',
      ExerciseType.duration => 'Duration',
      ExerciseType.dumbbellX2Simultaneous => '2 dumbbells · simultaneous',
      ExerciseType.dumbbellX1AlternatingSides => '1 dumbbell · alternating sides',
      ExerciseType.dumbbellX1Simultaneous => '1 dumbbell · simultaneous',
      ExerciseType.dumbbellX2AlternatingLegs => '2 dumbbells · alternating legs',
      ExerciseType.dumbbellX1AlternatingLegs => '1 dumbbell · alternating legs',
      ExerciseType.fullBodyweight => 'Full bodyweight',
      ExerciseType.assistedBodyweight => 'Assisted bodyweight',
      ExerciseType.stepsDuration => 'Steps & duration',
    };
