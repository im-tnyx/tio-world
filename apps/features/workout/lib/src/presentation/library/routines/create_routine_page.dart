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
import 'routine_set_input_row.dart';

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
  final Set<String> _invalidSetIds = {};
  String? _openSetId;

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
      _invalidSetIds.clear();
      _openSetId = null;
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

  void _validityChanged(String setId, bool valid) {
    if (!mounted) return;
    setState(() {
      if (valid) {
        _invalidSetIds.remove(setId);
      } else {
        _invalidSetIds.add(setId);
      }
    });
  }

  void _removeEntry(RoutineCompositionEntry entry) {
    if (!_enabled) return;
    if (entry.sets.any((set) => set.id == _openSetId)) _openSetId = null;
    _draft.removeExercise(entry.id);
    _entryLabels.remove(entry.id);
    _invalidSetIds.removeAll(entry.sets.map((set) => set.id));
  }

  void _removeSet(RoutineCompositionEntry entry, RoutineCompositionSet set) {
    if (!_enabled) return;
    if (entry.sets.length == 1) {
      // Removing the last Set removes this entire unsaved Exercise, instead
      // of leaving a nameless zero-Set Exercise behind.
      _removeEntry(entry);
      return;
    }
    if (_openSetId == set.id) _openSetId = null;
    _draft.removeSet(entry.id, set.id);
    _invalidSetIds.remove(set.id);
  }

  void _addSet(RoutineCompositionEntry entry) {
    if (!_enabled) return;
    // The reference's Add Set is immediate: no modal or second confirmation.
    if (_openSetId != null) setState(() => _openSetId = null);
    _draft.addSet(entry.id, SetPrescription(reps: 1));
  }

  void _setOpen(String id, bool open) {
    if (!mounted) return;
    final next = open ? id : (_openSetId == id ? null : _openSetId);
    if (next != _openSetId) setState(() => _openSetId = next);
  }

  Future<void> _selectSetType(
    RoutineCompositionEntry entry,
    RoutineCompositionSet set,
  ) async {
    if (!_enabled) return;
    final chosen = await showTioEditorSheet<Object>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => TioEditorSheet(
        title: 'Select Set Type',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final type in RoutineSetType.values)
              ListTile(
                key: ValueKey('routine-type-option-${type.wireValue}'),
                leading: Text(switch (type) {
                  RoutineSetType.normal => '1',
                  RoutineSetType.warmUp => 'W',
                  RoutineSetType.failure => 'F',
                  RoutineSetType.drop => 'D',
                }),
                title: Text(switch (type) {
                  RoutineSetType.normal => 'Normal Set',
                  RoutineSetType.warmUp => 'Warm Up Set',
                  RoutineSetType.failure => 'Failure Set',
                  RoutineSetType.drop => 'Drop Set',
                }),
                trailing: type == set.prescription.setType
                    ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(sheetContext).pop<Object>(type),
              ),
            ListTile(
              key: const ValueKey('routine-type-remove-set'),
              leading: Icon(Icons.close, color: context.tioColors.danger),
              title: Text('Remove Set',
                style: TextStyle(color: context.tioColors.danger)),
              onTap: () => Navigator.of(sheetContext).pop<Object>('remove'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || !_enabled || chosen == null) return;
    if (chosen is RoutineSetType) {
      _draft.changeSetType(entry.id, set.id, chosen);
    } else if (chosen == 'remove') {
      _removeSet(entry, set);
    }
  }

  Future<void> _selectRepetitionMode(RoutineCompositionEntry entry) async {
    if (!_enabled ||
        entry.sets.any((set) => _invalidSetIds.contains(set.id))) return;
    final isRange = entry.sets.isNotEmpty &&
        entry.sets.first.prescription.isRepRange;
    final chosen = await showTioEditorSheet<bool>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => TioEditorSheet(
        title: 'Repetition Options',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const ValueKey('routine-repetition-fixed'),
              title: const Text('Reps'),
              trailing: !isRange ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(sheetContext).pop<bool>(false),
            ),
            ListTile(
              key: const ValueKey('routine-repetition-range'),
              title: const Text('Rep Range'),
              trailing: isRange ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(sheetContext).pop<bool>(true),
            ),
          ],
        ),
      ),
    );
    if (!mounted || !_enabled || chosen == null) return;
    final current = _draft.state.entries.where((e) => e.id == entry.id);
    if (current.length != 1 ||
        current.single.sets.any((s) => _invalidSetIds.contains(s.id))) return;
    _draft.changeRepetitionMode(entry.id, range: chosen);
  }

  Future<void> _save() async {
    if (!_draft.state.canSave || !_enabled || _invalidSetIds.isNotEmpty) return;
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
    final canSave = _enabled && _draft.state.canSave && _invalidSetIds.isEmpty;
    return PopScope(
      canPop: !locked,
      child: Scaffold(
        key: const ValueKey('create-routine-page'),
        backgroundColor: colors.background,
        appBar: TioAppBar(
          backgroundColor: colors.background,
          elevation: TioElevation.none,
          scrolledUnderElevation: TioElevation.none,
          automaticallyImplyLeading: false,
          // The reference uses two visible text actions, not an icon-only
          // back button. Keep them inside the governed top bar so Cancel
          // cannot be clipped to Material's narrow leading-icon slot.
          title: Row(
            children: [
              TextButton(
                key: const ValueKey('create-routine-cancel'),
                onPressed: locked
                    ? null
                    : () => Navigator.of(context).pop<bool>(false),
                child: const Text('Cancel'),
              ),
              Expanded(
                child: Text(
                  'Create Routine',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: TioFontSize.size20,
                    fontWeight: TioFontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                key: const ValueKey('create-routine-save'),
                onPressed: canSave ? _save : null,
                child: const Text('Save'),
              ),
            ],
          ),
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


  Widget _setRow(
    RoutineCompositionEntry entry,
    RoutineCompositionSet set,
    int index,
  ) =>
      RoutineSetInputRow(
        key: ValueKey('create-routine-set-${set.id}'),
        set: set,
        index: index,
        normalNumber: entry.sets
            .take(index + 1)
            .where((s) => s.prescription.setType == RoutineSetType.normal)
            .length,
        onTypePressed: () => _selectSetType(entry, set),
        unit: widget.weightUnit,
        enabled: _enabled,
        isOpen: _openSetId == set.id,
        onOpenChanged: (open) => _setOpen(set.id, open),
        onChanged: (prescription) =>
            _draft.editSet(entry.id, set.id, prescription),
        onValidityChanged: (valid) => _validityChanged(set.id, valid),
        onRemove: () => _removeSet(entry, set),
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
                onPressed: _enabled ? () => _removeEntry(entry) : null,
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
              const SizedBox(
                width: TioSize.dp44,
                child: Text('SET', textAlign: TextAlign.center),
              ),
              const SizedBox(width: TioSpacing.sm),
              Expanded(
                child: Text(
                  unit == WeightUnit.kg ? 'KG' : 'LB',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: TioSpacing.sm),
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Repetition Options',
                  child: InkWell(
                    key: ValueKey('create-routine-repetition-options-${entry.id}'),
                    onTap: _enabled
                        ? () => _selectRepetitionMode(entry)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: TioSpacing.sm),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              entry.sets.isNotEmpty &&
                                      entry.sets.first.prescription.isRepRange
                                  ? 'REP RANGE'
                                  : 'REPS',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: TioSize.dp48),
            ],
          ),
          for (var i = 0; i < entry.sets.length; i++)
            _setRow(entry, entry.sets[i], i),
          TioButton.secondary(
            key: ValueKey('create-routine-add-set-${entry.id}'),
            label: 'Add Set',
            expand: true,
            onPressed: _enabled ? () => _addSet(entry) : null,
          ),
        ],
      ),
    );
  }
}
