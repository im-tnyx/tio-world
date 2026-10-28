import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/exercises/exercise_catalog_repository.dart';
import '../../../domain/exercises/user_exercise_repository.dart';
import 'exercise_detail_state.dart';

typedef ExerciseDetailSessionValue = String? Function();

/// Resolves one canonical Exercise through the existing Workout repositories.
///
/// A Custom Exercise is accepted only when the current owner/session still
/// matches the identity captured when the detail route was opened and the
/// authoritative repository read still reports it as active.
final class ExerciseDetailController extends ChangeNotifier {
  ExerciseDetailController({
    required this.exerciseRef,
    required this.catalogRepository,
    this.userExerciseRepository,
    this.expectedOwnerId,
    this.expectedLoginCycleId,
    this.currentUserId,
    this.currentLoginCycleId,
  });

  final ExerciseRef exerciseRef;
  final ExerciseCatalogRepository catalogRepository;
  final UserExerciseRepository? userExerciseRepository;
  final String? expectedOwnerId;
  final String? expectedLoginCycleId;
  final ExerciseDetailSessionValue? currentUserId;
  final ExerciseDetailSessionValue? currentLoginCycleId;

  ExerciseDetailState _state = const ExerciseDetailState.loading();
  var _disposed = false;
  var _loadVersion = 0;

  ExerciseDetailState get state => _state;

  bool get isCustom => exerciseRef is UserCreatedExerciseRef;

  bool get canEdit =>
      _state.status == ExerciseDetailStatus.ready &&
      _state.exercise?.ref is UserCreatedExerciseRef &&
      _sessionMatchesExpected();

  Future<void> load() async {
    final version = ++_loadVersion;
    _publish(const ExerciseDetailState.loading());

    try {
      final exercise = isCustom ? await _loadCustom() : await _loadCatalog();
      if (_disposed || version != _loadVersion) return;
      if (exercise == null || exercise.status != ExerciseStatus.active) {
        _publish(const ExerciseDetailState.unavailable());
        return;
      }
      _publish(ExerciseDetailState.ready(exercise));
    } catch (_) {
      if (_disposed || version != _loadVersion) return;
      _publish(
        const ExerciseDetailState.failed(
          'Exercise details are unavailable right now.',
        ),
      );
    }
  }

  /// Rechecks the active owner-scoped Custom row immediately before editing.
  Future<bool> revalidateCustom() async {
    try {
      if (!isCustom || !_sessionMatchesExpected()) {
        _publish(const ExerciseDetailState.unavailable());
        return false;
      }
      final exercise = await _loadCustom();
      if (_disposed) return false;
      if (exercise == null || exercise.status != ExerciseStatus.active) {
        _publish(const ExerciseDetailState.unavailable());
        return false;
      }
      _publish(ExerciseDetailState.ready(exercise));
      return true;
    } catch (_) {
      if (!_disposed) {
        _publish(
          const ExerciseDetailState.failed(
            'Exercise details are unavailable right now.',
          ),
        );
      }
      return false;
    }
  }

  Future<Exercise?> _loadCatalog() async {
    final catalog = await catalogRepository.load();
    return catalog.byRef(exerciseRef);
  }

  Future<Exercise?> _loadCustom() async {
    if (!_sessionMatchesExpected()) return null;
    final repository = userExerciseRepository;
    if (repository == null) return null;
    final exercises = await repository.list(includeArchived: true);
    for (final exercise in exercises) {
      if (exercise.ref == exerciseRef) return exercise;
    }
    return null;
  }

  bool _sessionMatchesExpected() {
    if (!isCustom) return true;
    final expectedOwner = expectedOwnerId?.trim();
    final expectedCycle = expectedLoginCycleId?.trim();
    final owner = currentUserId?.call()?.trim();
    final cycle = currentLoginCycleId?.call()?.trim();
    if (expectedOwner != null && expectedOwner.isNotEmpty) {
      if (owner == null || owner != expectedOwner) return false;
    }
    if (expectedCycle != null && expectedCycle.isNotEmpty) {
      if (cycle == null || cycle != expectedCycle) return false;
    }
    return owner == null || owner.isNotEmpty;
  }

  void _publish(ExerciseDetailState state) {
    if (_disposed) return;
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
