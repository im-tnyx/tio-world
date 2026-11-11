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

/// Authenticated, completed-only Workout history. No card selection until W8 Detail.
class WorkoutHistoryPage extends ConsumerStatefulWidget {
  const WorkoutHistoryPage({
    required this.repository,
    required this.catalogRepository,
    super.key,
  });

  final WorkoutHistoryRepository? repository;
  final ExerciseCatalogRepository catalogRepository;

  @override
  ConsumerState<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends ConsumerState<WorkoutHistoryPage> {
  List<WorkoutHistoryEntry> _entries = const [];
  WorkoutHistoryCursor? _cursor;
  ExerciseCatalog? _catalog;
  Object? _error;
  Object? _moreError;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load(reset: true));
    unawaited(_loadCatalog());
  }

  @override
  void didUpdateWidget(covariant WorkoutHistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.repository, widget.repository)) {
      // Clear former account data synchronously, before any new async read.
      unawaited(_load(reset: true));
    }
    if (!identical(oldWidget.catalogRepository, widget.catalogRepository)) {
      _catalog = null;
      unawaited(_loadCatalog());
    }
  }

  Future<void> _loadCatalog() async {
    final repository = widget.catalogRepository;
    try {
      final catalog = await repository.load();
      if (mounted && identical(repository, widget.catalogRepository)) {
        setState(() => _catalog = catalog);
      }
    } catch (_) {
      // Historical names and a themed exercise fallback remain usable.
    }
  }

  Future<void> _load({required bool reset}) async {
    final repository = widget.repository;
    if (reset) {
      _generation++;
      setState(() {
        _entries = const [];
        _cursor = null;
        _hasMore = false;
        _error = null;
        _moreError = null;
        _loading = true;
        _loadingMore = false;
      });
    } else {
      if (_loading || _loadingMore || !_hasMore || repository == null) return;
      setState(() {
        _loadingMore = true;
        _moreError = null;
      });
    }
    final generation = _generation;
    if (repository == null) {
      if (mounted && generation == _generation) {
        setState(() {
          _loading = false;
          _error = StateError('No authenticated Workout repository');
        });
      }
      return;
    }
    try {
      final page = await repository.listCompletedHistory(
        after: reset ? null : _cursor,
      );
      if (!mounted ||
          generation != _generation ||
          !identical(repository, widget.repository)) {
        return;
      }
      setState(() {
        final seen = _entries.map((item) => item.sessionId.value).toSet();
        _entries = [
          ..._entries,
          for (final item in page.entries)
            if (seen.add(item.sessionId.value)) item,
        ];
        _cursor = page.nextCursor;
        _hasMore = page.hasMore;
        _loading = false;
        _loadingMore = false;
        _error = null;
        _moreError = null;
      });
    } catch (error) {
      if (!mounted ||
          generation != _generation ||
          !identical(repository, widget.repository)) {
        return;
      }
      setState(() {
        _loading = false;
        _loadingMore = false;
        if (reset) {
          _error = error;
        } else {
          _moreError = error;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaGender = ref.watch(exerciseViewerMediaGenderProvider);
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;
    Widget content;
    if (_loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      content = _HistoryFeedback(
        message: 'Could not load workout history. Check your connection.',
        onRetry: () => unawaited(_load(reset: true)),
      );
    } else if (_entries.isEmpty) {
      content = _HistoryFeedback(
        message: 'No completed workouts yet.',
        onRetry: () => unawaited(_load(reset: true)),
        actionLabel: 'Refresh',
      );
    } else {
      content = RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView.separated(
          key: const ValueKey('workout-history-list'),
          padding: const EdgeInsets.all(TioSpacing.lg),
          itemCount: _entries.length + (_hasMore || _moreError != null ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: TioSpacing.md),
          itemBuilder: (context, index) {
            if (index == _entries.length) {
              if (_moreError != null) {
                return Center(
                  child: TextButton(
                    onPressed: () => unawaited(_load(reset: false)),
                    child: const Text('Retry loading more'),
                  ),
                );
              }
              return Center(
                child: _loadingMore
                    ? const CircularProgressIndicator()
                    : TextButton(
                        onPressed: () => unawaited(_load(reset: false)),
                        child: const Text('Load more'),
                      ),
              );
            }
            return WorkoutHistoryCard(
              entry: _entries[index],
              mediaFor: (ref) {
                final exercise = _catalog?.byRef(ref);
                return exercise == null
                    ? null
                    : ExercisesController.thumbnailUrlFor(
                        exercise,
                        gender: mediaGender,
                      );
              },
            );
          },
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: ColoredBox(
        color: colors.background,
        child: DefaultTextStyle.merge(
          style: textTheme.bodyMedium,
          child: content,
        ),
      ),
    );
  }
}

class _HistoryFeedback extends StatelessWidget {
  const _HistoryFeedback({
    required this.message,
    required this.onRetry,
    this.actionLabel = 'Retry',
  });

  final String message;
  final String actionLabel;
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
              TextButton(onPressed: onRetry, child: Text(actionLabel)),
            ],
          ),
        ),
      );
}

/// Compact read-only card. Its saved session ID stays in [entry] for W8 Detail.
class WorkoutHistoryCard extends StatelessWidget {
  const WorkoutHistoryCard({
    required this.entry,
    required this.mediaFor,
    super.key,
  });

  final WorkoutHistoryEntry entry;
  final Uri? Function(ExerciseRef) mediaFor;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatMediumDate(entry.displayAt);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(entry.displayAt),
    );
    final preview = entry.exercises.take(5);
    return TioCard(
      key: ValueKey('history-card-${entry.sessionId.value}'),
      variant: TioCardVariant.normal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$date · $time',
              style:
                  textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
          if (entry.gymName case final gym?) ...[
            const SizedBox(height: TioSpacing.xs),
            Text(gym,
                style:
                    textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
          ],
          const SizedBox(height: TioSpacing.sm),
          Text(entry.title, style: textTheme.titleMedium),
          if (entry.description case final description?) ...[
            const SizedBox(height: TioSpacing.xs),
            Text(description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium
                    ?.copyWith(color: colors.textSecondary)),
          ],
          const SizedBox(height: TioSpacing.md),
          Text('Time',
              style:
                  textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
          Text(_durationLabel(entry.duration), style: textTheme.titleSmall),
          if (entry.exercises.isNotEmpty) ...[
            const SizedBox(height: TioSpacing.md),
            Divider(height: TioSpacing.sm, color: colors.outlineStrong),
            const SizedBox(height: TioSpacing.xs),
            for (final (index, exercise) in preview.indexed) ...[
              if (index > 0) const SizedBox(height: TioSpacing.sm),
              Row(
                children: [
                  TioAvatar(
                    size: TioAvatarSize.small,
                    imageUrl: mediaFor(exercise.ref)?.toString(),
                    fallbackIcon: Icons.fitness_center,
                  ),
                  const SizedBox(width: TioSpacing.sm),
                  Expanded(
                    child: Text(
                      '${exercise.setCount} ${exercise.setCount == 1 ? 'set' : 'sets'} ${exercise.name}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
            if (entry.remainingExerciseCount > 0) ...[
              const SizedBox(height: TioSpacing.sm),
              Center(
                child: Text(
                  '${entry.remainingExerciseCount} more exercises',
                  style: textTheme.bodySmall
                      ?.copyWith(color: colors.textSecondary),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  static String _durationLabel(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}min';
    if (duration.inMinutes > 0) return '${duration.inMinutes}min';
    return '${duration.inSeconds}s';
  }
}
