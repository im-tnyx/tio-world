import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/exercises/exercise_catalog.dart';
import '../../domain/exercises/exercise_catalog_repository.dart';
import '../../domain/models/workout_history_entry.dart';
import '../../domain/repositories/workout_history_repository.dart';
import '../library/exercises/exercises_controller.dart';
import '../library/exercises/exercises_providers.dart';

/// Read-only, owner-scoped detail of one completed WorkoutSession.
class WorkoutHistoryDetailPage extends ConsumerStatefulWidget {
  const WorkoutHistoryDetailPage({
    required this.sessionId,
    required this.repository,
    required this.catalogRepository,
    super.key,
  });

  final WorkoutSessionId? sessionId;
  final WorkoutHistoryRepository? repository;
  final ExerciseCatalogRepository catalogRepository;

  @override
  ConsumerState<WorkoutHistoryDetailPage> createState() =>
      _WorkoutHistoryDetailPageState();
}

class _WorkoutHistoryDetailPageState
    extends ConsumerState<WorkoutHistoryDetailPage> {
  WorkoutHistoryDetail? _detail;
  ExerciseCatalog? _catalog;
  bool _loading = true;
  bool _failed = false;
  int _generation = 0;
  int _catalogGeneration = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    unawaited(_loadCatalog());
  }

  @override
  void didUpdateWidget(covariant WorkoutHistoryDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final identityChanged =
        !identical(oldWidget.repository, widget.repository) ||
            oldWidget.sessionId != widget.sessionId;
    if (identityChanged) {
      unawaited(_load());
    }
    if (identityChanged ||
        !identical(oldWidget.catalogRepository, widget.catalogRepository)) {
      _catalog = null;
      unawaited(_loadCatalog());
    }
  }

  Future<void> _loadCatalog() async {
    final generation = ++_catalogGeneration;
    final repository = widget.catalogRepository;
    try {
      final catalog = await repository.load();
      if (mounted &&
          generation == _catalogGeneration &&
          identical(repository, widget.catalogRepository)) {
        setState(() => _catalog = catalog);
      }
    } catch (_) {
      // The frozen exercise name and themed image fallback remain available.
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final repository = widget.repository;
    final sessionId = widget.sessionId;
    setState(() {
      _detail = null;
      _loading = repository != null && sessionId != null;
      _failed = repository == null;
    });
    if (repository == null || sessionId == null) return;
    try {
      final detail = await repository.getCompletedHistoryDetail(sessionId);
      if (!mounted ||
          generation != _generation ||
          !identical(repository, widget.repository) ||
          sessionId != widget.sessionId) {
        return;
      }
      setState(() {
        _detail = detail;
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      if (!mounted ||
          generation != _generation ||
          !identical(repository, widget.repository) ||
          sessionId != widget.sessionId) {
        return;
      }
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final detail = _detail;
    Widget body;
    if (_loading) {
      body = const Center(
        child: CircularProgressIndicator(
          key: ValueKey('workout-history-detail-loading'),
        ),
      );
    } else if (_failed) {
      body = _DetailFeedback(
        message: 'Could not load this workout. Check your connection.',
        onRetry: () => unawaited(_load()),
      );
    } else if (detail == null) {
      body = const Center(child: Text('Completed workout not found.'));
    } else {
      final mediaGender = ref.watch(exerciseViewerMediaGenderProvider);
      final rows = <Widget>[
        _Summary(detail: detail),
        const SizedBox(height: TioSpacing.xl),
        Row(
          children: [
            Expanded(
              child: Text('Workout',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            // The owner will specify Edit Workout behavior in a later slice.
            const Flexible(
              child: TextButton(
                key: ValueKey('workout-history-detail-edit'),
                onPressed: null,
                child: Text('Edit Workout', textAlign: TextAlign.end),
              ),
            ),
          ],
        ),
        const SizedBox(height: TioSpacing.md),
      ];
      for (final (index, exercise) in detail.exercises.indexed) {
        if (index > 0) rows.add(const SizedBox(height: TioSpacing.lg));
        final catalogExercise = _catalog?.byRef(exercise.ref);
        final media = catalogExercise == null
            ? null
            : ExercisesController.thumbnailUrlFor(
                catalogExercise,
                gender: mediaGender,
              );
        rows.add(_ExerciseHeading(exercise: exercise, media: media));
        rows.add(const SizedBox(height: TioSpacing.sm));
        rows.add(_SetColumnHeading(exercise: exercise));
        for (final (setNumber, set) in exercise.sets.indexed) {
          rows.add(_PerformedSetRow(
            set: set,
            setNumber: setNumber + 1,
          ));
        }
      }
      if (detail.exercises.isEmpty) {
        rows.add(const Text('No performed exercises were saved.'));
      }
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          key: const ValueKey('workout-history-detail-list'),
          padding: const EdgeInsets.all(TioSpacing.lg),
          itemCount: rows.length,
          itemBuilder: (_, index) => rows[index],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Detail')),
      body: ColoredBox(color: colors.background, child: body),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.detail});

  final WorkoutHistoryDetail detail;

  @override
  Widget build(BuildContext context) {
    final entry = detail.summary;
    final colors = context.tioColors;
    final theme = Theme.of(context).textTheme;
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatFullDate(entry.displayAt);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(entry.displayAt),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(entry.title, style: theme.headlineSmall),
        if (entry.description case final description?) ...[
          const SizedBox(height: TioSpacing.sm),
          Text(description,
              style: theme.bodyMedium?.copyWith(color: colors.textSecondary)),
        ],
        const SizedBox(height: TioSpacing.lg),
        Wrap(
          spacing: TioSpacing.xl,
          runSpacing: TioSpacing.sm,
          children: [
            _Statistic(label: 'Time', value: _formatDuration(entry.duration)),
            if (entry.volumeKg case final volume?)
              _Statistic(label: 'Volume', value: '${_formatNumber(volume)} kg'),
            _Statistic(label: 'Sets', value: '${detail.performedSetCount}'),
          ],
        ),
        const SizedBox(height: TioSpacing.lg),
        Text('$date · $time',
            style: theme.bodyMedium?.copyWith(color: colors.textSecondary)),
        if (entry.gymName case final gym?) ...[
          const SizedBox(height: TioSpacing.xs),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: TioSize.dp16, color: colors.textSecondary),
              const SizedBox(width: TioSpacing.xs),
              Expanded(
                child: Text(gym,
                    style: theme.bodyMedium
                        ?.copyWith(color: colors.textSecondary)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Statistic extends StatelessWidget {
  const _Statistic({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: context.tioColors.textSecondary)),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      );
}

class _ExerciseHeading extends StatelessWidget {
  const _ExerciseHeading({required this.exercise, required this.media});

  final WorkoutHistoryDetailExercise exercise;
  final Uri? media;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          TioAvatar(
            size: TioAvatarSize.small,
            imageUrl: media?.toString(),
            fallbackIcon: Icons.fitness_center,
          ),
          const SizedBox(width: TioSpacing.sm),
          Expanded(
            child: Text(exercise.name,
                style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      );
}

class _SetColumnHeading extends StatelessWidget {
  const _SetColumnHeading({required this.exercise});

  final WorkoutHistoryDetailExercise exercise;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final hasDistance = exercise.sets.any((set) => set.distanceMeters != null);
    final hasDuration = exercise.sets.any((set) => set.durationSeconds != null);
    final hasLoad = exercise.sets.any((set) => set.loadKg != null);
    final hasReps = exercise.sets.any((set) => set.reps != null);
    final measurement = hasDistance && hasDuration
        ? 'DISTANCE & DURATION'
        : hasDistance
            ? 'DISTANCE'
            : hasDuration
                ? 'DURATION'
                : hasLoad && hasReps
                    ? 'WEIGHT & REPS'
                    : hasLoad
                        ? 'WEIGHT'
                        : hasReps
                            ? 'REPS'
                            : 'PERFORMED';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TioSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: TioSize.dp44,
            child: Text('SET',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: colors.textSecondary)),
          ),
          const SizedBox(width: TioSpacing.sm),
          Expanded(
            child: Text(measurement,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: colors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _PerformedSetRow extends StatelessWidget {
  const _PerformedSetRow({required this.set, required this.setNumber});

  final PerformedSet set;
  final int setNumber;

  @override
  Widget build(BuildContext context) {
    final values = <String>[
      if (set.distanceMeters case final distance?)
        '${_formatNumber(distance / 1000)} km',
      if (set.durationSeconds case final seconds?)
        _formatDuration(Duration(seconds: seconds)),
      if (set.loadKg case final load?)
        set.reps == null
            ? '${_formatNumber(load)} kg'
            : '${_formatNumber(load)} kg × ${set.reps}',
      if (set.loadKg == null && set.reps != null) '${set.reps} reps',
    ];
    final measurement = values.isEmpty ? 'Completed set' : values.join(' · ');
    return Semantics(
      label: 'Set $setNumber, $measurement',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: TioSpacing.sm),
        child: Row(
          children: [
            SizedBox(width: TioSize.dp44, child: Text('$setNumber')),
            const SizedBox(width: TioSpacing.sm),
            Expanded(child: Text(measurement)),
          ],
        ),
      ),
    );
  }
}

class _DetailFeedback extends StatelessWidget {
  const _DetailFeedback({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(TioSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: TioSpacing.sm),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}

String _formatNumber(double number) => number == number.roundToDouble()
    ? number.toStringAsFixed(0)
    : number.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  if (hours > 0) {
    return seconds == 0
        ? '${hours}h ${minutes}min'
        : '${hours}h ${minutes}min ${seconds}s';
  }
  if (minutes > 0) {
    return seconds == 0
        ? '${duration.inMinutes}min'
        : '${duration.inMinutes}min ${seconds}s';
  }
  return '${duration.inSeconds}s';
}
