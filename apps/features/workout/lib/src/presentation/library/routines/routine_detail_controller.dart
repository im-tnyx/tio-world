import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/exercises/exercise_catalog_repository.dart';
import '../../../domain/exercises/user_exercise_repository.dart';
import '../../../domain/repositories/routine_composition_repository.dart';
import '../../../domain/repositories/routine_repository.dart';

enum RoutineDetailStatus { loading, ready, notFound, failed }

/// Read-only projection of one persisted entry. Repeated ExerciseRefs remain
/// separate entries and keep their persisted order and child identities.
final class RoutineDetailEntry {
  const RoutineDetailEntry({required this.entry, this.exercise});

  final RoutineCompositionEntry entry;
  final Exercise? exercise;
}

final class RoutineDetailState {
  const RoutineDetailState.loading()
      : status = RoutineDetailStatus.loading,
        routine = null,
        entries = const [],
        revision = null;

  const RoutineDetailState.notFound()
      : status = RoutineDetailStatus.notFound,
        routine = null,
        entries = const [],
        revision = null;

  const RoutineDetailState.failed()
      : status = RoutineDetailStatus.failed,
        routine = null,
        entries = const [],
        revision = null;

  RoutineDetailState.ready({
    required this.routine,
    required List<RoutineDetailEntry> entries,
    required this.revision,
  })  : status = RoutineDetailStatus.ready,
        entries = List.unmodifiable(entries);

  final RoutineDetailStatus status;
  final Routine? routine;
  final List<RoutineDetailEntry> entries;
  final int? revision;

  int get exerciseCount => entries.length;
  int get setCount =>
      entries.fold(0, (total, item) => total + item.entry.sets.length);
}

/// Verifies the selected Program→Routine relationship from current owner
/// metadata before resolving its composition; no client-side owner bypass.
final class RoutineDetailController extends ChangeNotifier {
  RoutineDetailController({
    required this.program,
    required this.routine,
    required this.routines,
    required this.compositions,
    required this.catalog,
    this.userExercises,
  });

  final Program program;
  final Routine routine;
  final RoutineRepository routines;
  final RoutineCompositionRepository compositions;
  final ExerciseCatalogRepository catalog;
  final UserExerciseRepository? userExercises;

  RoutineDetailState _state = const RoutineDetailState.loading();
  RoutineDetailState get state => _state;
  var _version = 0;
  var _disposed = false;

  Future<void> load() async {
    final version = ++_version;
    _emit(const RoutineDetailState.loading());
    if (routine.programId != program.id) {
      _emit(const RoutineDetailState.notFound());
      return;
    }
    try {
      final ownerRows = await routines.list(program.id);
      if (ownerRows.any((r) => r.programId != program.id) ||
          ownerRows.map((r) => r.id).toSet().length != ownerRows.length) {
        throw const FormatException('Invalid Routine owner listing.');
      }
      if (_disposed || version != _version) return;
      Routine? owned;
      for (final row in ownerRows) {
        if (row.id == routine.id) {
          owned = row;
          break;
        }
      }
      if (owned == null) {
        _emit(const RoutineDetailState.notFound());
        return;
      }

      final snapshot = await compositions.read(owned.id);
      if (_disposed || version != _version) return;
      if (snapshot == null) {
        _emit(const RoutineDetailState.notFound());
        return;
      }
      if (snapshot.routineId != owned.id) {
        throw const FormatException('Composition identity mismatch.');
      }

      // A purely custom or empty Routine must remain readable even when the
      // optional bundled catalog cannot be loaded.
      final needsCatalog = snapshot.entries.any(
        (entry) => entry.exercise is CatalogExerciseRef,
      );
      final builtIns = needsCatalog ? await catalog.load() : null;
      if (_disposed || version != _version) return;
      final needsUserExercises = snapshot.entries.any(
        (entry) => entry.exercise is UserCreatedExerciseRef,
      );
      final byUserId = <ExerciseRef, Exercise>{};
      if (needsUserExercises && userExercises != null) {
        final users = await userExercises!.list(includeArchived: true);
        for (final exercise in users) {
          if (exercise.ref is! UserCreatedExerciseRef ||
              byUserId.containsKey(exercise.ref)) {
            throw const FormatException('Invalid owner Exercise listing.');
          }
          byUserId[exercise.ref] = exercise;
        }
      }
      if (_disposed || version != _version) return;
      _emit(RoutineDetailState.ready(
        routine: owned,
        revision: snapshot.revision,
        entries: [
          for (final entry in snapshot.entries)
            RoutineDetailEntry(
              entry: entry,
              exercise: entry.exercise is CatalogExerciseRef
                  ? builtIns?.byRef(entry.exercise)
                  : byUserId[entry.exercise],
            ),
        ],
      ));
    } catch (_) {
      if (_disposed || version != _version) return;
      // Never show stale owner data, partial reads or private server messages.
      _emit(const RoutineDetailState.failed());
    }
  }

  void _emit(RoutineDetailState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _version++;
    super.dispose();
  }
}
