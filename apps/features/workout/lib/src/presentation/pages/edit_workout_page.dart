import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/exercises/exercise_catalog.dart';
import '../../domain/exercises/exercise_catalog_repository.dart';
import '../../domain/exercises/user_exercise_repository.dart';
import '../../domain/models/workout_history_entry.dart';
import '../../domain/repositories/gym_location_repository.dart';
import '../../domain/repositories/routine_composition_repository.dart';
import '../../domain/repositories/workout_history_edit_repository.dart';
import '../../domain/repositories/workout_history_repository.dart';
import '../controllers/workout_history_edit_controller.dart';
import '../library/exercises/exercises_controller.dart';
import '../library/exercises/exercises_page.dart';
import '../library/exercises/exercises_providers.dart';
import '../library/routines/routine_exercise_options_sheet.dart';
import '../widgets/workout_exercise_card.dart';
import '../widgets/workout_rpe_sheet.dart';
import '../widgets/workout_set_input_row.dart';
import '../widgets/workout_set_type_sheet.dart';
import 'save_workout_page.dart';

/// Edits a canonical completed workout without creating an Active draft.
class EditWorkoutPage extends ConsumerStatefulWidget {
  const EditWorkoutPage({
    required this.sessionId,
    required this.historyRepository,
    required this.editRepository,
    required this.catalogRepository,
    this.userExerciseRepository,
    this.gymLocationRepository,
    super.key,
  });

  final WorkoutSessionId? sessionId;
  final WorkoutHistoryRepository? historyRepository;
  final WorkoutHistoryEditRepository? editRepository;
  final ExerciseCatalogRepository catalogRepository;
  final UserExerciseRepository? userExerciseRepository;
  final GymLocationRepository? gymLocationRepository;

  @override
  ConsumerState<EditWorkoutPage> createState() => _EditWorkoutPageState();
}

class _EditWorkoutPageState extends ConsumerState<EditWorkoutPage> {
  WorkoutHistoryDetail? _detail;
  WorkoutHistoryEditController? _controller;
  ExerciseCatalog? _catalog;
  bool _loading = true;
  bool _failed = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    unawaited(_loadCatalog());
  }

  @override
  void didUpdateWidget(covariant EditWorkoutPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId ||
        !identical(oldWidget.historyRepository, widget.historyRepository) ||
        !identical(oldWidget.editRepository, widget.editRepository)) {
      unawaited(_load());
    }
    if (!identical(oldWidget.catalogRepository, widget.catalogRepository)) {
      _catalog = null;
      unawaited(_loadCatalog());
    }
  }

  @override
  void dispose() {
    _generation++;
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    final repository = widget.catalogRepository;
    try {
      final catalog = await repository.load();
      if (mounted && identical(repository, widget.catalogRepository)) {
        setState(() => _catalog = catalog);
      }
    } catch (_) {
      // The saved exercise name and themed fallback remain usable.
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final repository = widget.historyRepository;
    final id = widget.sessionId;
    final previous = _controller;
    setState(() {
      _detail = null;
      _controller = null;
      _loading = repository != null && id != null;
      _failed = repository == null;
    });
    previous?.dispose();
    if (repository == null || id == null) return;
    try {
      final detail = await repository.getCompletedHistoryDetail(id);
      if (!mounted ||
          generation != _generation ||
          !identical(repository, widget.historyRepository) ||
          id != widget.sessionId) {
        return;
      }
      WorkoutHistoryEditController? controller;
      if (detail != null) {
        controller = WorkoutHistoryEditController(detail);
      }
      setState(() {
        _detail = detail;
        _controller = controller;
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      if (!mounted ||
          generation != _generation ||
          !identical(repository, widget.historyRepository) ||
          id != widget.sessionId) {
        return;
      }
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<List<Exercise>?> _selectExercises() =>
      Navigator.of(context).push<List<Exercise>>(
        MaterialPageRoute<List<Exercise>>(
          builder: (routeContext) => ProviderScope(
            child: ExercisesPage(
              catalogRepository: widget.catalogRepository,
              userExerciseRepository: widget.userExerciseRepository,
              onExercisesAdded: (selected) =>
                  Navigator.of(routeContext).pop<List<Exercise>>(selected),
            ),
          ),
        ),
      );

  Future<void> _addExercises(WorkoutHistoryEditController controller) async {
    final selected = await _selectExercises();
    if (!mounted ||
        !identical(controller, _controller) ||
        selected == null ||
        selected.isEmpty) {
      return;
    }
    try {
      controller.addExercises(selected);
    } catch (_) {
      _message('These exercises could not be added.');
    }
  }

  Future<void> _exerciseOptions(
      WorkoutHistoryEditController controller, int index) async {
    final action = await showRoutineExerciseOptionsSheet(context);
    if (!mounted || !identical(controller, _controller) || action == null) {
      return;
    }
    if (action == RoutineExerciseOption.remove) {
      controller.removeExercise(index);
      return;
    }
    final selected = await _selectExercises();
    if (!mounted ||
        !identical(controller, _controller) ||
        selected == null ||
        selected.isEmpty) {
      return;
    }
    try {
      controller.replaceExercise(index, selected.first);
    } catch (_) {
      _message('This exercise could not be replaced.');
    }
  }

  Future<void> _setOptions(WorkoutHistoryEditController controller,
      int exerciseIndex, int setIndex, RoutineCompositionSet set) async {
    final chosen = await showWorkoutSetTypeSheet(
      context: context,
      sets: [
        for (final item in controller.exercises[exerciseIndex].sets)
          RoutineCompositionSet(id: item.id, prescription: item.prescription)
      ],
      targetSet: set,
    );
    if (!mounted || !identical(controller, _controller) || chosen == null) {
      return;
    }
    if (chosen == 'remove') {
      controller.removeSet(exerciseIndex, setIndex);
    } else if (chosen is RoutineSetType) {
      final p = set.prescription;
      controller.changePrescription(
          exerciseIndex,
          setIndex,
          SetPrescription(
            setType: chosen,
            reps: p.reps,
            repsMax: p.repsMax,
            loadKg: p.loadKg,
            durationSeconds: p.durationSeconds,
            distanceMeters: p.distanceMeters,
            restSeconds: p.restSeconds,
          ));
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final controller = _controller;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_failed || widget.editRepository == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Workout')),
        body: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Could not load this workout. Check your connection.'),
          TextButton(
              onPressed: () => unawaited(_load()), child: const Text('Retry')),
        ])),
      );
    }
    if (detail == null || controller == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Workout')),
        body: const Center(child: Text('Completed workout not found.')),
      );
    }
    final mediaGender = ref.watch(exerciseViewerMediaGenderProvider);
    final offset = detail.utcOffsetMinutes ??
        detail.summary.displayAt.timeZoneOffset.inMinutes;
    final savedAt = detail.workoutAtUtc ?? detail.summary.completedAtUtc;
    final wall = savedAt.add(Duration(minutes: offset));
    final displayDate =
        DateTime(wall.year, wall.month, wall.day, wall.hour, wall.minute);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => SaveWorkoutPage(
        key: ValueKey('edit-workout-form-${detail.summary.sessionId.value}'),
        editMode: true,
        initialTitle: detail.summary.title,
        initialDescription: detail.summary.description,
        initialWorkoutDateTime: displayDate,
        initialWorkoutUtcOffsetMinutes: offset,
        initialActivityType: detail.activityType,
        initialRpe: detail.overallRpe,
        initialGym: detail.summary.gymName,
        duration: detail.summary.duration,
        volumeKg: controller.volumeKg,
        showVolume: controller.hasMeasuredVolume,
        completedSets: controller.completedSetCount,
        maximumWorkoutDateTime: DateTime(
          detail.summary.completedAtUtc.add(Duration(minutes: offset)).year,
          detail.summary.completedAtUtc.add(Duration(minutes: offset)).month,
          detail.summary.completedAtUtc.add(Duration(minutes: offset)).day,
          detail.summary.completedAtUtc.add(Duration(minutes: offset)).hour,
          detail.summary.completedAtUtc.add(Duration(minutes: offset)).minute,
        ),
        gymLocationRepository: widget.gymLocationRepository,
        exerciseSection: _exerciseSection(controller, mediaGender),
        onSave: (
            {required title,
            required description,
            required date,
            required utcOffsetMinutes,
            required rpe,
            required activityType,
            required gym,
            duration}) async {
          if (controller.hasPerformedSetLimitExceeded) {
            _message(
              'A workout can have at most '
              '${WorkoutHistoryEditController.maxPerformedSetsPerWorkout} '
              'performed sets. Remove sets before updating.',
            );
            return false;
          }
          if (controller.hasUnsupportedPerformedSets) {
            _message(
              'This workout exceeds the eight-set editor limit. '
              'Update is blocked to protect its saved data.',
            );
            return false;
          }
          if (!controller.canUpdate) {
            _message('Log at least one set for every exercise.');
            return false;
          }
          final instant = DateTime.utc(
                  date.year, date.month, date.day, date.hour, date.minute)
              .subtract(Duration(minutes: utcOffsetMinutes));
          try {
            await widget.editRepository!.updateCompletedWorkout(
              WorkoutHistoryEditRequest(
                source: detail,
                title: title,
                description: description,
                workoutAtUtc: instant,
                utcOffsetMinutes: utcOffsetMinutes,
                durationSeconds:
                    (duration ?? detail.summary.duration).inSeconds,
                gymName: gym,
                activityType: activityType,
                overallRpe: rpe,
                exercises: controller.exercises,
              ),
            );
            return mounted && identical(controller, _controller);
          } catch (_) {
            if (mounted) {
              _message(
                  'Update failed. Reload before retrying if it may have saved.');
            }
            return false;
          }
        },
      ),
    );
  }

  Future<void> _selectSetRpe(WorkoutHistoryEditController controller,
      int exerciseIndex, int setIndex) async {
    final current = controller.exercises[exerciseIndex].sets[setIndex];
    final selected = await showWorkoutRpeSheet(
      context: context,
      setNumber: setIndex + 1,
      loadKg: current.loadKg ?? current.prescription.loadKg,
      reps: current.reps ?? current.prescription.reps,
      initialRpe: current.rpe,
    );
    if (!mounted || selected == null || !identical(controller, _controller)) {
      return;
    }
    if (exerciseIndex >= controller.exercises.length ||
        setIndex >= controller.exercises[exerciseIndex].sets.length ||
        controller.exercises[exerciseIndex].sets[setIndex].id != current.id) {
      return;
    }
    controller.setRpe(exerciseIndex, setIndex, selected > 0 ? selected : null);
  }

  Widget _exerciseSection(
      WorkoutHistoryEditController controller, ExerciseMediaGender? gender) {
    final exercises = controller.exercises;
    final showRpe = MediaQuery.sizeOf(context).width >= 360;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
        child: Text('Workout', style: Theme.of(context).textTheme.titleLarge),
      ),
      const SizedBox(height: TioSpacing.md),
      for (final (exerciseIndex, exercise) in exercises.indexed)
        WorkoutExerciseCard(
          key: ValueKey('edit-workout-exercise-${exercise.id}'),
          mode: WorkoutExerciseCardMode.log,
          entry: RoutineCompositionEntry(
            id: exercise.id,
            exercise: exercise.exerciseRef,
            sets: [
              for (final set in exercise.sets)
                RoutineCompositionSet(
                    id: set.id, prescription: set.prescription)
            ],
          ),
          index: exerciseIndex,
          totalEntries: exercises.length,
          title: exercise.displayName,
          thumbnailUrl: _catalog?.byRef(exercise.exerciseRef) == null
              ? null
              : ExercisesController.thumbnailUrlFor(
                  _catalog!.byRef(exercise.exerciseRef)!,
                  gender: gender),
          exerciseType: exercise.exerciseType,
          showRangeDraft: false,
          unit: WeightUnit.kg,
          enabled: true,
          notesEnabled: false,
          showRpe: showRpe,
          keyPrefix: 'edit-workout-exercise',
          showOptions: () =>
              unawaited(_exerciseOptions(controller, exerciseIndex)),
          buildSetRow: (set, setIndex) {
            final current = exercise.sets[setIndex];
            return WorkoutSetInputRow(
              key: ValueKey('edit-workout-set-${current.id}'),
              rowKey: ValueKey('edit-workout-row-${current.id}'),
              set: set,
              index: setIndex,
              normalNumber: setIndex + 1,
              unit: WeightUnit.kg,
              enabled: true,
              exerciseType: exercise.exerciseType,
              showPrevious: true,
              isExecution: true,
              isLogged: current.loggedAtUtc != null && !current.isSkipped,
              showRpe: showRpe,
              performedLoadKg: current.loadKg,
              performedReps: current.reps,
              performedDurationSeconds: current.durationSeconds,
              performedDistanceMeters: current.distanceMeters,
              performedRpe: current.rpe,
              rpeKey: ValueKey('edit-workout-rpe-${current.id}'),
              onRpePressed: () =>
                  unawaited(_selectSetRpe(controller, exerciseIndex, setIndex)),
              toggleKey: ValueKey('edit-workout-set-toggle-${current.id}'),
              onChanged: (value) =>
                  controller.changePrescription(exerciseIndex, setIndex, value),
              onRemove: () => controller.removeSet(exerciseIndex, setIndex),
              onTypePressed: () => unawaited(
                  _setOptions(controller, exerciseIndex, setIndex, set)),
              onToggleLogged: (
                  {reps, loadKg, durationSeconds, distanceMeters}) async {
                controller.toggleLogged(exerciseIndex, setIndex,
                    reps: reps,
                    loadKg: loadKg,
                    durationSeconds: durationSeconds,
                    distanceMeters: distanceMeters);
              },
            );
          },
          addSet: () {
            try {
              controller.addSet(exerciseIndex);
            } catch (_) {
              _message('Set limit reached.');
            }
          },
        ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
        child: TioButton.secondary(
          key: const ValueKey('edit-workout-add-exercise'),
          label: 'Add Exercise',
          onPressed: () => unawaited(_addExercises(controller)),
        ),
      ),
    ]);
  }
}
