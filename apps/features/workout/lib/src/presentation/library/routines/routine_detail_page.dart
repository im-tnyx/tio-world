import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/exercises/exercise_catalog_repository.dart';
import '../../../domain/exercises/user_exercise_repository.dart';
import '../../../domain/repositories/routine_composition_repository.dart';
import '../../../domain/repositories/routine_repository.dart';
import 'routine_detail_controller.dart';

/// A read-only preview of durable Routine content under its owning Program.
/// Starting a workout and modifying prescriptions require separate capabilities.
class RoutineDetailPage extends StatefulWidget {
  const RoutineDetailPage({
    required this.program,
    required this.routine,
    required this.routineRepository,
    required this.compositionRepository,
    required this.catalogRepository,
    this.userExerciseRepository,
    super.key,
  });

  final Program program;
  final Routine routine;
  final RoutineRepository? routineRepository;
  final RoutineCompositionRepository? compositionRepository;
  final ExerciseCatalogRepository catalogRepository;
  final UserExerciseRepository? userExerciseRepository;

  @override
  State<RoutineDetailPage> createState() => _RoutineDetailPageState();
}

class _RoutineDetailPageState extends State<RoutineDetailPage> {
  RoutineDetailController? _controller;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void didUpdateWidget(covariant RoutineDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.program.id != widget.program.id ||
        oldWidget.routine.id != widget.routine.id ||
        !identical(oldWidget.routineRepository, widget.routineRepository) ||
        !identical(oldWidget.compositionRepository,
            widget.compositionRepository) ||
        !identical(oldWidget.catalogRepository, widget.catalogRepository) ||
        !identical(oldWidget.userExerciseRepository,
            widget.userExerciseRepository)) {
      _bind();
    }
  }

  void _bind() {
    _controller
      ?..removeListener(_changed)
      ..dispose();
    final routines = widget.routineRepository;
    final compositions = widget.compositionRepository;
    if (routines == null || compositions == null) {
      _controller = null;
      return;
    }
    final controller = RoutineDetailController(
      program: widget.program,
      routine: widget.routine,
      routines: routines,
      compositions: compositions,
      catalog: widget.catalogRepository,
      userExercises: widget.userExerciseRepository,
    )..addListener(_changed);
    _controller = controller;
    controller.load();
  }

  void _changed() {
    if (mounted) setState(() {});
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
    final state = _controller?.state;
    return Scaffold(
      key: const ValueKey('routine-detail-page'),
      backgroundColor: colors.background,
      appBar: TioAppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          state?.routine?.name ?? 'Routine',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: TioFontSize.size20,
            fontWeight: TioFontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: TioSpacing.lg,
            vertical: TioSpacing.md,
          ),
          children: [_body(state)],
        ),
      ),
    );
  }

  Widget _body(RoutineDetailState? state) {
    if (state == null) {
      return const _RoutineDetailMessage(
        key: ValueKey('routine-detail-unavailable'),
        label: 'Routine details are unavailable right now.',
      );
    }
    switch (state.status) {
      case RoutineDetailStatus.loading:
        return const Center(
          key: ValueKey('routine-detail-loading'),
          child: CircularProgressIndicator(),
        );
      case RoutineDetailStatus.notFound:
        return const _RoutineDetailMessage(
          key: ValueKey('routine-detail-not-found'),
          label: 'This Routine is no longer available in this Program.',
        );
      case RoutineDetailStatus.failed:
        return Column(
          key: const ValueKey('routine-detail-failed'),
          children: [
            const _RoutineDetailMessage(
              label: 'Could not load Routine details. Please try again.',
            ),
            const SizedBox(height: TioSpacing.md),
            TioButton.secondary(
              key: const ValueKey('routine-detail-retry'),
              label: 'Try again',
              onPressed: _controller?.load,
            ),
          ],
        );
      case RoutineDetailStatus.ready:
        if (state.entries.isEmpty) {
          return const _RoutineDetailMessage(
            key: ValueKey('routine-detail-empty'),
            label: 'No exercises in this Routine yet.',
          );
        }
        return Column(
          key: const ValueKey('routine-detail-entries'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${state.exerciseCount} exercises · ${state.setCount} sets',
              key: const ValueKey('routine-detail-counts'),
              style: TextStyle(
                color: context.tioColors.textSecondary,
                fontSize: TioFontSize.size14,
              ),
            ),
            const SizedBox(height: TioSpacing.md),
            for (var i = 0; i < state.entries.length; i++) ...[
              TioCard(
                key: ValueKey('routine-detail-entry-${state.entries[i].entry.id}'),
                child: _RoutineEntryPreview(
                  index: i + 1,
                  item: state.entries[i],
                ),
              ),
              const SizedBox(height: TioSpacing.sm),
            ],
          ],
        );
    }
  }
}

class _RoutineEntryPreview extends StatelessWidget {
  const _RoutineEntryPreview({required this.index, required this.item});

  final int index;
  final RoutineDetailEntry item;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final entry = item.entry;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$index. ${item.exercise?.displayName ?? 'Exercise unavailable'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: TioFontWeight.w700,
            fontSize: TioFontSize.size15,
          ),
        ),
        if (item.exercise == null) ...[
          const SizedBox(height: TioSpacing.xs),
          Text(
            'Exercise information is not available in this app.',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: TioFontSize.size12,
            ),
          ),
        ],
        const SizedBox(height: TioSpacing.sm),
        for (var i = 0; i < entry.sets.length; i++) ...[
          Text(
            _setLabel(i + 1, entry.sets[i].prescription),
            key: ValueKey('routine-detail-set-${entry.sets[i].id}'),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: TioFontSize.size14,
            ),
          ),
          if (i + 1 < entry.sets.length)
            const SizedBox(height: TioSpacing.xs),
        ],
        if (entry.sets.isEmpty)
          Text(
            'No sets prescribed',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: TioFontSize.size14,
            ),
          ),
      ],
    );
  }

  static String _setLabel(int number, SetPrescription set) {
    final parts = <String>['Set $number', '${set.reps} reps'];
    if (set.loadKg != null) parts.add('${set.loadKg} kg');
    if (set.restSeconds != null) parts.add('${set.restSeconds} sec rest');
    return parts.join(' · ');
  }
}

class _RoutineDetailMessage extends StatelessWidget {
  const _RoutineDetailMessage({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(TioSpacing.xl),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.tioColors.textSecondary,
            fontSize: TioFontSize.size14,
          ),
        ),
      );
}
