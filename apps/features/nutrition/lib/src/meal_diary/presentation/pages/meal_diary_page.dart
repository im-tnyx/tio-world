import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/repositories/meal_categories_repository.dart';
import '../../../domain/repositories/meal_log_repository.dart';
import '../../../meal_logging/quick_add_meal_log_edit_controller.dart';
import '../../../meal_logging/presentation/widgets/add_food_sheet.dart';
import '../../../meal_logging/presentation/widgets/quick_add_editor_sheet.dart';
import '../../meal_diary_history_providers.dart';
import '../controllers/meal_diary_date_controller.dart';
import '../widgets/meal_diary_history_view.dart';
import '../widgets/meal_diary_log_action.dart';

/// Vertical room the floating `+` occupies at the bottom of the diary body:
/// the button itself plus the padding above and below it.
///
/// This is only the button's own footprint. The action also sits inside a
/// `SafeArea`, so on a viewport with a bottom inset — the shell's navigation
/// hidden, a gesture bar present — it rides that much higher and the body has
/// to reserve the inset too. See [_reservedClearance].
const double _actionClearance = TioSize.dp56 + TioSpacing.xl * 2;

/// The Meal Diary surface, and the first production consumer of the reusable
/// core date calendar.
///
/// The calendar integration stays intentionally thin. Nutrition supplies the
/// selected date, what counts as today, and the diary's own range — nothing
/// else. Everything about how a date strip scrolls, how the month grid expands
/// and how a date is drawn belongs to core.
///
/// Calendar progress decorations are still absent in this slice. Persisted
/// MealLog history renders below the calendar, but a calorie-progress ring
/// belongs to the later N3 daily-budget contract; drawing one here would invent
/// a denominator and conflate two read models.
///
/// Quick Add owns its own current-local consumed draft. A confirmed create is
/// persisted through the canonical MealLog repository and invalidates only its
/// affected Diary local-date read model; it never moves a historical selection.
class MealDiaryPage extends ConsumerStatefulWidget {
  const MealDiaryPage({
    super.key,
    this.resolvedFirstDayOfWeek,
    this.quickAddClock,
    this.mealCategoriesRepository,
  });

  /// The app-global week start, already resolved, supplied by app composition.
  ///
  /// Nutrition receives it and forwards it. It never persists it, never infers
  /// it from the locale and never keeps a second copy: week start is one
  /// app-wide Calendar Preferences value, not a diary setting. Null keeps the
  /// calendar's own locale fallback, which is what happens before the
  /// preference has loaded.
  final int? resolvedFirstDayOfWeek;

  /// Canonical Meal Categories owner supplied by app composition.
  ///
  /// Quick Add uses active categories; selected-day history uses the same
  /// retained configuration so archived category identities remain resolvable.
  /// Null is allowed only for isolated feature harnesses and never fabricates
  /// category/history data.
  final MealCategoriesRepository? mealCategoriesRepository;

  /// Testable local clock seam for a brand-new Quick Add draft.
  ///
  /// Production leaves this null and the editor reads `DateTime.now()` once
  /// when it opens. Keeping the seam on the route-owned entry avoids global
  /// clock state while allowing the complete Diary -> Quick Add flow to be
  /// deterministic in widget tests.
  final DateTime Function()? quickAddClock;

  @override
  ConsumerState<MealDiaryPage> createState() => _MealDiaryPageState();
}

class _MealDiaryPageState extends ConsumerState<MealDiaryPage>
    with WidgetsBindingObserver {
  /// One shot, aimed at the next local midnight, owned by this screen.
  ///
  /// The screen owns it rather than the controller because a provider can keep
  /// a controller alive after the page is gone; a timer parked there would run
  /// on behind an unmounted screen. Tied to the State, it dies with the route.
  Timer? _midnightTimer;

  /// Whether the calendar is currently showing its month grid.
  ///
  /// Observed, not owned: the page passes no `displayMode`, so the calendar
  /// keeps deciding what it shows and merely reports the change. The page
  /// needs to know only because the expanded grid reaches the bottom of a
  /// short viewport, where a floating `+` would sit on top of its date cells.
  var _isCalendarExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnightRefresh();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // A phone asleep across midnight fires no timer, so coming back is the
      // other moment the diary has to re-check what day it is — and the timer
      // it had aimed at last night's midnight is now meaningless.
      ref.read(mealDiaryDateControllerProvider).refreshLocalDate();
      _scheduleMidnightRefresh();
      return;
    }
    // Nothing is on screen to keep current while the app is away.
    _midnightTimer?.cancel();
    _midnightTimer = null;
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final delay = ref
        .read(mealDiaryDateControllerProvider)
        .durationUntilNextLocalMidnight;
    if (delay <= Duration.zero) return;
    _midnightTimer = Timer(delay, () {
      if (!mounted) return;
      ref.read(mealDiaryDateControllerProvider).refreshLocalDate();
      // Aim at tomorrow, one night at a time, rather than polling.
      _scheduleMidnightRefresh();
    });
  }

  /// Meal Diary → Add Food → Quick Add.
  ///
  /// The Diary's selected date deliberately does not cross this boundary.
  /// A new Quick Add owns a fresh current-local DateTime snapshot, while the
  /// Diary keeps the historical day the reader was viewing. The canonical
  /// MealLog repository is passed from the existing feature seam; after a
  /// confirmed create only that entry's stored local-date history is refreshed.
  Future<void> _openAddFood() async {
    final choice = await showMealDiaryAddFoodSheet(context);
    if (choice == null || !mounted) return;

    switch (choice) {
      case MealDiaryAddFoodChoice.quickAdd:
        final mealLogRepository = ref.read(mealDiaryMealLogRepositoryProvider);
        final mealCategoriesRepository = widget.mealCategoriesRepository;
        final created = await showQuickAddEditorSheet(
          context,
          clock: widget.quickAddClock,
          mealCategoriesRepository: mealCategoriesRepository,
          mealLogRepository: mealLogRepository,
        );
        if (!mounted ||
            created == null ||
            mealLogRepository == null ||
            mealCategoriesRepository == null) {
          return;
        }

        ref.invalidate(
          mealDiaryHistoryProvider(
            MealDiaryHistoryRequest(
              mealLogRepository: mealLogRepository,
              mealCategoriesRepository: mealCategoriesRepository,
              localDate: created.consumedLocalDate,
            ),
          ),
        );
    }
  }

  /// Meal Diary card → canonical row → Quick Edit.
  ///
  /// The card read model intentionally omits revision, hidden note, full
  /// nutrition and timezone facts. Reading by id immediately before opening
  /// prevents presentation data from becoming a stale update payload.
  Future<void> _openQuickEdit(String id) async {
    final mealLogRepository = ref.read(mealDiaryMealLogRepositoryProvider);
    final mealCategoriesRepository = widget.mealCategoriesRepository;
    if (mealLogRepository == null || mealCategoriesRepository == null) return;

    MealLogEntry? entry;
    try {
      entry = await mealLogRepository.readById(id);
    } on Object {
      if (mounted) _showMealEditMessage("Couldn't open this meal. Try again.");
      return;
    }
    if (!mounted) return;
    if (entry == null) {
      _showMealEditMessage('This meal is no longer available.');
      return;
    }
    if (entry.mode != MealLogMode.manual ||
        entry.manualNutritionSnapshot == null ||
        QuickAddMealLogEditController.editableLocalDateTime(entry) == null) {
      _showMealEditMessage('Editing is not available for this meal yet.');
      return;
    }

    final originalDate = entry.consumedLocalDate;
    final updated = await showQuickAddEditorSheet(
      context,
      clock: widget.quickAddClock,
      mealCategoriesRepository: mealCategoriesRepository,
      mealLogRepository: mealLogRepository,
      initialEntry: entry,
    );
    if (!mounted || updated == null) return;

    _invalidateHistoryDate(
      repository: mealLogRepository,
      categoriesRepository: mealCategoriesRepository,
      localDate: originalDate,
    );
    if (updated.consumedLocalDate != originalDate) {
      _invalidateHistoryDate(
        repository: mealLogRepository,
        categoriesRepository: mealCategoriesRepository,
        localDate: updated.consumedLocalDate,
      );
    }
  }

  void _invalidateHistoryDate({
    required MealLogRepository repository,
    required MealCategoriesRepository categoriesRepository,
    required MealLogLocalDate localDate,
  }) {
    ref.invalidate(
      mealDiaryHistoryProvider(
        MealDiaryHistoryRequest(
          mealLogRepository: repository,
          mealCategoriesRepository: categoriesRepository,
          localDate: localDate,
        ),
      ),
    );
  }

  void _showMealEditMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final dates = ref.watch(mealDiaryDateControllerProvider);
    final mealLogRepository = ref.watch(mealDiaryMealLogRepositoryProvider);
    final mealCategoriesRepository = widget.mealCategoriesRepository;
    final historyRequest =
        mealLogRepository == null || mealCategoriesRepository == null
            ? null
            : MealDiaryHistoryRequest.forSelectedDate(
                mealLogRepository: mealLogRepository,
                mealCategoriesRepository: mealCategoriesRepository,
                selectedDate: dates.selectedDate,
              );

    return Stack(
      fit: StackFit.expand,
      children: [
        _diaryBody(dates, historyRequest),
        // The expanded month grid can reach the bottom of a short viewport,
        // and a `+` parked over one of its date cells is worse than no `+`
        // for as long as the grid is open. It comes back on collapse.
        if (!_isCalendarExpanded)
          Positioned.fill(
            // Bottom navigation is the Scaffold's own slot, so the body
            // already stops above it. SafeArea covers the case where the
            // shell hides the nav and the body reaches the gesture inset.
            child: SafeArea(
              child: Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: Padding(
                  padding: const EdgeInsets.all(TioSpacing.xl),
                  child: MealDiaryLogAction(
                    key: const ValueKey('meal-diary-add-food-action'),
                    onPressed: _openAddFood,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// The clearance for a given viewport: the button's footprint plus whatever
  /// bottom inset pushed it up. A fixed reservation left content underneath
  /// the button by exactly the inset.
  double _reservedClearance(BuildContext context) =>
      _actionClearance + MediaQuery.paddingOf(context).bottom;

  Widget _diaryBody(
    MealDiaryDateController dates,
    MealDiaryHistoryRequest? historyRequest,
  ) {
    // The expanded month grid is tall. On a landscape or split-screen viewport
    // it can exceed the body, so the page scrolls rather than overflowing —
    // while still filling a normal viewport so the empty state stays centred.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          // The floating `+` is painted over this scroll view, so the content
          // reserves its footprint at the bottom. Without it, the last lines of
          // a scrolled-to-the-end body sit underneath the button. Reserved
          // unconditionally rather than only while the button is visible: a
          // padding that appeared and vanished with the calendar's month grid
          // would shift the reader's scroll position every time they expanded
          // it.
          padding: EdgeInsets.only(bottom: _reservedClearance(context)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // Clamped: a viewport shorter than the reserved band would
              // otherwise ask for a negative minimum.
              minHeight: math.max(
                0,
                constraints.maxHeight - _reservedClearance(context),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TioDateCalendar(
                  controller: dates.calendarController,
                  selectedDate: dates.selectedDate,
                  localToday: dates.localToday,
                  minDate: dates.minDate,
                  maxDate: dates.maxDate,
                  onDateSelected: dates.select,
                  onVisibleDateRangeChanged: dates.updateVisibleDateRange,
                  // Reported, not driven: no `displayMode` is passed, so the
                  // calendar still owns which rendering it shows. The page
                  // listens only so the `+` can step out of the grid's way.
                  onDisplayModeChanged: (mode) {
                    if (_isCalendarExpanded == mode.isMonth) return;
                    setState(() => _isCalendarExpanded = mode.isMonth);
                  },
                  // Forwarded, not owned. TNYX-72 made this an app-global
                  // Calendar Preferences value; Nutrition is one consumer of
                  // it, exactly like Workout and Meal Plan will be.
                  resolvedFirstDayOfWeek: widget.resolvedFirstDayOfWeek,
                ),
                // Clearance for the handle's touch target, which reaches just
                // past the calendar's own edge so the small grabber still has a
                // full-size tap area. Nothing interactive may sit in this band.
                const SizedBox(height: TioSpacing.xl),
                MealDiaryHistoryView(
                  date: dates.selectedDate,
                  request: historyRequest,
                  onEdit: historyRequest == null ? null : _openQuickEdit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
