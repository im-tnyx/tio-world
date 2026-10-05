import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/exercises/exercise_catalog_query.dart';
import '../../../domain/exercises/user_exercise_repository.dart';
import 'custom_exercise_editor_page.dart';
import 'custom_exercises_controller.dart';
import 'custom_exercises_state.dart';
import 'exercise_taxonomy_labels.dart';
import 'exercises_controller.dart';
import 'exercises_providers.dart';
import 'exercises_state.dart';
import 'widgets/exercise_filter_sheet.dart';
import 'widgets/exercise_list_row.dart';

/// Canonical Exercises screen.
///
/// Bundled and user-created Exercises compose here; a user-created row remains
/// a canonical [Exercise] and is distinguished only by presentation metadata.
class ExercisesPage extends ConsumerStatefulWidget {
  const ExercisesPage({
    super.key,
    this.startSearching = false,
    this.userExerciseRepository,
    this.customOnly = false,
  });

  /// Opens with the top-bar search field active and focused.
  final bool startSearching;

  /// Durable user-created Exercise source supplied by app composition.
  ///
  /// Null keeps the catalog fully usable while create/edit capability fails
  /// closed instead of reporting in-memory success.
  final UserExerciseRepository? userExerciseRepository;

  /// Focuses the same canonical screen to user-created rows only.
  final bool customOnly;

  static const loadingLabel = 'Loading exercises';
  static const emptyCatalogMessage = 'No exercises available yet.';
  static const noMatchMessage = 'No exercises match your search or filters.';
  static const customNoMatchMessage =
      'No custom exercises match your search or filters.';
  static const missingCatalogMessage =
      'Exercises aren’t available in this version of the app.';
  static const malformedCatalogMessage =
      'Exercises couldn’t be read in this version of the app.';
  static const failedMessage = 'Could not load exercises.';

  @override
  ConsumerState<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends ConsumerState<ExercisesPage> {
  CustomExercisesController? _customController;

  String get _screenTitle =>
      widget.customOnly ? 'Custom Exercises' : 'Exercises';

  String get _searchHint =>
      widget.customOnly ? 'Search custom exercises' : 'Search exercises';

  @override
  void initState() {
    super.initState();
    _bindCustomController();
  }

  @override
  void didUpdateWidget(covariant ExercisesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(
      oldWidget.userExerciseRepository,
      widget.userExerciseRepository,
    )) {
      _bindCustomController();
    }
  }

  void _bindCustomController() {
    _customController?.removeListener(_onCustomChanged);
    _customController?.dispose();

    final repository = widget.userExerciseRepository;
    if (repository == null) {
      _customController = null;
      return;
    }

    final controller = CustomExercisesController(repository: repository);
    _customController = controller;
    controller.addListener(_onCustomChanged);
    controller.load();
  }

  void _onCustomChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _customController?.removeListener(_onCustomChanged);
    _customController?.dispose();
    super.dispose();
  }

  Future<void> _openCustomEditor([Exercise? exercise]) async {
    final controller = _customController;
    if (controller == null ||
        controller.state.status != CustomExercisesStatus.ready ||
        controller.state.actionInProgress) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CustomExerciseEditorPage(
          controller: controller,
          exercise: exercise,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final catalogController =
        ref.watch(exercisesControllerProvider(widget.startSearching));
    final catalogState = catalogController.state;
    final customState = _customController?.state;
    final customExercises = customState?.status == CustomExercisesStatus.ready
        ? customState!.exercises
        : const <Exercise>[];
    final customQuery = _customQueryFor(
      catalogState.query,
      customOnly: widget.customOnly,
    );
    final filteredCustom = [
      for (final exercise in customExercises)
        if (customQuery.matches(exercise)) exercise,
    ];
    final customItems = [
      for (final exercise in filteredCustom)
        ExerciseListItem(
          exercise: exercise,
          thumbnailUrl: null,
          metadata: _customMetadataFor(exercise),
          isCustom: true,
        ),
    ];
    final hasCustomExercises = customExercises.isNotEmpty;
    final canBrowse = widget.customOnly
        ? hasCustomExercises
        : catalogState.hasActiveExercises || hasCustomExercises;
    final filterState = _withCustomFilterOptions(
      catalogState,
      customExercises,
      customOnly: widget.customOnly,
    );
    final canCreate = customState?.status == CustomExercisesStatus.ready &&
        !(customState?.actionInProgress ?? true);

    return Scaffold(
      key: const ValueKey('exercises-page'),
      backgroundColor: colors.background,
      appBar: TioAppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        leading: BackButton(color: colors.textPrimary),
        title: catalogState.isSearching
            ? TioInput(
                key: const ValueKey('exercises-search'),
                hint: _searchHint,
                value: catalogState.query.text,
                autofocus: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: TioInputTokens.horizontalPadding,
                  vertical: TioSpacing.sm,
                ),
                leading:
                    Icon(Icons.search_rounded, color: colors.textSecondary),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.search,
                onChanged: catalogController.setSearchText,
              )
            : Text(
                _screenTitle,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: TioFontWeight.w800,
                  fontSize: TioFontSize.size20,
                ),
              ),
        actions: catalogState.isSearching
            ? [
                IconButton(
                  key: const ValueKey('exercises-search-close'),
                  tooltip: 'Close search',
                  color: colors.textPrimary,
                  onPressed: catalogController.closeSearch,
                  icon: const Icon(Icons.close_rounded),
                ),
              ]
            : [
                if (widget.userExerciseRepository != null)
                  IconButton(
                    key: const ValueKey('custom-exercise-create'),
                    tooltip: 'Create custom exercise',
                    color: colors.textPrimary,
                    onPressed: canCreate ? () => _openCustomEditor() : null,
                    icon: const Icon(Icons.add_rounded),
                  ),
                IconButton(
                  key: const ValueKey('exercises-search-open'),
                  tooltip: _searchHint,
                  color: colors.textPrimary,
                  onPressed: canBrowse ? catalogController.openSearch : null,
                  icon: const Icon(Icons.search_rounded),
                ),
                IconButton(
                  key: const ValueKey('exercises-filter'),
                  tooltip: _filterSemanticLabel(
                    filterState.activeFilterCount,
                    customOnly: widget.customOnly,
                  ),
                  color: filterState.activeFilterCount > 0
                      ? colors.primary
                      : colors.textPrimary,
                  onPressed: canBrowse
                      ? () => _openFilters(
                            context,
                            catalogController,
                            filterState,
                            customOnly: widget.customOnly,
                          )
                      : null,
                  icon: const Icon(Icons.filter_list),
                ),
              ],
      ),
      body: SafeArea(
        child: _body(
          catalogState: catalogState,
          customState: customState,
          customItems: customItems,
        ),
      ),
    );
  }

  static String _filterSemanticLabel(
    int activeCount, {
    required bool customOnly,
  }) {
    final title = customOnly ? 'Filter custom exercises' : 'Filter exercises';
    return switch (activeCount) {
      0 => title,
      1 => '$title, 1 filter active',
      _ => '$title, $activeCount filters active',
    };
  }

  Future<void> _openFilters(
    BuildContext context,
    ExercisesController controller,
    ExercisesState state, {
    required bool customOnly,
  }) async {
    final selection = await showExerciseFilterSheet(
      context: context,
      state: state,
      title: customOnly ? 'Filter custom exercises' : 'Filter exercises',
    );
    if (selection == null) return;
    controller.applyFilters(
      muscleGroup: customOnly ? null : selection.muscleGroup,
      primaryEquipment: selection.primaryEquipment,
      category: customOnly ? null : selection.category,
    );
  }

  Widget _body({
    required ExercisesState catalogState,
    required CustomExercisesState? customState,
    required List<ExerciseListItem> customItems,
  }) {
    if (widget.customOnly) {
      final controller = _customController;
      if (controller == null) {
        return const _Message(
          key: ValueKey('custom-exercises-unavailable'),
          text: 'Custom Exercises are unavailable right now.',
        );
      }
      return switch (customState!.status) {
        CustomExercisesStatus.loading => const Center(
            key: ValueKey('custom-exercises-loading'),
            child: CircularProgressIndicator(
              semanticsLabel: 'Loading custom exercises',
            ),
          ),
        CustomExercisesStatus.loadFailed => _Failure(
            key: const ValueKey('custom-exercises-load-failure'),
            message: customState.loadError ??
                'Could not load custom exercises. Please try again.',
            onRetry: controller.retryLoad,
          ),
        CustomExercisesStatus.ready => _customOnlyReady(
            customState,
            customItems,
          ),
      };
    }

    final customReady = customState?.status == CustomExercisesStatus.ready;
    final customHasAny = customReady && customState!.exercises.isNotEmpty;
    final catalogItems = catalogState.status == ExercisesStatus.ready
        ? catalogState.items
        : const <ExerciseListItem>[];
    final hasMatchingItems =
        customItems.isNotEmpty || catalogItems.isNotEmpty;
    final anySourceLoading =
        catalogState.status == ExercisesStatus.loading ||
        customState?.status == CustomExercisesStatus.loading;
    final catalogFailureMessage = switch (catalogState.status) {
      ExercisesStatus.missingCatalog => ExercisesPage.missingCatalogMessage,
      ExercisesStatus.malformedCatalog => ExercisesPage.malformedCatalogMessage,
      ExercisesStatus.failed => ExercisesPage.failedMessage,
      _ => null,
    };
    final customFailureMessage =
        customState?.status == CustomExercisesStatus.loadFailed
            ? customState?.loadError ??
                'Could not load custom exercises. Please try again.'
            : null;

    if (!hasMatchingItems) {
      // A unified no-match/empty claim is valid only after every participating
      // source has resolved. A Custom read may still produce the matching row.
      if (anySourceLoading) {
        return const Center(
          key: ValueKey('exercises-loading'),
          child: CircularProgressIndicator(
            semanticsLabel: ExercisesPage.loadingLabel,
          ),
        );
      }

      if (customFailureMessage != null && catalogFailureMessage != null) {
        return _ExerciseList(
          customItems: const [],
          catalogItems: const [],
          onCustomTap: _openCustomEditor,
          customFailure: customFailureMessage,
          onRetryCustom: _customController?.retryLoad,
          catalogMessage: catalogFailureMessage,
        );
      }

      if (customFailureMessage != null) {
        return _Failure(
          key: const ValueKey('custom-exercises-load-failure'),
          message: customFailureMessage,
          onRetry: _customController!.retryLoad,
        );
      }

      if (catalogFailureMessage != null) {
        return _Message(
          key: ValueKey('exercises-${catalogState.status.name}'),
          text: catalogFailureMessage,
        );
      }

      final hasAnyExercise =
          catalogState.hasActiveExercises || customHasAny;
      if (!hasAnyExercise) {
        return const _Message(
          key: ValueKey('exercises-empty'),
          text: ExercisesPage.emptyCatalogMessage,
        );
      }

      return const _Message(
        key: ValueKey('exercises-no-match'),
        text: ExercisesPage.noMatchMessage,
      );
    }

    return _ExerciseList(
      customItems: customItems,
      catalogItems: catalogItems,
      onCustomTap: _openCustomEditor,
      customFailure: customFailureMessage,
      onRetryCustom: _customController?.retryLoad,
      catalogMessage: catalogFailureMessage,
    );
  }

  Widget _customOnlyReady(
    CustomExercisesState customState,
    List<ExerciseListItem> customItems,
  ) {
    if (customState.exercises.isEmpty) {
      return _CustomEmpty(onCreate: () => _openCustomEditor());
    }
    if (customItems.isEmpty) {
      return const _Message(
        key: ValueKey('exercises-no-match'),
        text: ExercisesPage.customNoMatchMessage,
      );
    }
    return _ExerciseList(
      customItems: customItems,
      catalogItems: const [],
      onCustomTap: _openCustomEditor,
      customOnly: true,
    );
  }

  static String? _customMetadataFor(Exercise exercise) {
    final parts = [
      if (exercise.primaryEquipment case final equipment?)
        exerciseTaxonomyLabel(equipment),
      if (exercise.primaryMuscles.isNotEmpty)
        exerciseTaxonomyLabel(exercise.primaryMuscles.first),
    ];
    return parts.isEmpty ? null : parts.join(' • ');
  }

  static ExerciseCatalogQuery _customQueryFor(
    ExerciseCatalogQuery query, {
    required bool customOnly,
  }) =>
      customOnly
          ? ExerciseCatalogQuery(
              text: query.text,
              primaryEquipment: query.primaryEquipment,
            )
          : query;

  static ExercisesState _withCustomFilterOptions(
    ExercisesState state,
    List<Exercise> customExercises, {
    required bool customOnly,
  }) {
    final customEquipment = <String, ExerciseFilterOption>{
      for (final exercise in customExercises)
        if (exercise.primaryEquipment case final value?)
          value: ExerciseFilterOption(
            value: value,
            label: exerciseTaxonomyLabel(value),
          ),
    };
    final equipment = <String, ExerciseFilterOption>{
      if (!customOnly)
        for (final option
            in state.optionsFor(ExerciseFilterDimension.equipment))
          option.value: option,
      ...customEquipment,
    };
    final equipmentOptions = equipment.values.toList()
      ..sort((a, b) {
        final byLabel = a.label.toLowerCase().compareTo(b.label.toLowerCase());
        return byLabel != 0 ? byLabel : a.value.compareTo(b.value);
      });
    final query = _customQueryFor(
      state.query,
      customOnly: customOnly,
    );

    return ExercisesState(
      status: state.status,
      query: query,
      items: state.items,
      hasActiveExercises:
          state.hasActiveExercises || customExercises.isNotEmpty,
      filterOptions: customOnly
          ? {
              ExerciseFilterDimension.equipment:
                  List<ExerciseFilterOption>.unmodifiable(equipmentOptions),
            }
          : {
              ...state.filterOptions,
              ExerciseFilterDimension.equipment:
                  List<ExerciseFilterOption>.unmodifiable(equipmentOptions),
            },
      isSearching: state.isSearching,
    );
  }
}

class _ExerciseList extends StatelessWidget {
  const _ExerciseList({
    required this.customItems,
    required this.catalogItems,
    required this.onCustomTap,
    this.customOnly = false,
    this.customFailure,
    this.onRetryCustom,
    this.catalogMessage,
  });

  final List<ExerciseListItem> customItems;
  final List<ExerciseListItem> catalogItems;
  final ValueChanged<Exercise> onCustomTap;
  final bool customOnly;
  final String? customFailure;
  final VoidCallback? onRetryCustom;
  final String? catalogMessage;

  @override
  Widget build(BuildContext context) {
    final dividerColor =
        context.tioColors.outlineStrong.withAlpha(TioAlpha.alpha20);

    Widget divider() => Divider(
          height: TioStroke.width1,
          thickness: TioStroke.width1,
          indent: TioSpacing.lg,
          endIndent: TioSpacing.lg,
          color: dividerColor,
        );

    final children = <Widget>[
      if (customFailure case final message?)
        _InlineFailure(
          message: message,
          onRetry: onRetryCustom,
        ),
      if (customItems.isNotEmpty) ...[
        if (!customOnly)
          const _SectionHeader(
            key: ValueKey('custom-exercises-section'),
            label: 'Custom Exercises',
          ),
        for (var i = 0; i < customItems.length; i++) ...[
          ExerciseListRow(
            key: ValueKey(
              'exercise-row-${customItems[i].exercise.ref.value}',
            ),
            item: customItems[i],
            onTap: () => onCustomTap(customItems[i].exercise),
          ),
          if (i != customItems.length - 1) divider(),
        ],
      ],
      if (!customOnly && catalogItems.isNotEmpty) ...[
        const _SectionHeader(
          key: ValueKey('all-exercises-section'),
          label: 'All Exercises',
        ),
        for (var i = 0; i < catalogItems.length; i++) ...[
          ExerciseListRow(
            key: ValueKey(
              'exercise-row-${catalogItems[i].exercise.ref.value}',
            ),
            item: catalogItems[i],
          ),
          if (i != catalogItems.length - 1) divider(),
        ],
      ],
      if (catalogMessage case final message?)
        _InlineMessage(text: message),
    ];

    return ListView(
      key: const ValueKey('exercises-list'),
      padding: const EdgeInsets.only(bottom: TioSpacing.lg),
      children: children,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          TioSpacing.lg,
          TioSpacing.lg,
          TioSpacing.lg,
          TioSpacing.sm,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: context.tioColors.textSecondary,
            fontSize: TioFontSize.size14,
            fontWeight: TioFontWeight.w700,
          ),
        ),
      );
}

class _InlineFailure extends StatelessWidget {
  const _InlineFailure({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(TioSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (onRetry != null) ...[
              const SizedBox(height: TioSpacing.sm),
              TioButton.secondary(
                label: 'Try again',
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      );
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(TioSpacing.lg),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.tioColors.textSecondary,
            fontSize: TioFontSize.size14,
          ),
        ),
      );
}

class _CustomEmpty extends StatelessWidget {
  const _CustomEmpty({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
        key: const ValueKey('custom-exercises-empty'),
        child: Padding(
          padding: const EdgeInsets.all(TioSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No custom exercises yet'),
              const SizedBox(height: TioSpacing.lg),
              TioButton.primary(
                key: const ValueKey('custom-exercises-empty-create'),
                label: 'Create Exercise',
                onPressed: onCreate,
              ),
            ],
          ),
        ),
      );
}

class _Failure extends StatelessWidget {
  const _Failure({
    required this.message,
    required this.onRetry,
    super.key,
  });

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
              const SizedBox(height: TioSpacing.lg),
              TioButton.secondary(label: 'Try again', onPressed: onRetry),
            ],
          ),
        ),
      );
}

class _Message extends StatelessWidget {
  const _Message({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TioSpacing.xl),
        child: Semantics(
          liveRegion: true,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.tioColors.textSecondary,
              fontSize: TioFontSize.size14,
            ),
          ),
        ),
      ),
    );
  }
}
