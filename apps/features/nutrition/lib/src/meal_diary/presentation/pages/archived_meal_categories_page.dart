import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/models/meal_category.dart';
import '../../../domain/repositories/meal_categories_repository.dart';
import '../controllers/meal_categories_controller.dart';
import '../widgets/meal_category_glyph.dart';

/// Archived meal categories, reached from the Meal Categories top bar.
///
/// Archived identities are retained rather than deleted, so this is where a
/// reader finds them again and restores one. Restoring reuses the same
/// `MealCategory.id`, which is what keeps historical meal entries resolvable.
class ArchivedMealCategoriesPage extends StatefulWidget {
  const ArchivedMealCategoriesPage({required this.repository, super.key});

  final MealCategoriesRepository repository;

  @override
  State<ArchivedMealCategoriesPage> createState() =>
      _ArchivedMealCategoriesPageState();
}

class _ArchivedMealCategoriesPageState
    extends State<ArchivedMealCategoriesPage> {
  late final MealCategoriesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MealCategoriesController(repository: widget.repository);
    _controller.addListener(_onChanged);
    _controller.load();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _reactivate(String id) async {
    final succeeded = await _controller.reactivate(id);
    if (!mounted || succeeded) return;
    final message = _controller.state.actionError;
    if (message == null) return;
    ScaffoldMessenger.maybeOf(context)
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          key: const ValueKey('archived-categories-error'),
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final state = _controller.state;

    return Scaffold(
      key: const ValueKey('archived-meal-categories-page'),
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          'Archived Meal Categories',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: TioFontWeight.w800,
            fontSize: TioFontSize.size20,
          ),
        ),
      ),
      body: SafeArea(child: _body(state)),
    );
  }

  Widget _body(MealCategoriesState state) {
    switch (state.status) {
      case MealCategoriesStatus.loading:
        return const Center(
          key: ValueKey('archived-categories-loading'),
          child: CircularProgressIndicator(),
        );
      case MealCategoriesStatus.loadFailed:
        return _Message(
          key: const ValueKey('archived-categories-load-failure'),
          text: state.loadError ?? 'Could not load meal categories.',
          action: TioButton.secondary(
            key: const ValueKey('archived-categories-retry'),
            label: 'Try again',
            onPressed: _controller.retryLoad,
          ),
        );
      case MealCategoriesStatus.ready:
        final archived = state.archivedItems;
        if (archived.isEmpty) {
          return const _Message(
            key: ValueKey('archived-categories-empty'),
            text: 'Nothing archived yet. Swipe a category left on the Meal '
                'Categories screen to archive it.',
          );
        }
        return _list(state, archived);
    }
  }

  Widget _list(MealCategoriesState state, List<MealCategory> archived) {
    final colors = context.tioColors;

    return ListView(
      key: const ValueKey('archived-categories-list'),
      padding: const EdgeInsets.symmetric(
        horizontal: TioSpacing.lg,
        vertical: TioSpacing.md,
      ),
      children: [
        TioGroupCard(
          children: [
            for (var index = 0; index < archived.length; index++) ...[
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TioSpacing.lg,
                    vertical: TioSpacing.sm,
                  ),
                  // Glyph, name, action — the same shape as the active list's
                  // rows, so the two screens read alike. Every row carries a
                  // glyph here: nothing on this screen is draggable, so the
                  // column has nothing else to hold, and one row showing an
                  // icon while its neighbour shows blank space reads as a bug.
                  // The name flexes and ellipsises so a long one shortens
                  // rather than pushing the action off the row.
                  child: Row(
                    children: [
                      SizedBox(
                        width: MealCategoryGlyph.columnWidth,
                        child: MealCategoryGlyph(item: archived[index]),
                      ),
                      const SizedBox(width: TioSpacing.md),
                      Expanded(
                        child: Text(
                          archived[index].displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontWeight: TioFontWeight.w700,
                            fontSize: TioFontSize.size15,
                          ),
                        ),
                      ),
                      const SizedBox(width: TioSpacing.md),
                      TioButton.ghost(
                        key: ValueKey(
                          'archived-category-reactivate-'
                          '${archived[index].id}',
                        ),
                        label: 'Restore',
                        onPressed: state.saving || state.isAtActiveCap
                            ? null
                            : () => _reactivate(archived[index].id),
                      ),
                    ],
                  ),
                ),
              ),
              if (index != archived.length - 1)
                _InsetDivider(
                  // Per item: sibling keys must be unique, and a shared one
                  // breaks as soon as a third archived category exists.
                  dividerKey: ValueKey(
                    'archived-category-divider-${archived[index].id}',
                  ),
                ),
            ],
          ],
        ),
        if (state.isAtActiveCap)
          Padding(
            padding: const EdgeInsets.only(
              top: TioSpacing.sm,
              left: TioSpacing.sm,
            ),
            child: Text(
              MealCategoriesController.activeCapReason,
              key: const ValueKey('archived-categories-cap-reason'),
              style: TextStyle(
                color: colors.textMuted,
                fontSize: TioFontSize.size12,
              ),
            ),
          ),
      ],
    );
  }
}

/// A rule that starts at the row's content rather than the card edge.
class _InsetDivider extends StatelessWidget {
  const _InsetDivider({required this.dividerKey});

  final Key dividerKey;

  @override
  Widget build(BuildContext context) {
    return Divider(
      key: dividerKey,
      height: TioStroke.width1,
      thickness: TioStroke.width1,
      // Starts where the names do, past the glyph column, so the rule
      // separates the names instead of cutting through the icons.
      indent: TioSpacing.lg + MealCategoryGlyph.columnWidth + TioSpacing.md,
      // Flush at the end, matching the active list — these are sibling
      // screens and a different rule treatment on each would read as a bug.
      endIndent: TioSpacing.none,
      color: context.tioColors.outlineStrong.withAlpha(TioAlpha.alpha20),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.action, super.key});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TioSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: TioFontSize.size14,
              ),
            ),
            if (action case final widget?) ...[
              const SizedBox(height: TioSpacing.lg),
              widget,
            ],
          ],
        ),
      ),
    );
  }
}
