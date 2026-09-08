import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// One choosable meal category, reduced to what a screen may show.
///
/// An id and a label, and deliberately nothing else. The domain's
/// `MealCategory` also carries `defaultKey`, `active` and `order`, none of
/// which a picker has any business rendering — and the surest way for an
/// internal identity to reach the screen is for it to be in the object the
/// screen is handed.
///
/// [id] is the selection's identity and survives renaming; [label] is what the
/// reader sees and does not.
@immutable
final class MealCategoryOption {
  const MealCategoryOption({required this.id, required this.label});

  final String id;
  final String label;

  @override
  bool operator ==(Object other) =>
      other is MealCategoryOption && other.id == id && other.label == label;

  @override
  int get hashCode => Object.hash(id, label);
}

/// What the selector should show when it opens.
enum MealCategorySelectorStatus { ready, failed }

/// Asks which meal category this log belongs to.
///
/// Returns the chosen category's **id**, or null if the reader dismissed the
/// sheet without choosing. Never returns a label: the caller stores identity,
/// and the label is resolved for display from the source that owns it.
///
/// Built from `showTioEditorSheet` and `TioSelectableCard` — the sheet and the
/// option component the rest of the app already uses — rather than a picker of
/// its own. `TioSelectableCard` brings the selected appearance, the disabled
/// state and the selection semantics with it.
Future<String?> showMealCategorySelectorSheet({
  required BuildContext context,
  required List<MealCategoryOption> options,
  required String? selectedId,
  MealCategorySelectorStatus status = MealCategorySelectorStatus.ready,
  String? failureMessage,
  Future<void> Function()? onRetry,
}) {
  return showTioEditorSheet<String>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    builder: (sheetContext) => _MealCategorySelector(
      options: options,
      selectedId: selectedId,
      status: status,
      failureMessage: failureMessage,
      onRetry: onRetry,
    ),
  );
}

class _MealCategorySelector extends StatefulWidget {
  const _MealCategorySelector({
    required this.options,
    required this.selectedId,
    required this.status,
    required this.failureMessage,
    required this.onRetry,
  });

  final List<MealCategoryOption> options;
  final String? selectedId;
  final MealCategorySelectorStatus status;
  final String? failureMessage;
  final Future<void> Function()? onRetry;

  @override
  State<_MealCategorySelector> createState() => _MealCategorySelectorState();
}

class _MealCategorySelectorState extends State<_MealCategorySelector> {
  bool _retrying = false;

  Future<void> _retry() async {
    final retry = widget.onRetry;
    if (retry == null || _retrying) return;
    setState(() => _retrying = true);
    await retry();
    if (!mounted) return;
    // The caller reloads and rebuilds; if it succeeded this sheet is no longer
    // the right surface, so it closes and the reader taps again on a control
    // that now has options behind it. Closing beats redrawing a sheet whose
    // whole content changed underneath the reader.
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    if (widget.status == MealCategorySelectorStatus.failed) {
      return TioEditorSheet(
        title: 'Meal type',
        content: Column(
          key: const ValueKey('meal-category-selector-failure'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              // Never a fallback list. Showing the canonical four here would
              // tell the reader their own categories are these, which is a
              // claim this screen cannot make after a failed read.
              widget.failureMessage ?? 'Could not load your meal categories.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: TioFontSize.size14,
                height: TioLineHeight.height145,
              ),
            ),
          ],
        ),
        actions: TioButton.secondary(
          key: const ValueKey('meal-category-selector-retry'),
          label: 'Try again',
          loading: _retrying,
          onPressed: widget.onRetry == null ? null : _retry,
        ),
      );
    }

    return TioEditorSheet(
      title: 'Meal type',
      content: Column(
        key: const ValueKey('meal-category-selector-options'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final option in widget.options) ...[
            TioSelectableCard(
              key: ValueKey('meal-category-option-${option.id}'),
              selected: option.id == widget.selectedId,
              semanticLabel: option.label,
              onTap: () => Navigator.of(context).pop(option.id),
              // No padding of its own: `TioSelectableCard` already pads its
              // child, and adding to it made every option twice as tall as it
              // needs to be for one line of text.
              child: Text(
                option.label,
                // A custom name can be longer than any of the defaults, and at
                // a large text scale it wraps rather than being cut.
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: TioFontWeight.w700,
                  fontSize: TioFontSize.size15,
                ),
              ),
            ),
            const SizedBox(height: TioSpacing.sm),
          ],
        ],
      ),
    );
  }
}
