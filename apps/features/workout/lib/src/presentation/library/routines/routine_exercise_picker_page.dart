import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/exercises/exercise_catalog_repository.dart';
import '../../../domain/exercises/user_exercise_repository.dart';
import '../exercises/exercises_state.dart';
import '../exercises/widgets/exercise_list_row.dart';
import 'routine_exercise_picker_controller.dart';

/// Routine-context canonical Exercise search. Pops one Exercise on selection,
/// or null on Back/Cancel; never writes to the Routine itself.
class RoutineExercisePickerPage extends StatefulWidget {
  const RoutineExercisePickerPage({
    required this.catalogRepository,
    this.userExerciseRepository,
    super.key,
  });

  final ExerciseCatalogRepository catalogRepository;
  final UserExerciseRepository? userExerciseRepository;

  @override
  State<RoutineExercisePickerPage> createState() =>
      _RoutineExercisePickerPageState();
}

class _RoutineExercisePickerPageState extends State<RoutineExercisePickerPage> {
  RoutineExercisePickerController? _controller;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void didUpdateWidget(covariant RoutineExercisePickerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.catalogRepository, widget.catalogRepository) ||
        !identical(
            oldWidget.userExerciseRepository, widget.userExerciseRepository)) {
      _bind();
    }
  }

  void _bind() {
    _controller
      ?..removeListener(_changed)
      ..dispose();

    final controller = RoutineExercisePickerController(
      catalogRepository: widget.catalogRepository,
      userExerciseRepository: widget.userExerciseRepository,
    )..addListener(_changed);
    _controller = controller;
    controller.load();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _choose(ExerciseListItem item) {
    final chosen = _controller?.select(item.exercise.ref);
    if (chosen != null) Navigator.of(context).pop<Exercise>(chosen);
  }

  @override
  void dispose() {
    _controller
      ?..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final state = _controller!.state;
    return Scaffold(
      key: const ValueKey('routine-exercise-picker-page'),
      backgroundColor: colors.background,
      appBar: TioAppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          'Add Exercise',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: TioFontSize.size20,
            fontWeight: TioFontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: state.status == RoutineExercisePickerStatus.ready
            ? Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(TioSpacing.lg),
                    child: TioInput(
                      key: const ValueKey('routine-exercise-picker-search'),
                      hint: 'Search exercises',
                      value: state.query,
                      leading: Icon(
                        Icons.search_rounded,
                        color: colors.textSecondary,
                      ),
                      textInputAction: TextInputAction.search,
                      onChanged: _controller!.search,
                    ),
                  ),
                  Expanded(child: _results(state)),
                ],
              )
            : _notReady(state.status),
      ),
    );
  }

  Widget _results(RoutineExercisePickerState state) {
    if (state.items.isEmpty) {
      return Center(
        key: ValueKey(state.hasActiveExercises
            ? 'routine-exercise-picker-no-match'
            : 'routine-exercise-picker-empty'),
        child: Text(
          state.hasActiveExercises
              ? 'No exercises match your search.'
              : 'No exercises available yet.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.tioColors.textSecondary),
        ),
      );
    }
    return ListView.builder(
      key: const ValueKey('routine-exercise-picker-results'),
      itemCount: state.items.length,
      itemBuilder: (context, index) {
        final item = state.items[index];
        return ExerciseListRow(
          key: ValueKey('routine-exercise-picker-${item.exercise.ref.value}'),
          item: item,
          onTap: () => _choose(item),
        );
      },
    );
  }

  Widget _notReady(RoutineExercisePickerStatus status) {
    switch (status) {
      case RoutineExercisePickerStatus.loading:
        return const Center(
          key: ValueKey('routine-exercise-picker-loading'),
          child: CircularProgressIndicator(
            semanticsLabel: 'Loading exercises',
          ),
        );
      case RoutineExercisePickerStatus.failed:
        return Center(
          key: const ValueKey('routine-exercise-picker-failed'),
          child: Padding(
            padding: const EdgeInsets.all(TioSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Could not load exercises. Try again.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: TioSpacing.lg),
                TioButton.secondary(
                  key: const ValueKey('routine-exercise-picker-retry'),
                  label: 'Try again',
                  onPressed: _controller?.load,
                ),
              ],
            ),
          ),
        );
      case RoutineExercisePickerStatus.ready:
        return const SizedBox.shrink();
    }
  }
}
