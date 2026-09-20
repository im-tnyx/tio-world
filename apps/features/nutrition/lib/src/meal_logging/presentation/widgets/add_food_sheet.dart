import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/repositories/meal_text_parse_repository.dart';
import '../../meal_text_parse_controller.dart';

/// What the reader asked the Add Food sheet for.
///
/// The two currently implemented Add Food paths.
///
/// Natural-language text returns only a provider-neutral draft; Quick Add
/// returns its explicit action identity. Photo and food-search remain visible
/// but unavailable and therefore cannot produce a result.
enum MealDiaryAddFoodChoice { quickAdd, parsedText }

@immutable
final class MealDiaryAddFoodResult {
  const MealDiaryAddFoodResult.quickAdd()
      : choice = MealDiaryAddFoodChoice.quickAdd,
        draft = null;

  const MealDiaryAddFoodResult.parsedText(this.draft)
      : choice = MealDiaryAddFoodChoice.parsedText;

  final MealDiaryAddFoodChoice choice;
  final MealLoggingDraft? draft;
}

/// Opens the Add Food sheet and reports what was chosen.
///
/// Returns null when the reader backed out. Parsed text returns only a
/// provider-neutral draft; nothing becomes durable until the later Meal Editor
/// confirmation.
Future<MealDiaryAddFoodResult?> showMealDiaryAddFoodSheet(
  BuildContext context, {
  MealTextParseRepository? mealTextParseRepository,
}) {
  return showModalBottomSheet<MealDiaryAddFoodResult>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    backgroundColor: TioPalette.transparent,
    builder: (sheetContext) => Stack(
      children: [
        // The sheet stays where it is when the keyboard opens; the keyboard is
        // drawn over its lower part. `SafeArea` would follow `padding`, which
        // Android shrinks to zero while the keyboard covers the navigation
        // bar, so the sheet would sink by the bar's height. The bar's height
        // is `viewPadding`, which does not change, so it is used instead.
        Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewPaddingOf(sheetContext).bottom,
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: SingleChildScrollView(
              child: AddFoodSheet(
                mealTextParseRepository: mealTextParseRepository,
                onParsed: (draft) => Navigator.of(sheetContext).pop(
                  MealDiaryAddFoodResult.parsedText(draft),
                ),
                onQuickAdd: () => Navigator.of(sheetContext).pop(
                  const MealDiaryAddFoodResult.quickAdd(),
                ),
                onDismiss: () => Navigator.of(sheetContext).pop(),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: MediaQuery.viewPaddingOf(sheetContext).bottom,
          child: ColoredBox(
            key: const ValueKey('meal-diary-add-food-bottom-inset-fill'),
            color: sheetContext.tioColors.surface,
          ),
        ),
      ],
    ),
  );
}

/// The Add Food surface: the four ways N5 will eventually let someone log a
/// meal, weighted the way TNYX-62 specifies rather than flattened into a list.
///
/// ```text
/// Add Food                                   ×
/// ┌─────────────────────────────────────────┐
/// │ What did you eat?                    🎙 │   describe it
/// └─────────────────────────────────────────┘
/// ┌─────────────────────────────────────────┐
/// │ 📷  Take a Photo                        │   or show it
/// └─────────────────────────────────────────┘
/// ┌──────────────────┐ ┌────────────────────┐
/// │ +  Quick Add     │ │ 🔍  Search Food    │   or do it yourself
/// └──────────────────┘ └────────────────────┘
/// ```
///
/// The shape carries the meaning. Describing a meal is the way most meals will
/// be logged, so it is the largest thing on the sheet and looks like somewhere
/// to type. A photo is the second way, so it gets a card of its own. Quick Add
/// and Search are the deliberate manual fallbacks, so they share one compact
/// row. Rendering all four as equal rows — which is what this sheet did before
/// device review — throws that away and makes the reader read four options
/// instead of seeing one.
///
/// Natural-language text and Quick Add work today. Photo and Search remain
/// drawn as unavailable — dimmed, inert, saying so in their own copy and
/// reported disabled to assistive technology — because a row that looks live
/// and does nothing is worse than no row at all. Voice remains visible as the
/// blank-text affordance but is intentionally unavailable in this slice.
class AddFoodSheet extends StatelessWidget {
  const AddFoodSheet({
    required this.onQuickAdd,
    required this.onDismiss,
    required this.onParsed,
    super.key,
    this.mealTextParseRepository,
  });

  /// Said in the copy, not only in the dimming, and repeated in semantics.
  static const unavailable = 'Not available yet';

  final VoidCallback onQuickAdd;
  final VoidCallback onDismiss;
  final ValueChanged<MealLoggingDraft> onParsed;
  final MealTextParseRepository? mealTextParseRepository;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return TioSheet(
      key: const ValueKey('meal-diary-add-food-sheet'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Add Food',
                  style: textTheme.titleLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: TioFontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('meal-diary-add-food-close'),
                tooltip: 'Close',
                onPressed: onDismiss,
                icon: Icon(Icons.close_rounded, color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: TioSpacing.sm),
          _DescribeMealSurface(
            repository: mealTextParseRepository,
            onParsed: onParsed,
          ),
          const _KeyboardGap(),
          const _PhotoCard(),
          const SizedBox(height: TioSpacing.md),
          // Intrinsic height so the two compact cards match whichever of them
          // wraps onto more lines — on a narrow phone that is usually the one
          // with the longer label, and a short card beside a tall one reads as
          // a mistake.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _CompactAction(
                    actionKey: const ValueKey('add-food-quick-add'),
                    icon: Icons.add_rounded,
                    title: 'Quick Add',
                    supportingText: 'Calories and macros',
                    semanticLabel: 'Quick Add. Calories and macros.',
                    onTap: onQuickAdd,
                  ),
                ),
                const SizedBox(width: TioSpacing.md),
                const Expanded(
                  child: _CompactAction(
                    actionKey: ValueKey('add-food-search'),
                    icon: Icons.search_rounded,
                    title: 'Search Food',
                    supportingText: unavailable,
                    semanticLabel: 'Search Food. $unavailable.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The natural-language entry point: the primary way N5 expects meals to be
/// logged, so it is the one element on the sheet shaped like somewhere to type.
///
/// The accepted outlined-card composition is preserved while the centre region
/// becomes a real text field. The permanent leading keyboard affordance only
/// controls focus/software-keyboard visibility; the trailing Mic remains while
/// input is blank and changes to Send only for nonblank text.
class _DescribeMealSurface extends StatefulWidget {
  const _DescribeMealSurface({
    required this.repository,
    required this.onParsed,
  });

  final MealTextParseRepository? repository;
  final ValueChanged<MealLoggingDraft> onParsed;

  @override
  State<_DescribeMealSurface> createState() => _DescribeMealSurfaceState();
}

class _DescribeMealSurfaceState extends State<_DescribeMealSurface> {
  final _text = TextEditingController();
  final _focusNode = FocusNode();
  MealTextParseController? _controller;

  @override
  void initState() {
    super.initState();
    _text.addListener(_onTextChanged);
    _bindController();
  }

  @override
  void didUpdateWidget(covariant _DescribeMealSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.repository, widget.repository)) {
      _unbindController();
      _bindController();
    }
  }

  @override
  void dispose() {
    _text
      ..removeListener(_onTextChanged)
      ..dispose();
    _focusNode.dispose();
    _unbindController();
    super.dispose();
  }

  void _bindController() {
    final repository = widget.repository;
    if (repository == null) return;
    _controller = MealTextParseController(repository: repository)
      ..addListener(_onControllerChanged);
  }

  void _unbindController() {
    _controller
      ?..removeListener(_onControllerChanged)
      ..dispose();
    _controller = null;
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  bool get _isAvailable => _controller != null;
  bool get _hasText => _text.text.trim().isNotEmpty;
  bool get _isProcessing => _controller?.state.isProcessing ?? false;

  void _toggleKeyboard() {
    if (!_isAvailable || _isProcessing) return;
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (keyboardVisible) {
      FocusScope.of(context).unfocus();
      return;
    }
    _focusNode.requestFocus();
  }

  Future<void> _submit() async {
    final controller = _controller;
    final text = _text.text.trim();
    if (controller == null || !controller.canSubmit(text)) return;

    FocusScope.of(context).unfocus();

    final state = controller.state;
    final draft = state.canRetry && state.submittedText == text
        ? await controller.retry()
        : await controller.submit(text);
    if (!mounted || draft == null) return;
    widget.onParsed(draft);
  }

  /// The line under the field only carries state. At rest the field's own hint
  /// is the single prompt, so there is nothing to say and no second line.
  String? _supportingText() {
    if (!_isAvailable) return AddFoodSheet.unavailable;
    final state = _controller!.state;
    if (state.isProcessing) return 'Processing meal…';
    if (state.status == MealTextParseStatus.failed &&
        state.submittedText == _text.text.trim()) {
      return state.message ?? MealTextParseController.unavailableMessage;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;
    final available = _isAvailable;
    final canSubmit = available && _hasText && !_isProcessing;
    final supportingText = _supportingText();
    final hasVisibleFailure = _controller?.state.status ==
            MealTextParseStatus.failed &&
        _controller?.state.submittedText == _text.text.trim();

    final card = TioCard(
      variant: TioCardVariant.outlined,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Semantics(
            button: true,
            enabled: available && !_isProcessing,
            label: 'Show or hide keyboard',
            child: InkResponse(
              key: const ValueKey('add-food-keyboard'),
              onTap: available && !_isProcessing ? _toggleKeyboard : null,
              radius: TioSize.dp24,
              // Pressing it only shows or hides the keyboard. The splash and
              // highlight an ink response paints around a bare icon read as a
              // blur inside the card, so neither is drawn.
              splashFactory: NoSplash.splashFactory,
              overlayColor: const WidgetStatePropertyAll(TioPalette.transparent),
              child: SizedBox(
                width: TioSize.dp40,
                height: TioSize.dp40,
                child: Icon(
                  Icons.keyboard_alt_outlined,
                  size: TioSize.dp22,
                  color: available ? colors.textSecondary : colors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: TioSpacing.sm),
          Expanded(
            child: KeyedSubtree(
              key: const ValueKey('add-food-ai-text'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                TextField(
                  key: const ValueKey('add-food-ai-text-field'),
                  controller: _text,
                  focusNode: _focusNode,
                  enabled: available && !_isProcessing,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.send,
                  maxLines: 4,
                  minLines: 1,
                  onSubmitted: (_) => unawaited(_submit()),
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: TioFontWeight.w600,
                  ),
                  // The card owns the outline. `InputDecoration.collapsed` only
                  // clears `border`; the theme's enabled/focused outline would
                  // still be applied, so every border is cleared explicitly.
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    filled: false,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'What did you eat?',
                    // Muted and regular weight, as `TioInput` draws its hint, so
                    // the prompt reads as a placeholder and typed text does not
                    // look like it. Same size, so nothing shifts while typing.
                    hintStyle: textTheme.titleMedium?.copyWith(
                      color: colors.textMuted,
                      fontWeight: TioFontWeight.w400,
                    ),
                  ),
                ),
                if (supportingText != null) ...[
                  const SizedBox(height: TioSpacing.xxs),
                  Semantics(
                    liveRegion: _isProcessing || hasVisibleFailure,
                    child: Text(
                      supportingText,
                      key: const ValueKey('add-food-ai-supporting-text'),
                      style: TextStyle(
                        color: hasVisibleFailure
                            ? colors.danger
                            : colors.textSecondary,
                        fontSize: TioFontSize.size12,
                      ),
                    ),
                  ),
                ],
                ],
              ),
            ),
          ),
          const SizedBox(width: TioSpacing.sm),
          if (_isProcessing)
            const SizedBox(
              key: ValueKey('add-food-ai-processing'),
              width: TioSize.dp40,
              height: TioSize.dp40,
              child: Padding(
                padding: EdgeInsets.all(TioSpacing.sm),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (canSubmit)
            Semantics(
              button: true,
              enabled: true,
              label: 'Process meal description',
              child: InkResponse(
                key: const ValueKey('add-food-submit'),
                onTap: () => unawaited(_submit()),
                radius: TioSize.dp24,
                child: SizedBox(
                  width: TioSize.dp40,
                  height: TioSize.dp40,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: TioSize.dp22,
                    color: colors.primary,
                  ),
                ),
              ),
            )
          else
            Semantics(
              key: const ValueKey('add-food-voice'),
              button: true,
              enabled: false,
              label: 'Voice input. ${AddFoodSheet.unavailable}.',
              child: ExcludeSemantics(
                child: Container(
                  width: TioSize.dp40,
                  height: TioSize.dp40,
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mic_none_rounded,
                    size: TioSize.dp22,
                    // The entry point for logging a meal by voice, so it keeps
                    // the primary colour. It is still inert and reported as
                    // unavailable to assistive technology.
                    color: colors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (available) return card;
    return Opacity(opacity: TioOpacity.opacity64, child: card);
  }
}

/// The space between the describe card and the Photo card, which stretches
/// only while the keyboard would otherwise cover the describe card.
///
/// The sheet is anchored to the bottom of the screen and does not move when the
/// keyboard opens. Stretching this gap moves everything above it — the title
/// row and the describe card, still the same distance apart — up by the amount
/// it stretches, and the sheet's surface stretches upward with them. Everything
/// below stays put under the keyboard. On most phones the card is already clear
/// of the keyboard and the gap keeps its normal height.
class _KeyboardGap extends StatefulWidget {
  const _KeyboardGap();

  @override
  State<_KeyboardGap> createState() => _KeyboardGapState();
}

class _KeyboardGapState extends State<_KeyboardGap> {
  /// Distance from the top of the Photo card to the bottom of the sheet. It is
  /// fixed by the content below the gap, so it does not change while the
  /// keyboard moves; it is measured once the sheet has finished opening.
  double? _below;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final navBar = MediaQuery.viewPaddingOf(context).bottom;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureBelow());

    // The stretch is worked out from the keyboard's height in this same build,
    // never from where things ended up after the last layout, so it follows
    // the keyboard frame for frame instead of trailing it.
    //
    // The describe card's bottom edge sits `navBar + below + gap + extra` above
    // the bottom of the screen and has to clear the keyboard by a small margin.
    var extra = 0.0;
    final below = _below;
    if (below != null) {
      extra = keyboard + TioSpacing.sm - navBar - below - TioSpacing.md;
      if (extra < 0) extra = 0;
    }
    return SizedBox(height: TioSpacing.md + extra);
  }

  void _measureBelow() {
    if (!mounted) return;
    // Mid-transition the sheet is still sliding in, so positions are not final.
    final opening = ModalRoute.of(context)?.animation;
    if (opening != null && opening.status != AnimationStatus.completed) return;
    // A full-height, scrolling sheet keeps the field at the top anyway, and
    // its positions are not measured from the bottom.
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable != null &&
        (scrollable.position.pixels != 0 ||
            scrollable.position.maxScrollExtent > 0)) {
      return;
    }
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;

    final photoTop = box.localToGlobal(Offset(0, box.size.height)).dy;
    final sheetBottom = MediaQuery.sizeOf(context).height -
        MediaQuery.viewPaddingOf(context).bottom;
    final below = sheetBottom - photoTop;
    final known = _below;
    if (known == null || (below - known).abs() > 0.5) {
      setState(() => _below = below);
    }
  }
}

/// The second capture route, on a card of its own so it stays clearly above
/// the two manual fallbacks and clearly below the describe-it surface.
class _PhotoCard extends StatelessWidget {
  const _PhotoCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      key: const ValueKey('add-food-photo'),
      button: true,
      enabled: false,
      label: 'Take a Photo. ${AddFoodSheet.unavailable}.',
      child: ExcludeSemantics(
        child: Opacity(
          opacity: TioOpacity.opacity64,
          child: TioCard(
            variant: TioCardVariant.normal,
            child: Row(
              children: [
                Icon(
                  Icons.photo_camera_outlined,
                  size: TioSize.dp22,
                  color: colors.textMuted,
                ),
                const SizedBox(width: TioSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Take a Photo',
                        style: textTheme.titleMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: TioFontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: TioSpacing.xxs),
                      Text(
                        'Analyze food from a photo · '
                        '${AddFoodSheet.unavailable}',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: TioFontSize.size12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One of the two manual fallbacks that share the bottom row.
///
/// [onTap] null is the unavailable state: no ripple, no callback, dimmed, and
/// disabled to assistive technology. There is no separate `enabled` flag,
/// because an action with nowhere to go and an action that is switched off are
/// the same thing here.
class _CompactAction extends StatelessWidget {
  const _CompactAction({
    required this.actionKey,
    required this.icon,
    required this.title,
    required this.supportingText,
    required this.semanticLabel,
    this.onTap,
  });

  final Key actionKey;
  final IconData icon;
  final String title;
  final String supportingText;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;
    final isEnabled = onTap != null;
    final iconColor = isEnabled ? colors.primary : colors.textMuted;

    final card = TioCard(
      variant: TioCardVariant.normal,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: TioSize.dp20, color: iconColor),
              const SizedBox(width: TioSpacing.sm),
              Flexible(
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: TioFontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TioSpacing.xxs),
          Text(
            supportingText,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: TioFontSize.size12,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      key: actionKey,
      button: true,
      enabled: isEnabled,
      label: semanticLabel,
      onTap: onTap,
      child: ExcludeSemantics(
        child: isEnabled
            ? card
            : Opacity(opacity: TioOpacity.opacity64, child: card),
      ),
    );
  }
}
