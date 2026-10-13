import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/exercises/exercise_catalog_repository.dart';
import '../../../domain/exercises/user_exercise_repository.dart';
import '../../../domain/repositories/routine_composition_repository.dart';
import '../../../domain/repositories/routine_create_repository.dart';
import '../../../domain/repositories/routine_repository.dart';
import 'routine_create_controller.dart';
import 'routine_exercise_picker_page.dart';
import 'routine_set_editor_sheet.dart';

/// Full-screen, Program-owned Create draft. Nothing persists until Save
/// calls an atomic Create repository. This is NOT the existing-Routine editor.
class CreateRoutinePage extends StatefulWidget {
  const CreateRoutinePage({
    required this.program,
    required this.initialName,
    required this.createRepository,
    required this.catalogRepository,
    required this.weightUnit,
    this.userExerciseRepository,
    this.routineRepository,
    this.compositionRepository,
    this.canWrite,
    this.newUuid,
    super.key,
  });

  final Program program;
  final String initialName;
  final RoutineCreateRepository createRepository;
  final ExerciseCatalogRepository catalogRepository;
  final UserExerciseRepository? userExerciseRepository;
  final RoutineRepository? routineRepository;
  final RoutineCompositionRepository? compositionRepository;
  final WeightUnit weightUnit;
  final bool Function()? canWrite;
  final String Function()? newUuid;

  @override
  State<CreateRoutinePage> createState() => _CreateRoutinePageState();
}

class _CreateRoutinePageState extends State<CreateRoutinePage> {
  late RoutineCreateController _draft;
  late TextEditingController _name;
  final Map<String, String> _entryLabels = {};

  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void didUpdateWidget(covariant CreateRoutinePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.program.id != widget.program.id ||
        !identical(oldWidget.createRepository, widget.createRepository) ||
        !identical(oldWidget.userExerciseRepository, widget.userExerciseRepository)) {
      _draft.removeListener(_changed);
      _draft.dispose();
      _name.dispose();
      _entryLabels.clear();
      _bind();
    }
  }

  void _bind() {
    _name = TextEditingController(text: widget.initialName);
    _draft = RoutineCreateController(
      program: widget.program,
      initialName: _name.text,
      repository: widget.createRepository,
      userExercises: widget.userExerciseRepository,
      canWrite: widget.canWrite,
      newUuid: widget.newUuid,
    )..addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _draft.removeListener(_changed);
    _draft.dispose();
    _name.dispose();
    super.dispose();
  }

  bool get _enabled {
    if (widget.canWrite != null && !widget.canWrite!()) return false;
    return _draft.state.status == RoutineCreateStatus.ready;
  }

  Future<void> _pick() async {
    if (!_enabled) return;
    final exercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (_) => RoutineExercisePickerPage(
          catalogRepository: widget.catalogRepository,
          userExerciseRepository: widget.userExerciseRepository,
        ),
      ),
    );
    if (!mounted || !_enabled || exercise == null) return;
    final id = _draft.addPickedExercise(exercise);
    if (id != null) _entryLabels[id] = exercise.displayName;
  }

  Future<void> _editSet(RoutineCompositionEntry entry,
      [RoutineCompositionSet? existing]) async {
    if (!_enabled) return;
    final result = await showTioEditorSheet<SetPrescription>(
      context: context,
      useSafeArea: true,
      builder: (_) => RoutineSetEditorSheet(
        unit: widget.weightUnit,
        initial: existing?.prescription,
      ),
    );
    if (!mounted || !_enabled || result == null) return;
    if (existing == null) {
      _draft.addSet(entry.id, result);
    } else {
      _draft.editSet(entry.id, existing.id, result);
    }
  }

  Future<void> _save() async {
    if (!_draft.state.canSave || !_enabled) return;
    final confirmed = await _draft.save();
    if (confirmed && mounted) _closeConfirmed();
  }

  Future<void> _verify() async {
    final routines = widget.routineRepository;
    final compositions = widget.compositionRepository;
    if (routines == null || compositions == null) return;
    final confirmed = await _draft.reconcileUnknown(
      routines: routines, compositions: compositions,
    );
    if (confirmed && mounted) _closeConfirmed();
  }

  void _closeConfirmed() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _draft.state.status == RoutineCreateStatus.saved) {
        Navigator.of(context).pop<bool>(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final status = _draft.state.status;
    final locked = status == RoutineCreateStatus.saving;
    final canSave = _enabled && _draft.state.canSave;
    return PopScope(
      canPop: !locked,
      child: Scaffold(
        key: const ValueKey('create-routine-page'),
        backgroundColor: colors.background,
        appBar: TioAppBar(
          backgroundColor: colors.background,
          elevation: TioElevation.none,
          scrolledUnderElevation: TioElevation.none,
          leading: TextButton(
            key: const ValueKey('create-routine-cancel'),
            onPressed: locked ? null : () => Navigator.of(context).pop<bool>(false),
            child: const Text('Cancel'),
          ),
          title: Text(
            'Create Routine',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: TioFontSize.size20,
              fontWeight: TioFontWeight.w800,
            ),
          ),
          actions: [
            TextButton(
              key: const ValueKey('create-routine-save'),
              onPressed: canSave ? _save : null,
              child: const Text('Save'),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            key: const ValueKey('create-routine-scroll'),
            padding: const EdgeInsets.symmetric(
              horizontal: TioSpacing.lg,
              vertical: TioSpacing.xl,
            ),
            children: [
              TioInput(
                key: const ValueKey('create-routine-name'),
                controller: _name,
                enabled: _enabled,
                hint: 'Routine name',
                textCapitalization: TextCapitalization.words,
                onChanged: _draft.rename,
              ),
              const SizedBox(height: TioSpacing.xl),
              if (_draft.state.entries.isEmpty) _empty(context),
              for (var i = 0; i < _draft.state.entries.length; i++)
                _exerciseCard(_draft.state.entries[i], i),
              if (status == RoutineCreateStatus.verifying ||
                  status == RoutineCreateStatus.saving)
                Padding(
                  padding: const EdgeInsets.all(TioSpacing.lg),
                  child: Center(
                    child: Text(
                      status == RoutineCreateStatus.verifying
                          ? 'Verifying Custom Exercises'
                          : 'Saving Routine...',
                    ),
                  ),
                ),
              if (_draft.state.message != null)
                Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: TioSpacing.md,
                    ),
                    child: Text(
                      _draft.state.message!,
                      style: TextStyle(color: colors.danger),
                    ),
                  ),
                ),
              if (status == RoutineCreateStatus.outcomeUnknown)
                TioButton.secondary(
                  key: const ValueKey('create-routine-verify'),
                  label: 'Verify saved Routine',
                  onPressed: widget.routineRepository != null &&
                          widget.compositionRepository != null
                      ? _verify
                      : null,
                  expand: true,
                ),
              if (status == RoutineCreateStatus.ready) ...[
                const SizedBox(height: TioSpacing.md),
                TioButton.primary(
                  key: const ValueKey('create-routine-add-exercise'),
                  label: 'Add exercise',
                  expand: true,
                  onPressed: _enabled ? _pick : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) => Padding(
        key: const ValueKey('create-routine-empty'),
        padding: const EdgeInsets.symmetric(vertical: TioSpacing.xxl),
        child: Column(
          children: [
            Icon(Icons.fitness_center_outlined,
                size: TioSize.dp64, color: context.tioColors.textSecondary),
            const SizedBox(height: TioSpacing.xl),
            Text(
              'Get started by adding an exercise to your routine.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.tioColors.textSecondary),
            ),
            const SizedBox(height: TioSpacing.xxl),
          ],
        ),
      );

  Widget _exerciseCard(RoutineCompositionEntry entry, int position) {
    final colors = context.tioColors;
    final unit = widget.weightUnit;
    return Padding(
      padding: const EdgeInsets.only(bottom: TioSpacing.xl),
      child: Column(
        key: ValueKey('create-routine-entry-${entry.id}'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _entryLabels[entry.id] ?? 'Selected Exercise',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: TioFontSize.size20,
                    fontWeight: TioFontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                key: ValueKey('create-routine-remove-${entry.id}'),
                tooltip: 'Remove Exercise',
                onPressed: _enabled
                    ? () {
                        _draft.removeExercise(entry.id);
                        _entryLabels.remove(entry.id);
                      }
                    : null,
                icon: const Icon(Icons.close_rounded),
              ),
              IconButton(
                tooltip: 'Move Exercise up',
                onPressed: _enabled && position > 0
                    ? () => _draft.moveExercise(position, position - 1)
                    : null,
                icon: const Icon(Icons.arrow_upward_rounded),
              ),
              IconButton(
                tooltip: 'Move Exercise down',
                onPressed: _enabled && position < _draft.state.entries.length - 1
                    ? () => _draft.moveExercise(position, position + 1)
                    : null,
                icon: const Icon(Icons.arrow_downward_rounded),
              ),
            ],
          ),
          const SizedBox(height: TioSpacing.md),
          Row(
            children: [
              const Expanded(child: Text('SET')),
              Expanded(child: Text(unit == WeightUnit.kg ? 'KG' : 'LB')),
              const Expanded(child: Text('REPS')),
            ],
          ),
          for (var i = 0; i < entry.sets.length; i++)
            Row(
              key: ValueKey('create-routine-set-${entry.sets[i].id}'),
              children: [
                Expanded(child: Text('${i + 1}')),
                Expanded(
                  child: Text(entry.sets[i].prescription.loadKg == null
                      ? '–'
                      : UnitFormatters.formatWeight(
                          entry.sets[i].prescription.loadKg!, unit)),
                ),
                Expanded(child: Text('${entry.sets[i].prescription.reps}')),
                IconButton(
                  key: ValueKey('create-routine-edit-set-${entry.sets[i].id}'),
                  tooltip: 'Edit Set ${i + 1}',
                  onPressed: _enabled
                      ? () => _editSet(entry, entry.sets[i])
                      : null,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Remove Set ${i + 1}',
                  onPressed: _enabled
                      ? () => _draft.removeSet(entry.id, entry.sets[i].id)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
              ],
            ),
          TioButton.secondary(
            key: ValueKey('create-routine-add-set-${entry.id}'),
            label: 'Add Set',
            expand: true,
            onPressed: _enabled ? () => _editSet(entry) : null,
          ),
        ],
      ),
    );
  }
}
