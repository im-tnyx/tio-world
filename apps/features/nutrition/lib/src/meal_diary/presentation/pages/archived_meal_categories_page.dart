import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/repositories/meal_categories_repository.dart';
import '../controllers/meal_categories_controller.dart';

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

  Widget _list(MealCategoriesState state, List<dynamic> archived) {
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
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: TioSpacing.md,
                    children: [
                      Text(
                        archived[index].displayName as String,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontWeight: TioFontWeight.w700,
                          fontSize: TioFontSize.size15,
                        ),
                      ),
                      TioButton.ghost(
                        key: ValueKey(
                          'archived-category-reactivate-'
                          '${archived[index].id}',
                        ),
                        label: 'Restore',
                        onPressed: state.saving || state.isAtActiveCap
                            ? null
                            : () => _reactivate(archived[index].id as String),
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
      indent: TioSpacing.lg,
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
