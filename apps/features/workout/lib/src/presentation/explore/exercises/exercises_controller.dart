import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';

import '../../../data/exercises/exercise_catalog_source_exceptions.dart';
import '../../../domain/exercises/exercise_catalog.dart';
import '../../../domain/exercises/exercise_catalog_query.dart';
import '../../../domain/exercises/exercise_catalog_repository.dart';
import '../../../domain/exercises/invalid_exercise_catalog_exception.dart';
import 'exercise_taxonomy_labels.dart';
import 'exercises_state.dart';

/// Owns loading, search, filtering and media selection for the dedicated
/// Exercises screen.
///
/// Matching is delegated to [ExerciseCatalogQuery] and image choice to
/// `ExerciseMedia.urlFor`; this controller only composes their results into
/// [ExercisesState].
class ExercisesController extends ChangeNotifier {
  /// With [startSearching], the top-bar search field is open from the first
  /// frame, as when Library's search action opens this screen.
  ExercisesController({
    required ExerciseCatalogRepository repository,
    ExerciseMediaGender? mediaGender,
    bool startSearching = false,
  })  : _repository = repository,
        _mediaGender = mediaGender,
        _state = ExercisesState(
          status: ExercisesStatus.loading,
          isSearching: startSearching,
        );

  final ExerciseCatalogRepository _repository;
  ExerciseMediaGender? _mediaGender;
  ExerciseCatalog? _catalog;
  ExercisesState _state;
  bool _disposed = false;

  ExercisesState get state => _state;

  ExerciseMediaGender? get mediaGender => _mediaGender;

  Future<void> load() async {
    _catalog = null;
    _emit(ExercisesState(
      status: ExercisesStatus.loading,
      query: _state.query,
      isSearching: _state.isSearching,
    ));

    final ExerciseCatalog catalog;
    try {
      catalog = await _repository.load();
    } on MissingExerciseCatalogAssetException {
      return _emitFailure(ExercisesStatus.missingCatalog);
    } on InvalidExerciseCatalogDocumentException {
      return _emitFailure(ExercisesStatus.malformedCatalog);
    } on UnsupportedExerciseCatalogSchemaVersionException {
      return _emitFailure(ExercisesStatus.malformedCatalog);
    } on InvalidExerciseCatalogException {
      return _emitFailure(ExercisesStatus.malformedCatalog);
    } catch (_) {
      return _emitFailure(ExercisesStatus.failed);
    }

    _catalog = catalog;
    _emitReady();
  }

  void setSearchText(String text) {
    final query = _state.query;
    if (query.text == text) return;
    _setQuery(ExerciseCatalogQuery(
      text: text,
      muscleGroup: query.muscleGroup,
      primaryEquipment: query.primaryEquipment,
      category: query.category,
    ));
  }

  /// Shows the top-bar search field.
  void openSearch() {
    if (_state.isSearching) return;
    _emit(_copyWith(isSearching: true));
  }

  /// Hides the search field and clears its text.
  void closeSearch() {
    if (!_state.isSearching) return;
    final query = _state.query;
    final cleared = ExerciseCatalogQuery(
      muscleGroup: query.muscleGroup,
      primaryEquipment: query.primaryEquipment,
      category: query.category,
    );
    if (_catalog == null) {
      _emit(ExercisesState(status: _state.status, query: cleared));
      return;
    }
    _emitReady(query: cleared, isSearching: false);
  }

  /// Replaces every filter at once, as the filter sheet's Show results does.
  void applyFilters({
    String? muscleGroup,
    String? primaryEquipment,
    String? category,
  }) {
    _setQuery(ExerciseCatalogQuery(
      text: _state.query.text,
      muscleGroup: muscleGroup,
      primaryEquipment: primaryEquipment,
      category: category,
    ));
  }

  /// Updates the viewer's media gender; rows re-resolve their thumbnails.
  void setMediaGender(ExerciseMediaGender? gender) {
    if (_mediaGender == gender) return;
    _mediaGender = gender;
    if (_catalog != null) _emitReady();
  }

  /// Image for [exercise]: the `image` kind, then the `thumbnail` kind, each
  /// through the canonical per-gender selection rule.
  static Uri? thumbnailUrlFor(
    Exercise exercise, {
    ExerciseMediaGender? gender,
  }) {
    final media = exercise.media;
    if (media == null) return null;
    return media.urlFor(ExerciseMediaKind.image, gender: gender) ??
        media.urlFor(ExerciseMediaKind.thumbnail, gender: gender);
  }

  /// `Primary equipment • Muscle group`, or whichever part exists.
  static String? metadataFor(Exercise exercise) {
    final parts = [
      if (exercise.primaryEquipment case final equipment?)
        exerciseTaxonomyLabel(equipment),
      if (exercise.muscleGroup case final muscleGroup?)
        exerciseTaxonomyLabel(muscleGroup),
    ];
    return parts.isEmpty ? null : parts.join(' • ');
  }

  void _setQuery(ExerciseCatalogQuery query) {
    if (query == _state.query) return;
    if (_catalog == null) {
      _emit(ExercisesState(
        status: _state.status,
        query: query,
        isSearching: _state.isSearching,
      ));
      return;
    }
    _emitReady(query: query);
  }

  ExercisesState _copyWith({required bool isSearching}) => ExercisesState(
        status: _state.status,
        query: _state.query,
        items: _state.items,
        hasActiveExercises: _state.hasActiveExercises,
        filterOptions: _state.filterOptions,
        isSearching: isSearching,
      );

  void _emitReady({ExerciseCatalogQuery? query, bool? isSearching}) {
    final catalog = _catalog!;
    final effectiveQuery = query ?? _state.query;
    final active = const ExerciseCatalogQuery().apply(catalog);

    _emit(ExercisesState(
      status: ExercisesStatus.ready,
      query: effectiveQuery,
      isSearching: isSearching ?? _state.isSearching,
      hasActiveExercises: active.isNotEmpty,
      filterOptions: {
        ExerciseFilterDimension.muscle:
            _options(active.map((exercise) => exercise.muscleGroup)),
        ExerciseFilterDimension.equipment:
            _options(active.map((exercise) => exercise.primaryEquipment)),
        ExerciseFilterDimension.category:
            _options(active.map((exercise) => exercise.category)),
      },
      items: List<ExerciseListItem>.unmodifiable([
        for (final exercise in effectiveQuery.apply(catalog))
          ExerciseListItem(
            exercise: exercise,
            thumbnailUrl: thumbnailUrlFor(exercise, gender: _mediaGender),
            metadata: metadataFor(exercise),
          ),
      ]),
    ));
  }

  static List<ExerciseFilterOption> _options(Iterable<String?> tokens) {
    final options = [
      for (final token in tokens.nonNulls.toSet())
        ExerciseFilterOption(value: token, label: exerciseTaxonomyLabel(token)),
    ]..sort((a, b) {
        final byLabel = a.label.toLowerCase().compareTo(b.label.toLowerCase());
        return byLabel != 0 ? byLabel : a.value.compareTo(b.value);
      });
    return List<ExerciseFilterOption>.unmodifiable(options);
  }

  void _emitFailure(ExercisesStatus status) => _emit(
      ExercisesState(status: status, query: const ExerciseCatalogQuery()));

  void _emit(ExercisesState state) {
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
