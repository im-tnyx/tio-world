import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_core/core.dart';

import '../controllers/workout_date_controller.dart';
import '../widgets/workout_play_action.dart';

/// Workout root: the date calendar plus the Library entry.
///
/// This page owns date-navigation presentation state only. Domain-backed
/// workout decorations belong to later Workout slices. Library navigation is
/// supplied by the app shell through [onLibraryPressed].
class WorkoutHomePage extends ConsumerStatefulWidget {
  const WorkoutHomePage({
    required this.onLibraryPressed,
    super.key,
    this.onPlayPressed,
    this.resolvedFirstDayOfWeek,
  });

  final int? resolvedFirstDayOfWeek;

  /// Opens the canonical Workout Library.
  final VoidCallback onLibraryPressed;

  /// Opens the UI-only Active Workout entry; app composition owns navigation.
  final VoidCallback? onPlayPressed;

  @override
  ConsumerState<WorkoutHomePage> createState() => _WorkoutHomePageState();
}

class _WorkoutHomePageState extends ConsumerState<WorkoutHomePage>
    with WidgetsBindingObserver {
  Timer? _midnightTimer;
  bool _isCalendarExpanded = false;

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
    return Stack(
      fit: StackFit.expand,
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(
            bottom: TioSize.dp56 + TioSpacing.xl * 2,
          ),
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
            onDisplayModeChanged: (mode) {
              if (_isCalendarExpanded != mode.isMonth) {
                setState(() => _isCalendarExpanded = mode.isMonth);
              }
            },
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
        ),
        // Mirrors Nutrition's themed 56dp action and month-expansion safety.
        if (widget.onPlayPressed != null && !_isCalendarExpanded)
          Positioned.fill(
            child: SafeArea(
              child: Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: Padding(
                  padding: const EdgeInsets.all(TioSpacing.xl),
                  child: WorkoutPlayAction(
                    key: const ValueKey('workout-home-play-action'),
                    onPressed: widget.onPlayPressed!,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
