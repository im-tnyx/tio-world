import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/exercises/exercise_catalog_repository.dart';
import '../exercises/exercises_controller.dart';
import 'routine_set_input_limits.dart';
import 'routine_measurement_profile.dart';
import '../exercises/widgets/exercise_list_row.dart';
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
    this.viewerMediaGender,
    this.weightUnit = WeightUnit.kg,
    this.onEditPressed,
    super.key,
  });

  final Program program;
  final Routine routine;
  final RoutineRepository? routineRepository;
  final RoutineCompositionRepository? compositionRepository;
  final ExerciseCatalogRepository catalogRepository;
  final UserExerciseRepository? userExerciseRepository;
  /// Media profile is resolved by the app; null follows the catalog fallback.
  final ExerciseMediaGender? viewerMediaGender;
  /// Null means the authenticated account's display unit has not resolved.
  final WeightUnit? weightUnit;

  /// App-provided, account-verified navigation. True only on confirmed save.
  /// No edit capability is inferred from a read-only Detail repository.
  final Future<bool?> Function(Routine routine)? onEditPressed;

  @override
  State<RoutineDetailPage> createState() => _RoutineDetailPageState();
}

class _RoutineDetailPageState extends State<RoutineDetailPage> {
  RoutineDetailController? _controller;
  bool _editing = false;

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

  Future<void> _openEditor() async {
    final controller = _controller;
    final state = controller?.state;
    final edit = widget.onEditPressed;
    final routine = state?.routine;
    if (_editing ||
        controller == null ||
        state?.status != RoutineDetailStatus.ready ||
        routine == null ||
        widget.weightUnit == null ||
        edit == null) {
      return;
    }
    setState(() => _editing = true);
    bool? confirmed;
    try {
      confirmed = await edit(routine);
    } finally {
      if (mounted && identical(controller, _controller)) {
        setState(() => _editing = false);
      }
    }
    if (!mounted || !identical(controller, _controller)) return;
    // Always re-read owner-verified server truth after confirmed Update.
    if (confirmed == true) await controller.load();
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
        child: state != null &&
                state.status == RoutineDetailStatus.ready
            ? _readyList(state)
            : ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: TioSpacing.lg,
                  vertical: TioSpacing.md,
                ),
                children: [_body(state)],
              ),
      ),
    );
  }

  /// The same owner-verified Edit capability applies to ready-but-empty
  /// Routines; loading/not-found/failed states never expose editing.
  bool _canShowEdit(RoutineDetailState state) =>
      widget.onEditPressed != null &&
      widget.weightUnit != null &&
      state.status == RoutineDetailStatus.ready &&
      state.routine != null;

  /// Keep persisted entries lazy with a shared header for ready states.
  Widget _readyList(RoutineDetailState state) => ListView.builder(
        key: const ValueKey('routine-detail-entries'),
        padding: const EdgeInsets.symmetric(
          horizontal: TioSpacing.lg,
          vertical: TioSpacing.md,
        ),
        itemCount: state.entries.isEmpty ? 2 : state.entries.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: TioSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Exercises',
                          key: const ValueKey('routine-detail-exercises-header'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: context.tioColors.textSecondary,
                          ),
                        ),
                      ),
                      if (_canShowEdit(state))
                        TextButton(
                          key: const ValueKey('routine-detail-edit'),
                          onPressed: _editing ? null : _openEditor,
                          child: const Text('Edit Routine'),
                        ),
                    ],
                  ),
                  Semantics(
                    label: '${state.exerciseCount} exercises, ${state.setCount} sets',
                    child: Text(
                      '${state.exerciseCount} ${state.exerciseCount == 1 ? 'exercise' : 'exercises'} · '
                      '${state.setCount} ${state.setCount == 1 ? 'set' : 'sets'}',
                      key: const ValueKey('routine-detail-counts'),
                      style: TextStyle(
                        color: context.tioColors.textSecondary,
                        fontSize: TioFontSize.size12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          if (state.entries.isEmpty) {
            return const _RoutineDetailMessage(
              key: ValueKey('routine-detail-empty'),
              label: 'No exercises in this Routine yet.',
            );
          }
          final entry = state.entries[index - 1];
          return Padding(
            key: ValueKey('routine-detail-entry-${entry.entry.id}'),
            padding: const EdgeInsets.only(bottom: TioSpacing.xl),
            child: _RoutineEntryPreview(
              index: index,
              item: entry,
              weightUnit: widget.weightUnit,
              viewerMediaGender: widget.viewerMediaGender,
            ),
          );
        },
      );

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
        // Ready content, including historical empties, uses _readyList.
        return const SizedBox.shrink();
    }
  }
}

class _RoutineEntryPreview extends StatelessWidget {
  const _RoutineEntryPreview({
    required this.index,
    required this.item,
    required this.weightUnit,
    required this.viewerMediaGender,
  });

  final int index;
  final RoutineDetailEntry item;
  final WeightUnit? weightUnit;
  final ExerciseMediaGender? viewerMediaGender;

  // Bound exceptionally long persisted Routines rather than constructing
  // thousands of rows in a single frame.
  static const _inlineSetLimit = 40;

  static String _typeLabel(SetPrescription p, int normalNumber) =>
      switch (p.setType) {
        RoutineSetType.normal => '$normalNumber',
        RoutineSetType.warmUp => 'W',
        RoutineSetType.failure => 'F',
        RoutineSetType.drop => 'D',
      };

  Widget _cell(String value, {Color? color, TextAlign align = TextAlign.center}) =>
      Text(value, textAlign: align,
        style: TextStyle(color: color, fontSize: TioFontSize.size14));

  Widget _setRow(
    BuildContext context, int index, ExerciseType? profile,
  ) {
    final sets = item.entry.sets;
    final p = sets[index].prescription;
    final normalNumber = sets.take(index + 1)
        .where((s) => s.prescription.setType == RoutineSetType.normal)
        .length;
    final weight = p.loadKg == null
        ? '–'
        : weightUnit == null
            ? 'Load unavailable'
            : UnitFormatters.formatWeight(p.loadKg!, weightUnit!).split(' ').first;
    final reps = p.repsMax == null
        ? (p.reps?.toString() ?? '–')
        : '${p.reps}–${p.repsMax}';
    final distance = p.distanceMeters == null
        ? '–'
        : RoutineSetInputLimits.displayDistanceKm(p.distanceMeters);
    final time = p.durationSeconds == null
        ? '–'
        : RoutineSetInputLimits.displayDurationSeconds(p.durationSeconds);
    final values = profile == ExerciseType.distanceDuration
        ? [distance, time]
        : profile == ExerciseType.duration
            ? [time]
            : [weight, reps];
    final color = context.tioColors.textPrimary;
    return Semantics(
      label: 'Set ${index + 1}, ${p.setType.name}, ${values.join(', ')}'
          '${p.restSeconds == null ? '' : ', rest ${p.restSeconds} seconds'}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: TioSpacing.sm),
        child: Row(
          key: ValueKey('routine-detail-set-${sets[index].id}'),
          children: [
            SizedBox(
              width: TioSize.dp44,
              child: _cell(_typeLabel(p, normalNumber), color: color),
            ),
            const SizedBox(width: TioSpacing.sm),
            for (var i = 0; i < values.length; i++) ...[
              if (i > 0) const SizedBox(width: TioSpacing.sm),
              Expanded(
                child: _cell(
                  values[i],
                  color: i == 0 && profile != ExerciseType.duration
                      ? context.tioColors.textSecondary
                      : color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final entry = item.entry;
    final source = item.exercise;
    final profile = routineEntryMeasurementProfile(
      source?.exerciseType,
      entry.sets,
    );
    final thumbnail = source == null
        ? null
        : ExercisesController.thumbnailUrlFor(
            source,
            gender: viewerMediaGender,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (thumbnail != null)
              ExerciseThumbnail(url: thumbnail),
            Expanded(
              child: Text(
                item.exercise?.displayName ?? 'Exercise unavailable',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: TioFontWeight.w400,
                  fontSize: TioFontSize.size16,
                ),
              ),
            ),
          ],
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
        const SizedBox(height: TioSpacing.md),
        Row(
          children: [
            const SizedBox(
              width: TioSize.dp44,
              child: Text('SET', textAlign: TextAlign.center),
            ),
            const SizedBox(width: TioSpacing.sm),
            if (profile == ExerciseType.distanceDuration) ...[
              const Expanded(child: Text('KM', textAlign: TextAlign.center)),
              const SizedBox(width: TioSpacing.sm),
              const Expanded(child: Text('TIME', textAlign: TextAlign.center)),
            ] else if (profile == ExerciseType.duration) ...[
              const Expanded(child: Text('TIME', textAlign: TextAlign.center)),
            ] else ...[
              Expanded(child: Text(
                weightUnit == null
                    ? 'WEIGHT'
                    : weightUnit == WeightUnit.lb ? 'LB' : 'KG',
                textAlign: TextAlign.center,
              )),
              const SizedBox(width: TioSpacing.sm),
              const Expanded(child: Text('REPS', textAlign: TextAlign.center)),
            ],
          ],
        ),
        const SizedBox(height: TioSpacing.sm),
        if (entry.sets.length > _inlineSetLimit)
          SizedBox(
            height: TioSize.dp200,
            child: ListView.builder(
              key: ValueKey('routine-detail-set-list-${entry.id}'),
              primary: false,
              padding: EdgeInsets.zero,
              itemCount: entry.sets.length,
              itemBuilder: (context, index) => _setRow(context, index, profile),
            ),
          )
        else
          for (var i = 0; i < entry.sets.length; i++)
            _setRow(context, i, profile),
        if (entry.sets.isEmpty)
          Text('No sets prescribed',
              style: TextStyle(color: colors.textSecondary)),
      ],
    );
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
