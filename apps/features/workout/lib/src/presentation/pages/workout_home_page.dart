import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_core/core.dart';

import '../controllers/workout_date_controller.dart';

/// Workout root: the date calendar plus the Library entry.
///
/// This page owns date-navigation presentation state only. Domain-backed
/// workout decorations belong to later Workout slices. Library navigation is
/// supplied by the app shell through [onLibraryPressed].
class WorkoutHomePage extends ConsumerStatefulWidget {
  const WorkoutHomePage({
    required this.onLibraryPressed,
    super.key,
    this.resolvedFirstDayOfWeek,
  });

  final int? resolvedFirstDayOfWeek;

  /// Opens the canonical Workout Library.
  final VoidCallback onLibraryPressed;

  @override
  ConsumerState<WorkoutHomePage> createState() => _WorkoutHomePageState();
}

class _WorkoutHomePageState extends ConsumerState<WorkoutHomePage>
    with WidgetsBindingObserver {
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
      ref.read(workoutDateControllerProvider).refreshLocalDate();
      _scheduleMidnightRefresh();
      return;
    }

    _midnightTimer?.cancel();
    _midnightTimer = null;
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final delay =
        ref.read(workoutDateControllerProvider).durationUntilNextLocalMidnight;
    if (delay <= Duration.zero) return;

    _midnightTimer = Timer(delay, () {
      if (!mounted) return;
      ref.read(workoutDateControllerProvider).refreshLocalDate();
      _scheduleMidnightRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dates = ref.watch(workoutDateControllerProvider);

    // Scrolls so the expanded month grid and the Library entry never
    // overflow a compact viewport.
    return SingleChildScrollView(
      child: Column(
        children: [
          TioDateCalendar(
            controller: dates.calendarController,
            selectedDate: dates.selectedDate,
            localToday: dates.localToday,
            minDate: dates.minDate,
            maxDate: dates.maxDate,
            resolvedFirstDayOfWeek: widget.resolvedFirstDayOfWeek,
            onDateSelected: dates.select,
            onVisibleDateRangeChanged: dates.updateVisibleDateRange,
          ),
          // No top padding: the calendar already reserves a transparent band
          // below its surface for the expansion handle's hit target, and this
          // entry is interactive, so it must not overlap that band (the same
          // rule Meal Diary applies to its interactive surfaces).
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TioSpacing.lg,
              TioSpacing.none,
              TioSpacing.lg,
              TioSpacing.lg,
            ),
            child: TioGroupCard(
              children: [
                TioSettingsNavigationRow(
                  key: const ValueKey('workout-home-library-entry'),
                  leading: const TioSettingsLeadingIcon(
                    icon: Icons.folder_open_rounded,
                  ),
                  title: 'Library',
                  supportingText: 'Browse exercises',
                  onTap: widget.onLibraryPressed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
