import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:tio_core/core.dart';

import '../../../domain/repositories/meal_categories_repository.dart';
import '../../../domain/usecases/meal_category_time_suggestion.dart';
import '../../../meal_diary/presentation/controllers/meal_categories_controller.dart';
import 'meal_category_picker_popup.dart';
import 'meal_log_action_footer.dart';

/// Opens a brand-new Quick Add manual nutrition editor.
Future<void> showQuickAddEditorSheet(
  BuildContext context, {
  DateTime Function()? clock,
  MealCategoriesRepository? mealCategoriesRepository,
}) {
  return showTioEditorSheet<void>(
    context: context,
    // Same reason as the Add Food sheet: the diary sits inside a shell branch
    // navigator, and an editor holding a captured date must not leave the
    // Today action or the tabs reachable behind it.
    useRootNavigator: true,
    // And the same reason again for the top: without this the route strips the
    // top padding, so a keyboard-raised or split-screen viewport can push the
    // handle and title under the status bar.
    useSafeArea: true,
    builder: (_) => QuickAddEditorSheet(
      clock: clock,
      mealCategoriesRepository: mealCategoriesRepository,
    ),
  );
}

/// The manual/coarse nutrition editor.
///
/// ```text
/// Quick Add
/// ┌────────────────────────────────┐
/// │ Meal name (optional)           │   large, and the only free text
/// └────────────────────────────────┘
/// Calories (kcal)         [      ]
/// Carbs (g)               [      ]
/// Protein (g)             [      ]
/// Fat (g)                 [      ]
/// ─────────────────────────────────   body scrolls, footer does not
/// Meal type ▼        🗓 Sep 6, 00:07
/// [           Log Meal            ]
/// ```
///
/// ## Why this is not the Meal Editor
///
/// Quick Add is for the reader who already knows the numbers and does not want
/// to name a single ingredient. AI, voice, photo, search, repeat and saved
/// meals will all converge on the full Meal Editor through a draft; this screen
/// deliberately does not, because routing it there would make the fastest path
/// wear the slowest screen's chrome. They may share components. They are not
/// the same surface.
///
/// ## Why so few fields
///
/// Fiber and micronutrients were dropped from this shell on owner review. They
/// are not cancelled — TNYX-115 and TNYX-58 can add supported nutrients later
/// through the shared nutrition-value contract — but a coarse entry that asks
/// for seven numbers is not a coarse entry.
///
/// ## Why `Log Meal` does nothing
///
/// Actual meal history is owned by TNYX-113 (the canonical entry), TNYX-114
/// (consumed time and local-date semantics) and TNYX-115 (the Quick Add
/// lifecycle). None of them exists yet. A button that stored the meal
/// somewhere improvised — in memory, in preferences, in a table invented here
/// — would be a second, wrong owner of the user's history, and the user would
/// find out it was wrong by losing meals. So the button is present, disabled,
/// and says why.
///
/// Every value, including the selected local DateTime, lives in this `State`
/// and dies with the route. There is no notifier, repository or store behind
/// it. Reopening a brand-new Quick Add takes a fresh current-local snapshot.
class QuickAddEditorSheet extends StatefulWidget {
  const QuickAddEditorSheet({
    super.key,
    this.clock,
    this.mealCategoriesRepository,
  });

  /// Optional local clock seam. Production uses `DateTime.now`.
  final DateTime Function()? clock;

  /// Where the meal categories come from, supplied by app composition.
  ///
  /// Nutrition cannot reach the provider that owns it — the app depends on the
  /// feature, not the reverse — so it arrives the same way the diary's week
  /// start does. Null leaves the Meal type control inert, which is what a
  /// surface with no category source honestly is.
  final MealCategoriesRepository? mealCategoriesRepository;

  @override
  State<QuickAddEditorSheet> createState() => _QuickAddEditorSheetState();
}

class _QuickAddEditorSheetState extends State<QuickAddEditorSheet>
    with WidgetsBindingObserver {
  final _mealCategoryAnchorKey = GlobalKey();
  final _dateTimeAnchorKey = GlobalKey();
  final _mealName = TextEditingController();
  final _calories = TextEditingController();
  final _carbs = TextEditingController();
  final _protein = TextEditingController();
  final _fat = TextEditingController();

  late final List<TextEditingController> _fields = [
    _mealName,
    _calories,
    _carbs,
    _protein,
    _fat,
  ];
  late DateTime _draftDateTime;
  late DateTime _maximumDateTime;
  Timer? _maximumDateTimer;

  /// Built here and read once per editor session.
  ///
  /// One read when the editor opens rather than one per selector opening: the
  /// options cannot change while this sheet is up, and a fresh read each
  /// session is what keeps a category renamed or archived in Settings from
  /// showing up stale here. There is no second cache — this is the same
  /// controller the Meal Categories screen uses.
  MealCategoriesController? _categories;

  /// The category the reader chose, held as its durable id.
  ///
  /// Never the label: renaming a category must move what the footer reads
  /// without moving what the draft points at.
  ///
  /// Null means they have not chosen yet, which is not the same as nothing
  /// being selected — until then the editor offers a suggestion.
  String? _chosenMealCategoryId;

  /// Whether the Meal Type card is showing. Owned here, exactly as the
  /// date/time popup's flag is: the footer stays a fixed strip and the card
  /// floats over the body above it.
  var _isMealTypePickerOpen = false;
  var _isDateTimePickerOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final repository = widget.mealCategoriesRepository;
    if (repository != null) {
      _categories = MealCategoriesController(repository: repository)
        ..addListener(_onCategoriesChanged)
        ..load();
    }
    final openedAt = _currentLocalNow();
    _draftDateTime = _minuteOnly(openedAt);
    _maximumDateTime = _draftDateTime;
    // Validation is per-keystroke because the errors are about the characters
    // themselves, not about a submission that cannot happen here.
    for (final controller in _fields) {
      controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _stopMaximumDateRefresh();
    _categories
      ?..removeListener(_onCategoriesChanged)
      ..dispose();
    WidgetsBinding.instance.removeObserver(this);
    for (final controller in _fields) {
      controller
        ..removeListener(_onChanged)
        ..dispose();
    }
    super.dispose();
  }

  void _onCategoriesChanged() {
    if (mounted) setState(() {});
  }

  /// What the footer may offer: active categories only, in the order the
  /// configuration puts them.
  ///
  /// Archived ones are absent rather than disabled. A new log cannot be filed
  /// under a category the reader has retired, and showing it greyed out would
  /// only invite the question of why.
  List<MealCategoryOption> get _categoryOptions {
    final controller = _categories;
    if (controller == null) return const [];
    return [
      for (final item in controller.state.activeItems)
        MealCategoryOption(id: item.id, label: item.displayName),
    ];
  }

  /// Openable once there is something to show — options, or a failure to
  /// explain. Inert only while the categories are still loading.
  bool get _canOpenMealTypePicker =>
      _categories != null &&
      _categories!.state.status != MealCategoriesStatus.loading;

  /// Opens the Meal Type card, or closes it if it is already showing.
  ///
  /// Never both: the date card is closed in the same frame, because each card
  /// leaves the other's control reachable and a tap there means "show me that
  /// one instead". Tapping this control while its own card is open just
  /// closes it — these are two controls, not a pair of tabs where one is
  /// always chosen.
  void _toggleMealTypePicker() {
    setState(() {
      _isDateTimePickerOpen = false;
      _isMealTypePickerOpen = !_isMealTypePickerOpen;
    });
  }

  void _closeMealTypePicker() {
    if (!_isMealTypePickerOpen) return;
    setState(() => _isMealTypePickerOpen = false);
  }

  /// Choosing is the whole interaction: it selects and closes.
  ///
  /// From here the suggestion stops applying. Changing the time afterwards
  /// must not quietly move the reader's own answer somewhere else.
  void _onMealCategorySelected(String id) {
    setState(() {
      _chosenMealCategoryId = id;
      _isMealTypePickerOpen = false;
    });
  }

  /// What the footer shows: the reader's choice, or the suggestion until they
  /// make one.
  ///
  /// Derived rather than stored, so the suggestion follows the draft's time
  /// while it still applies and is simply ignored once a choice exists. There
  /// is no second copy to keep in step.
  String? get _selectedMealCategoryId =>
      _chosenMealCategoryId ?? _suggestedMealCategoryId;

  /// The canonical category the draft's own consumed time points at.
  ///
  /// The draft's time, never the device clock: a reader logging last night's
  /// dinner at breakfast time has already said when they ate, and the editor
  /// should follow that rather than the hour they happen to be typing in.
  String? get _suggestedMealCategoryId {
    final controller = _categories;
    if (controller == null) return null;
    return suggestedMealCategoryId(
      consumedLocal: _draftDateTime,
      activeItems: controller.state.activeItems,
    );
  }

  /// The chosen category's current name, or null when the selection names
  /// nothing available. A stale id is never swapped for another category — the
  /// control falls back to its invitation and the stored id is left alone.
  String? get _selectedCategoryLabel {
    final id = _selectedMealCategoryId;
    if (id == null) return null;
    for (final option in _categoryOptions) {
      if (option.id == id) return option.label;
    }
    return null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isDateTimePickerOpen) {
      final now = _currentLocalNow();
      _refreshMaximumDateTime(now);
      _scheduleMaximumDateRefresh(now);
      return;
    }
    _stopMaximumDateRefresh();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  DateTime _currentLocalNow() => widget.clock?.call() ?? DateTime.now();

  DateTime _minuteOnly(DateTime value) {
    return DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
    );
  }

  DateTime _resolveMealDateTime(DateTime candidate) {
    // The wheel has minute precision. Compare its zero-second candidate to the
    // real clock, then snap to the real minute floor. Hidden seconds can never
    // make the same visible minute inconsistently valid or invalid.
    final now = _minuteOnly(_currentLocalNow());
    _maximumDateTime = now;
    return candidate.isAfter(now) ? now : candidate;
  }

  void _refreshMaximumDateTime([DateTime? current]) {
    final maximum = _minuteOnly(current ?? _currentLocalNow());
    if (maximum == _maximumDateTime) return;
    setState(() => _maximumDateTime = maximum);
  }

  void _scheduleMaximumDateRefresh([DateTime? current]) {
    _maximumDateTimer?.cancel();
    final now = current ?? _currentLocalNow();
    final nextMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );
    final delay = nextMinute.difference(now);
    if (delay <= Duration.zero) return;
    _maximumDateTimer = Timer(delay, () {
      if (!mounted) return;
      final refreshedAt = _currentLocalNow();
      _refreshMaximumDateTime(refreshedAt);
      _scheduleMaximumDateRefresh(refreshedAt);
    });
  }

  void _stopMaximumDateRefresh() {
    _maximumDateTimer?.cancel();
    _maximumDateTimer = null;
  }

  void _onDateTimeChanged(DateTime value) {
    setState(() => _draftDateTime = value);
  }

  void _toggleDateTimePicker() {
    FocusScope.of(context).unfocus();
    _refreshMaximumDateTime();
    setState(() {
      // The other card cannot stay up behind this one.
      _isMealTypePickerOpen = false;
      _isDateTimePickerOpen = !_isDateTimePickerOpen;
    });
    if (_isDateTimePickerOpen) {
      _scheduleMaximumDateRefresh();
    } else {
      _stopMaximumDateRefresh();
    }
  }

  void _closeDateTimePicker() {
    if (!_isDateTimePickerOpen) return;
    _stopMaximumDateRefresh();
    setState(() => _isDateTimePickerOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final selectedDateLabel = localizations.formatShortMonthDay(_draftDateTime);
    final selectedTimeLabel =
        '${_draftDateTime.hour.toString().padLeft(2, '0')}:'
        '${_draftDateTime.minute.toString().padLeft(2, '0')}';
    final dateTimeLabel = '$selectedDateLabel, $selectedTimeLabel';

    // Neither card is a route, so without this the system Back would pop the
    // editor and take the whole draft with it while the reader only meant to
    // close the thing in front of them.
    return PopScope(
      canPop: !_isMealTypePickerOpen && !_isDateTimePickerOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_isMealTypePickerOpen) {
          _closeMealTypePicker();
        } else {
          _closeDateTimePicker();
        }
      },
      child: MealCategoryPickerPopup(
        anchorKey: _mealCategoryAnchorKey,
      isOpen: _isMealTypePickerOpen,
      onDismiss: _closeMealTypePicker,
      options: _categoryOptions,
      selectedId: _selectedMealCategoryId,
      onSelected: _onMealCategorySelected,
      loadError: _categories?.state.loadError,
      isLoading: _categories?.state.status == MealCategoriesStatus.loading,
      onRetry: _categories?.retryLoad,
      // The date control stays reachable while this card is open, so moving
      // from one to the other is a single tap.
      passThroughAnchorKey: _dateTimeAnchorKey,
      child: TioDateTimePickerPopup(
      anchorKey: _dateTimeAnchorKey,
      isOpen: _isDateTimePickerOpen,
      onDismiss: _closeDateTimePicker,
      value: _draftDateTime,
      maximumDate: _maximumDateTime,
      resolveDateTime: _resolveMealDateTime,
      onChanged: _onDateTimeChanged,
      onPickerInteractionStart: _refreshMaximumDateTime,
      // And the same the other way round — but only while that control can
      // actually be pressed. Cutting a hole over an inert widget would leave a
      // patch of screen where a tap neither opens anything nor closes this.
      passThroughAnchorKey:
          _canOpenMealTypePicker ? _mealCategoryAnchorKey : null,
      child: TioEditorSheet(
        key: const ValueKey('quick-add-editor'),
        title: 'Quick Add',
        // The footer draws its own rule across the sheet, so the standard gap
        // above the actions would only put dead space above that line.
        flushActions: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The one free-text field. It uses the governed larger rounded
            // surface so it reads as the thing you name the meal with, but it
            // starts at one line: a fixed two-line box was more room than a
            // title needs and made the screen top-heavy. It still grows to a
            // second line for a longer name, and stops there — this is a title,
            // not a notes field.
            TioInput.multiline(
              key: const ValueKey('quick-add-meal-name'),
              controller: _mealName,
              hint: 'Meal name (optional)',
              minLines: 1,
              maxLines: 2,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              onChanged: (_) {},
            ),
            const SizedBox(height: TioSpacing.lg),
            _NutritionRow(
              fieldKey: const ValueKey('quick-add-calories'),
              controller: _calories,
              label: 'Calories',
              unit: 'kcal',
            ),
            const SizedBox(height: TioSpacing.md),
            _NutritionRow(
              fieldKey: const ValueKey('quick-add-carbs'),
              controller: _carbs,
              label: 'Carbs',
              unit: 'g',
            ),
            const SizedBox(height: TioSpacing.md),
            _NutritionRow(
              fieldKey: const ValueKey('quick-add-protein'),
              controller: _protein,
              label: 'Protein',
              unit: 'g',
            ),
            const SizedBox(height: TioSpacing.md),
            _NutritionRow(
              fieldKey: const ValueKey('quick-add-fat'),
              controller: _fat,
              label: 'Fat',
              unit: 'g',
            ),
            // The footer divider is intentionally flush to the action region;
            // reserve body breathing room so the final input does not touch it.
            const SizedBox(height: TioSpacing.md),
          ],
        ),
        actions: MealLogActionFooter(
          // An invitation, not a guess. TNYX-67 owns what a meal category is,
          // The reader's choice, the suggestion the draft's time points at, or
          // — until the categories have arrived — neither.
          mealCategoryLabel: _selectedCategoryLabel ?? _categoryPlaceholder,
          mealCategorySemanticLabel: _categorySemanticLabel,
          mealCategoryAnchorKey: _mealCategoryAnchorKey,
          onMealCategoryTap: _canOpenMealTypePicker ? _toggleMealTypePicker : null,
          dateTimeLabel: dateTimeLabel,
          dateTimeSemanticLabel: 'Date and time. $dateTimeLabel. '
              'Picker ${_isDateTimePickerOpen ? 'expanded' : 'collapsed'}.',
          onDateTimeTap: _toggleDateTimePicker,
          dateTimeAnchorKey: _dateTimeAnchorKey,
          primaryLabel: 'Log Meal',
          primarySemanticLabel: 'Log Meal. Not available yet.',
        ),
      ),
      ),
      ),
    );
  }
}

extension _QuickAddCategories on _QuickAddEditorSheetState {

  /// What the control reads before anything is selected.
  ///
  /// One wording for every such state, and the short one. `Select meal type`
  /// said the same thing at greater length — the chevron beside it already
  /// says the control opens something — and having a separate loading wording
  /// only moved the flip rather than removing it: the reader saw `Meal type`
  /// and then `Select meal type`, two labels for one situation.
  ///
  /// It is also the widest thing this control ever has to show before a
  /// category is picked, so the short form is what keeps it off the date.
  String get _categoryPlaceholder => 'Meal type';

  /// Spoken as a label and a value, never as an identity.
  String get _categorySemanticLabel {
    final controller = _categories;
    if (controller == null) return 'Meal type. Not available yet.';
    switch (controller.state.status) {
      case MealCategoriesStatus.loading:
        return 'Meal type. Loading.';
      case MealCategoriesStatus.loadFailed:
        return 'Meal type. Could not load meal categories.';
      case MealCategoriesStatus.ready:
        final selected = _selectedCategoryLabel;
        return selected == null
            ? 'Meal type. None selected.'
            : 'Meal type. $selected.';
    }
  }
}

/// One coarse nutrition value: label on the left, a compact number on the
/// right.
///
/// Blank means absent, not zero: the reader who skips Carbs has not told the
/// app they ate none, and this slice must not turn silence into a number. That
/// distinction is the reason the field carries no default text.
///
/// ## Why there is no input formatter
///
/// A character allow-list looks like the safe option and is the opposite of
/// one. Filtering does not reject the input — it edits it, and the edit lands
/// on a value that is still a number:
///
/// ```text
/// 1,5       → 1 5     → 15
/// 1e400abc  → 1 400   → 1400
/// ```
///
/// The reader typed one number and the field kept a different one, with no
/// error to notice. Per-keystroke rejection has the same ending: refuse the
/// comma in `1,5` and the following `5` still lands on the `1`.
///
/// So nothing is filtered. Whatever is typed stays visible, and [_error]
/// decides whether it is a number. The reader either sees their own value or
/// sees why it is not accepted; the field never quietly holds a third thing.
class _NutritionRow extends StatelessWidget {
  const _NutritionRow({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.unit,
  });

  /// Width of the value box. Wide enough for any calorie count anyone eats,
  /// narrow enough that the label keeps the row.
  static const _valueWidth = TioSize.dp100;

  final ValueKey<String> fieldKey;
  final TextEditingController controller;
  final String label;
  final String unit;

  /// Whether the current text is a usable coarse nutrition value, and if not,
  /// why.
  ///
  /// Parsing is deliberately not locale-aware. A comma is the decimal point in
  /// one locale and the thousands separator in another, so reading `1,5` as
  /// `1.5` in one place means reading `1,500` as `1.5` in another — which is
  /// the same silent wrong number the formatter used to produce, arrived at
  /// more politely. Until a repo-wide numeric-input slice can carry a real
  /// locale contract, an unsupported separator is refused out loud rather than
  /// guessed at.
  String? get _error {
    final text = controller.text.trim();
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    // `1e400` parses to infinity rather than failing, so finiteness is a
    // separate question from parseability.
    if (value == null || !value.isFinite) return 'Enter a number.';
    if (value < 0) return '$label cannot be negative.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final error = _error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$label ($unit)',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: TioFontSize.size15,
                  fontWeight: TioFontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: TioSpacing.md),
            SizedBox(
              width: _valueWidth,
              // The line below is the visible half of the error; this is the
              // half a screen reader needs. Without it the field keeps
              // reporting itself valid while a separate `Text` somewhere else
              // says otherwise, so someone on TalkBack hears nothing wrong
              // about the field they are actually sitting in.
              child: Semantics(
                validationResult: error == null
                    ? SemanticsValidationResult.none
                    : SemanticsValidationResult.invalid,
                child: TioInput.numericEditor(
                  key: fieldKey,
                  controller: controller,
                  hint: '0',
                  // The keyboard suggests the shape of the answer; it does not
                  // enforce it. Enforcement is [_error]'s job, so a hardware
                  // keyboard or a paste can put anything here and still be
                  // told what is wrong with it.
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  // Shorter than the editor default: four of these stacked
                  // read as a list of numbers, and each one only ever holds a
                  // few characters.
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: TioSpacing.md,
                    vertical: TioSpacing.sm,
                  ),
                  onChanged: (_) {},
                ),
              ),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: TioSpacing.xs),
          // A live region so the message is announced when it appears, rather
          // than only being found by someone who happens to move past it.
          Semantics(
            liveRegion: true,
            child: Text(
              error,
              key: ValueKey('${fieldKey.value}-error'),
              style: TextStyle(
                color: colors.danger,
                fontSize: TioFontSize.size13,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
