import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_core/core.dart';

import 'exercises_controller.dart';
import 'exercises_providers.dart';
import 'exercises_state.dart';
import 'widgets/exercise_filter_sheet.dart';
import 'widgets/exercise_list_row.dart';

/// Dedicated Exercises screen: search, filter and browse the built-in
/// catalog.
///
/// Renders [ExercisesController] state and forwards user intent to it; it
/// never reads the catalog or its JSON itself.
class ExercisesPage extends ConsumerWidget {
  const ExercisesPage({super.key});

  static const loadingLabel = 'Loading exercises';
  static const emptyCatalogMessage = 'No exercises available yet.';
  static const noMatchMessage = 'No exercises match your search or filters.';
  static const missingCatalogMessage =
      'Exercises aren’t available in this version of the app.';
  static const malformedCatalogMessage =
      'Exercises couldn’t be read in this version of the app.';
  static const failedMessage = 'Could not load exercises.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.tioColors;
    final controller = ref.watch(exercisesControllerProvider);
    final state = controller.state;
    final canBrowse =
        state.status == ExercisesStatus.ready && state.hasActiveExercises;

    return Scaffold(
      key: const ValueKey('exercises-page'),
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          'Exercises',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: TioFontWeight.w800,
            fontSize: TioFontSize.size20,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TioSpacing.lg,
                TioSpacing.sm,
                TioSpacing.lg,
                TioSpacing.none,
              ),
              child: TioInput(
                key: const ValueKey('exercises-search'),
                hint: 'Search exercises',
                value: state.query.text,
                enabled: canBrowse,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.search,
                onChanged: controller.setSearchText,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TioSpacing.lg,
                TioSpacing.sm,
                TioSpacing.lg,
                TioSpacing.sm,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: TioButton.secondary(
                  key: const ValueKey('exercises-filter'),
                  label: 'Filter exercises',
                  semanticLabel: _filterSemanticLabel(state.activeFilterCount),
                  enabled: canBrowse,
                  onPressed: () => _openFilters(context, controller),
                ),
              ),
            ),
            Expanded(child: _body(state)),
          ],
        ),
      ),
    );
  }

  static String _filterSemanticLabel(int activeCount) => switch (activeCount) {
        0 => 'Filter exercises',
        1 => 'Filter exercises, 1 filter active',
        _ => 'Filter exercises, $activeCount filters active',
      };

  Future<void> _openFilters(
    BuildContext context,
    ExercisesController controller,
  ) async {
    final selection = await showExerciseFilterSheet(
      context: context,
      state: controller.state,
    );
    if (selection == null) return;
    controller.applyFilters(
      muscleGroup: selection.muscleGroup,
      primaryEquipment: selection.primaryEquipment,
      category: selection.category,
    );
  }

  Widget _body(ExercisesState state) {
    switch (state.status) {
      case ExercisesStatus.loading:
        return const Center(
          key: ValueKey('exercises-loading'),
          child: CircularProgressIndicator(semanticsLabel: loadingLabel),
        );
      case ExercisesStatus.missingCatalog:
        return const _Message(
          key: ValueKey('exercises-missing-catalog'),
          text: missingCatalogMessage,
        );
      case ExercisesStatus.malformedCatalog:
        return const _Message(
          key: ValueKey('exercises-malformed-catalog'),
          text: malformedCatalogMessage,
        );
      case ExercisesStatus.failed:
        return const _Message(
          key: ValueKey('exercises-failed'),
          text: failedMessage,
        );
      case ExercisesStatus.ready:
        if (state.isEmptyCatalog) {
          return const _Message(
            key: ValueKey('exercises-empty'),
            text: emptyCatalogMessage,
          );
        }
        if (state.isNoMatch) {
          return const _Message(
            key: ValueKey('exercises-no-match'),
            text: noMatchMessage,
          );
        }
        return _ExerciseList(items: state.items);
    }
  }
}

class _ExerciseList extends StatelessWidget {
  const _ExerciseList({required this.items});

  final List<ExerciseListItem> items;

  @override
  Widget build(BuildContext context) {
    final dividerColor =
        context.tioColors.outlineStrong.withAlpha(TioAlpha.alpha20);

    return ListView.separated(
      key: const ValueKey('exercises-list'),
      padding: const EdgeInsets.only(bottom: TioSpacing.lg),
      itemCount: items.length,
      itemBuilder: (context, index) => ExerciseListRow(
        key: ValueKey('exercise-row-${items[index].exercise.ref.value}'),
        item: items[index],
      ),
      separatorBuilder: (context, index) => Divider(
        height: TioStroke.width1,
        thickness: TioStroke.width1,
        indent: TioSpacing.lg,
        endIndent: TioSpacing.lg,
        color: dividerColor,
      ),
    );
  }
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
