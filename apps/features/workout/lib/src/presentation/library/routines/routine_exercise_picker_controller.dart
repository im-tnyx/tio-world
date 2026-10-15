import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/exercises/exercise_catalog.dart';
import '../../../domain/models/routine_composition_limits.dart';
import '../../../domain/exercises/exercise_catalog_query.dart';
import '../../../domain/exercises/exercise_catalog_repository.dart';
import '../../../domain/exercises/user_exercise_repository.dart';
import '../exercises/exercises_controller.dart';
import '../exercises/exercises_state.dart';

enum RoutineExercisePickerStatus { loading, ready, failed }

/// Search results are projections of the canonical Exercise sources, not
/// persisted Routine entries or a second Exercise collection.
final class RoutineExercisePickerState {
  RoutineExercisePickerState({
    required this.status,
    required List<ExerciseListItem> items,
    required this.query,
    required this.hasActiveExercises,
  }) : items = List.unmodifiable(items);

  final RoutineExercisePickerStatus status;
  final List<ExerciseListItem> items;
  final String query;
  final bool hasActiveExercises;
}

/// Read-only, owner-scoped Exercise selection for an unsaved Routine draft.
///
/// The app must supply the current owner's RLS-scoped UserExerciseRepository.
/// When that capability is unavailable the picker can only return bundled
/// catalog refs. Neither source is editable through this picker.
final class RoutineExercisePickerController extends ChangeNotifier {
  RoutineExercisePickerController({
    required ExerciseCatalogRepository catalogRepository,
    UserExerciseRepository? userExerciseRepository,
  })  : _catalogRepository = catalogRepository,
        _userExerciseRepository = userExerciseRepository;

  final ExerciseCatalogRepository _catalogRepository;
  final UserExerciseRepository? _userExerciseRepository;
  ExerciseCatalog? _catalog;
  List<Exercise> _custom = const [];
  int _loadVersion = 0;
  bool _disposed = false;
  String _query = '';

  RoutineExercisePickerState _state = RoutineExercisePickerState(
    status: RoutineExercisePickerStatus.loading,
    items: const [],
    query: '',
    hasActiveExercises: false,
  );

  RoutineExercisePickerState get state => _state;

  /// Do not show partial results if either requested source fails.
  /// A replaced/disposed owner session cannot publish late async results.
  Future<void> load() async {
    if (_disposed) return;
    final version = ++_loadVersion;
    _catalog = null;
    _custom = const [];
    _publish(RoutineExercisePickerState(
      status: RoutineExercisePickerStatus.loading,
      items: const [],
      query: _query,
      hasActiveExercises: false,
    ));
    try {
      final catalog = await _catalogRepository.load();
      if (_disposed || version != _loadVersion) return;

      final List<Exercise> custom;
      if (_userExerciseRepository == null) {
        custom = const [];
      } else {
        custom = await _userExerciseRepository.list();
      }
      if (_disposed || version != _loadVersion) return;

      final ids = <ExerciseRef>{};
      for (final exercise in custom) {
        if (exercise.ref is! UserCreatedExerciseRef ||
            !ids.add(exercise.ref)) {
          throw const FormatException('Invalid owner Exercise collection.');
        }
      }

      _catalog = catalog;
      _custom = List.unmodifiable(custom);
      _publishReady();
    } catch (_) {
      if (_disposed || version != _loadVersion) return;
      _catalog = null;
      _custom = const [];
      _publish(RoutineExercisePickerState(
        status: RoutineExercisePickerStatus.failed,
        items: const [],
        query: _query,
        hasActiveExercises: false,
      ));
    }
  }

  void search(String value) {
    if (_disposed || _query == value) return;
    _query = value;
    if (_catalog == null) return;
    _publishReady();
  }

  /// Accept only an active, currently visible result from a loaded source.
  /// No selection writes to Supabase or to the owning Routine draft.
  Exercise? select(ExerciseRef ref) {
    if (_disposed || _state.status != RoutineExercisePickerStatus.ready) {
      return null;
    }
    for (final item in _state.items) {
      if (item.exercise.ref == ref &&
          item.exercise.status == ExerciseStatus.active &&
          RoutineCompositionLimits.supportsExerciseType(
            item.exercise.exerciseType)) {
        return item.exercise;
      }
    }
    return null;
  }

  void _publishReady() {
    final catalog = _catalog;
    if (catalog == null) return;
    final filter = ExerciseCatalogQuery(text: _query);
    final catalogResults = filter.apply(catalog);
    final customResults = [
      for (final exercise in _custom)
        if (filter.matches(exercise)) exercise,
    ];
    _publish(RoutineExercisePickerState(
      status: RoutineExercisePickerStatus.ready,
      query: _query,
      hasActiveExercises:
          const ExerciseCatalogQuery().apply(catalog).isNotEmpty ||
              _custom.any((exercise) =>
                  exercise.status == ExerciseStatus.active),
      items: [
        for (final exercise in customResults)
          ExerciseListItem(
            exercise: exercise,
            thumbnailUrl: null,
            metadata: ExercisesController.metadataFor(exercise),
            isCustom: true,
          ),
        for (final exercise in catalogResults)
          ExerciseListItem(
            exercise: exercise,
            thumbnailUrl: null,
            metadata: ExercisesController.metadataFor(exercise),
          ),
      ],
    ));
  }

  void _publish(RoutineExercisePickerState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _loadVersion++;
    _catalog = null;
    _custom = const [];
    super.dispose();
  }
}
