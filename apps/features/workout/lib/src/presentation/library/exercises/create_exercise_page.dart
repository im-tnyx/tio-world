import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/exercises/user_exercise_repository.dart';
import 'custom_exercise_editor_page.dart';
import 'custom_exercises_controller.dart';
import 'custom_exercises_state.dart';

/// Direct Library-owned entry for creating a user Exercise.
///
/// This page owns only the presentation controller lifecycle. The editor,
/// repository contract, identity generation, and persistence semantics remain
/// the canonical W3D Custom Exercise flow.
class CreateExercisePage extends StatefulWidget {
  const CreateExercisePage({
    required this.repository,
    super.key,
  });

  final UserExerciseRepository repository;

  @override
  State<CreateExercisePage> createState() => _CreateExercisePageState();
}

class _CreateExercisePageState extends State<CreateExercisePage> {
  late final CustomExercisesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CustomExercisesController(repository: widget.repository)
      ..addListener(_onControllerChanged)
      ..load();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;

    return switch (state.status) {
      CustomExercisesStatus.loading => const _CreateExerciseLoading(),
      CustomExercisesStatus.loadFailed => _CreateExerciseLoadFailure(
          message: state.loadError ??
              'Could not load custom exercises. Please try again.',
          onRetry: _controller.retryLoad,
        ),
      CustomExercisesStatus.ready => CustomExerciseEditorPage(
          controller: _controller,
        ),
    };
  }
}

class _CreateExerciseLoading extends StatelessWidget {
  const _CreateExerciseLoading();

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Scaffold(
      key: const ValueKey('create-exercise-loading'),
      backgroundColor: colors.background,
      appBar: TioAppBar(
        leading: BackButton(color: colors.textPrimary),
        title: const Text('Create Exercise'),
      ),
      body: const Center(
        child: CircularProgressIndicator(
          semanticsLabel: 'Loading Create Exercise',
        ),
      ),
    );
  }
}

class _CreateExerciseLoadFailure extends StatelessWidget {
  const _CreateExerciseLoadFailure({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Scaffold(
      key: const ValueKey('create-exercise-load-failure'),
      backgroundColor: colors.background,
      appBar: TioAppBar(
        leading: BackButton(color: colors.textPrimary),
        title: const Text('Create Exercise'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(TioSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary),
              ),
              const SizedBox(height: TioSpacing.lg),
              TioButton.primary(
                key: const ValueKey('create-exercise-retry'),
                label: 'Retry',
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
