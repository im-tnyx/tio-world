import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_core/core.dart';

import '../controllers/meal_diary_date_controller.dart';

/// The Meal Diary surface, and the first production consumer of the reusable
/// core date calendar.
///
/// The integration is intentionally thin. Nutrition supplies the selected date,
/// what counts as today, and the diary's own range — nothing else. Everything
/// about how a date strip scrolls, how the month grid expands and how a date is
/// drawn belongs to core, which is what lets Workout and Meal Plan reuse the
/// same component later without any of this.
///
/// No decorations are supplied yet. There is no meal-log store, so there is no
/// progress to draw, and an absent decoration is the honest way to say that —
/// a zero would claim the user ate nothing, which is a different statement.
class MealDiaryPage extends ConsumerStatefulWidget {
  const MealDiaryPage({super.key});

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
    final delay =
        ref.read(mealDiaryDateControllerProvider).durationUntilNextLocalMidnight;
    if (delay <= Duration.zero) return;
    _midnightTimer = Timer(delay, () {
      if (!mounted) return;
      ref.read(mealDiaryDateControllerProvider).refreshLocalDate();
      // Aim at tomorrow, one night at a time, rather than polling.
      _scheduleMidnightRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dates = ref.watch(mealDiaryDateControllerProvider);

    // The expanded month grid is tall. On a landscape or split-screen viewport
    // it can exceed the body, so the page scrolls rather than overflowing —
    // while still filling a normal viewport so the empty state stays centred.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                  // resolvedFirstDayOfWeek is deliberately not passed. Week
                  // start is an app-global Calendar Preferences value; until
                  // that resolver exists the calendar falls back to the
                  // platform locale, which is the same "automatic" answer the
                  // resolver will give. Nutrition never owns it.
                ),
                // Clearance for the handle's touch target, which reaches just
                // past the calendar's own edge so the small grabber still has a
                // full-size tap area. Nothing interactive may sit in this band.
                const SizedBox(height: TioSpacing.xl),
                _SelectedDaySummary(date: dates.selectedDate),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SelectedDaySummary extends StatelessWidget {
  const _SelectedDaySummary({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;
    final localizations = MaterialLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(TioSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            localizations.formatFullDate(date),
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: TioSpacing.sm),
          Text(
            'Meal logging is not available yet.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
