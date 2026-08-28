import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_progress/progress.dart';
import 'package:tio_feature_settings/settings.dart';

void main() {
  Widget buildApp(Widget child, {TioThemeMode mode = TioThemeMode.dark}) {
    return MaterialApp(
      builder: (context, appChild) => TioTheme(
        config: TioThemeConfig(mode: mode),
        child: appChild ?? const SizedBox.shrink(),
      ),
      home: child,
    );
  }

  String timeRange(WidgetTester tester, TimeOfDay bed, TimeOfDay wake) {
    final context = tester.element(find.byType(DailyWellnessSettingsPage));
    return '${bed.format(context)} - ${wake.format(context)}';
  }

  testWidgets('DailyWellnessSettingsPage renders populated targets cleanly',
      (tester) async {
    const initial = WellnessTargetsData(
      dailySteps: 10000,
      waterMl: 2500,
      bedTimeMinutes: 22 * 60, // 10:00 PM
      wakeTimeMinutes: 6 * 60 + 30, // 6:30 AM
    );

    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: initial,
          volumeUnit: VolumeUnit.ml,
          onSave: (_) async {},
        ),
      ),
    );

    expect(find.text('Daily Wellness'), findsOneWidget);
    expect(find.text('TARGETS'), findsOneWidget);
    expect(find.text('SLEEP'), findsOneWidget);
    expect(find.text('DAILY SCHEDULE'), findsNothing);

    expect(find.text('10000 steps/day'), findsOneWidget);
    expect(find.text('2500 ml/day (2.5 L)'), findsOneWidget);

    // Sleep duration (22:00 -> 6:30, wraps midnight) = 510 min = 8h 30m.
    expect(find.text('8h 30m'), findsOneWidget);
    expect(
      find.text(timeRange(
        tester,
        const TimeOfDay(hour: 22, minute: 0),
        const TimeOfDay(hour: 6, minute: 30),
      )),
      findsOneWidget,
    );

    // Duration sits on the SAME top row as the "Sleep Schedule" title, not
    // stacked as a third line underneath it.
    final titleY = tester.getCenter(find.text('Sleep Schedule')).dy;
    final durationY = tester.getCenter(find.text('8h 30m')).dy;
    expect((titleY - durationY).abs(), lessThan(2.0));

    // Sleep Goal / Bedtime / Wake Time no longer exist as independent rows.
    expect(find.text('Sleep Goal'), findsNothing);
    expect(find.byKey(const ValueKey('daily-wellness-sleep-field')),
        findsNothing);
    expect(find.byKey(const ValueKey('daily-wellness-bedtime-field')),
        findsNothing);
    expect(find.byKey(const ValueKey('daily-wellness-wake-time-field')),
        findsNothing);
    expect(find.byKey(const ValueKey('daily-wellness-sleep-schedule-field')),
        findsOneWidget);

    // Save button disabled initially because no changes
    final saveButtonFinder = find.byKey(const ValueKey('daily-wellness-save'));
    expect(saveButtonFinder, findsOneWidget);
    final button = tester.widget<TioButton>(saveButtonFinder);
    expect(button.onPressed, isNull);

    // Verify Glass Size is strictly absent
    for (final absent in [
      'Glass Size',
      'Default Glass Size',
      'glass_size',
      'Glass size',
    ]) {
      expect(find.text(absent), findsNothing, reason: absent);
    }
  });

  testWidgets(
      'DailyWellnessSettingsPage renders "Not set" when initial targets are null',
      (tester) async {
    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: null,
          volumeUnit: VolumeUnit.ml,
          onSave: (_) async {},
        ),
      ),
    );

    // Step Goal, Water Goal, Sleep Schedule duration. No subtitle range is
    // rendered when both Bedtime and Wake Time are unset.
    expect(find.text('Not set'), findsNWidgets(3));
    final button = tester
        .widget<TioButton>(find.byKey(const ValueKey('daily-wellness-save')));
    expect(button.onPressed, isNull);
  });

  testWidgets(
      'DailyWellnessSettingsPage displays water in fl oz when volumeUnit is flOz',
      (tester) async {
    const initial = WellnessTargetsData(waterMl: 2500);

    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: initial,
          volumeUnit: VolumeUnit.flOz,
          onSave: (_) async {},
        ),
      ),
    );

    expect(find.text('85 fl oz/day'), findsOneWidget);
  });

  testWidgets(
      'Pristine editor rehydrates new initialTargets when provider updates and keeps Save disabled',
      (tester) async {
    const targetsA = WellnessTargetsData(
      dailySteps: 8000,
      waterMl: 2000,
    );

    const targetsB = WellnessTargetsData(
      dailySteps: 12000,
      waterMl: 3500,
    );

    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: targetsA,
          volumeUnit: VolumeUnit.ml,
          onSave: (_) async {},
        ),
      ),
    );

    expect(find.text('8000 steps/day'), findsOneWidget);
    expect(find.text('2000 ml/day (2 L)'), findsOneWidget);
    var saveButton = tester
        .widget<TioButton>(find.byKey(const ValueKey('daily-wellness-save')));
    expect(saveButton.onPressed, isNull);

    // Parent provider updates with targetsB while user made no edits
    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: targetsB,
          volumeUnit: VolumeUnit.ml,
          onSave: (_) async {},
        ),
      ),
    );

    expect(find.text('12000 steps/day'), findsOneWidget);
    expect(find.text('3500 ml/day (3.5 L)'), findsOneWidget);
    saveButton = tester
        .widget<TioButton>(find.byKey(const ValueKey('daily-wellness-save')));
    expect(saveButton.onPressed, isNull);
  });

  testWidgets('Dirty editor preserves user edits across provider updates',
      (tester) async {
    const targetsA = WellnessTargetsData(
      dailySteps: 8000,
      waterMl: 2000,
    );

    const targetsB = WellnessTargetsData(
      dailySteps: 12000,
      waterMl: 3500,
    );

    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: targetsA,
          volumeUnit: VolumeUnit.ml,
          onSave: (_) async {},
        ),
      ),
    );

    // User clears step goal to make editor dirty
    await tester.tap(find.byKey(const ValueKey('daily-wellness-steps-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear Goal'));
    await tester.pumpAndSettle();

    var saveButton = tester
        .widget<TioButton>(find.byKey(const ValueKey('daily-wellness-save')));
    expect(saveButton.onPressed, isNotNull);

    // Parent rebuilds with targetsB while user is dirty
    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: targetsB,
          volumeUnit: VolumeUnit.ml,
          onSave: (_) async {},
        ),
      ),
    );

    // User draft is preserved (steps remains null/Not set, not overwritten by 12000)
    expect(find.text('12000 steps/day'), findsNothing);
  });

  testWidgets(
      'Editing step goal updates value, enables save, and preserves untouched nulls',
      (tester) async {
    WellnessTargetsData? savedTargets;

    const initial = WellnessTargetsData(
      dailySteps: 8000,
      waterMl: null,
      bedTimeMinutes: null,
      wakeTimeMinutes: null,
    );

    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: initial,
          volumeUnit: VolumeUnit.ml,
          onSave: (targets) async => savedTargets = targets,
        ),
      ),
    );

    // Tap Step Goal row to open editor
    await tester.tap(find.byKey(const ValueKey('daily-wellness-steps-field')));
    await tester.pumpAndSettle();

    expect(find.text('Daily Step Goal'), findsOneWidget);
    await tester.tap(find.text('Set Goal'));
    await tester.pumpAndSettle();

    // Now tap and clear
    await tester.tap(find.byKey(const ValueKey('daily-wellness-steps-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear Goal'));
    await tester.pumpAndSettle();

    // Steps, Water, Sleep Schedule duration all "Not set".
    expect(find.text('Not set'), findsNWidgets(3));

    // Save should now be enabled because steps changed from 8000 -> null
    final saveButton = tester
        .widget<TioButton>(find.byKey(const ValueKey('daily-wellness-save')));
    expect(saveButton.onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('daily-wellness-save')));
    await tester.pumpAndSettle();

    expect(savedTargets, isNotNull);
    expect(savedTargets!.dailySteps, isNull);
    expect(savedTargets!.waterMl, isNull);
    expect(savedTargets!.sleepTargetMinutes, isNull);
    expect(savedTargets!.bedTimeMinutes, isNull);
    expect(savedTargets!.wakeTimeMinutes, isNull);
  });

  testWidgets('Partial edit preserves untouched populated values on save',
      (tester) async {
    WellnessTargetsData? savedTargets;

    const initial = WellnessTargetsData(
      dailySteps: 10000,
      waterMl: 3000,
      bedTimeMinutes: 1320, // 22:00
      wakeTimeMinutes: 390, // 06:30
    );

    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: initial,
          volumeUnit: VolumeUnit.ml,
          onSave: (targets) async => savedTargets = targets,
        ),
      ),
    );

    // Edit water goal
    await tester.tap(find.byKey(const ValueKey('daily-wellness-water-field')));
    await tester.pumpAndSettle();
    expect(find.text('Daily Water Goal'), findsOneWidget);

    await tester.tap(find.text('Clear Goal'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('daily-wellness-save')));
    await tester.pumpAndSettle();

    expect(savedTargets, isNotNull);
    expect(savedTargets!.dailySteps, 10000); // Preserved!
    expect(savedTargets!.waterMl, isNull); // Cleared!
    // Bedtime/Wake Time untouched -> derived duration = 510 (8h 30m).
    expect(savedTargets!.sleepTargetMinutes, 510);
    expect(savedTargets!.bedTimeMinutes, 1320); // Preserved!
    expect(savedTargets!.wakeTimeMinutes, 390); // Preserved!
  });

  testWidgets(
      'Provider refresh preserves only the edited field and adopts fresh canonical values for untouched fields',
      (tester) async {
    const targetsA = WellnessTargetsData(
      dailySteps: 8000,
      waterMl: 2000,
      bedTimeMinutes: 1320,
      wakeTimeMinutes: 390,
    );

    const targetsB = WellnessTargetsData(
      dailySteps: 12000,
      waterMl: 3500,
      bedTimeMinutes: 1350,
      wakeTimeMinutes: 420,
    );

    WellnessTargetsData? savedTargets;

    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: targetsA,
          volumeUnit: VolumeUnit.ml,
          onSave: (targets) async => savedTargets = targets,
        ),
      ),
    );

    // User edits ONLY the step goal. Tap near the low end of the slider
    // track so the resulting value is deterministically distinct from both
    // the original canonical value (8000) and the refreshed one (12000).
    await tester.tap(find.byKey(const ValueKey('daily-wellness-steps-field')));
    await tester.pumpAndSettle();
    final stepsSliderRect = tester.getRect(find.byType(Slider));
    await tester.tapAt(
      Offset(stepsSliderRect.left + stepsSliderRect.width * 0.1,
          stepsSliderRect.center.dy),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set Goal'));
    await tester.pumpAndSettle();

    final editedSteps = tester
        .widget<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('daily-wellness-steps-field')),
            matching: find.textContaining('steps/day'),
          ),
        )
        .data!;
    expect(editedSteps, isNot('8000 steps/day'));

    // Provider refreshes to targetsB while the step edit is still a draft.
    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: targetsB,
          volumeUnit: VolumeUnit.ml,
          onSave: (targets) async => savedTargets = targets,
        ),
      ),
    );

    // Edited field keeps the user's draft, not targetsB's steps value.
    expect(find.text('12000 steps/day'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('daily-wellness-steps-field')),
        matching: find.text(editedSteps),
      ),
      findsOneWidget,
    );

    // Untouched fields adopt the fresh canonical values from targetsB.
    // Schedule 22:30 -> 07:00 wraps to 510 min = 8h 30m either way.
    expect(find.text('3500 ml/day (3.5 L)'), findsOneWidget);
    expect(find.text('8h 30m'), findsOneWidget);
    expect(
      find.text(timeRange(
        tester,
        const TimeOfDay(hour: 22, minute: 30),
        const TimeOfDay(hour: 7, minute: 0),
      )),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('daily-wellness-save')));
    await tester.pumpAndSettle();

    expect(savedTargets, isNotNull);
    expect(savedTargets!.dailySteps, isNot(8000));
    expect(savedTargets!.dailySteps, isNot(12000));
    expect(savedTargets!.waterMl, 3500);
    expect(savedTargets!.sleepTargetMinutes, 510);
    expect(savedTargets!.bedTimeMinutes, 1350);
    expect(savedTargets!.wakeTimeMinutes, 420);
  });

  testWidgets(
      'A dirty field that converges with a refreshed canonical value stops blocking future refreshes',
      (tester) async {
    const targetsA = WellnessTargetsData(
      dailySteps: 8000,
      waterMl: 2000,
    );

    // Canonical Steps happens to catch up to exactly the user's draft.
    const targetsB = WellnessTargetsData(
      dailySteps: 10000,
      waterMl: 3000,
    );

    const targetsC = WellnessTargetsData(
      dailySteps: 12000,
      waterMl: 3500,
    );

    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: targetsA,
          volumeUnit: VolumeUnit.ml,
          onSave: (_) async {},
        ),
      ),
    );

    // User edits Steps to exactly the midpoint of the slider range
    // (2000-18000), which lands precisely on 10000.
    await tester.tap(find.byKey(const ValueKey('daily-wellness-steps-field')));
    await tester.pumpAndSettle();
    final stepsSliderRect = tester.getRect(find.byType(Slider));
    await tester.tapAt(
      Offset(stepsSliderRect.left + stepsSliderRect.width * 0.5,
          stepsSliderRect.center.dy),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set Goal'));
    await tester.pumpAndSettle();

    expect(find.text('10000 steps/day'), findsOneWidget);
    var saveButton = tester
        .widget<TioButton>(find.byKey(const ValueKey('daily-wellness-save')));
    expect(saveButton.onPressed, isNotNull);

    // Provider refreshes to targetsB, whose canonical Steps now equals the
    // user's draft. The Steps field should converge (no longer dirty) and
    // Water should hydrate to the fresh canonical value; Save disables.
    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: targetsB,
          volumeUnit: VolumeUnit.ml,
          onSave: (_) async {},
        ),
      ),
    );

    expect(find.text('10000 steps/day'), findsOneWidget);
    expect(find.text('3000 ml/day (3 L)'), findsOneWidget);
    saveButton = tester
        .widget<TioButton>(find.byKey(const ValueKey('daily-wellness-save')));
    expect(saveButton.onPressed, isNull);

    // Provider refreshes again to targetsC. Because Steps converged back to
    // non-dirty at B, it must now hydrate to C rather than staying latched
    // at the old 10000 draft.
    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: targetsC,
          volumeUnit: VolumeUnit.ml,
          onSave: (_) async {},
        ),
      ),
    );

    expect(find.text('12000 steps/day'), findsOneWidget);
    expect(find.text('3500 ml/day (3.5 L)'), findsOneWidget);
    saveButton = tester
        .widget<TioButton>(find.byKey(const ValueKey('daily-wellness-save')));
    expect(saveButton.onPressed, isNull);
  });

  testWidgets('Editing water goal saves canonical ml regardless of display unit',
      (tester) async {
    WellnessTargetsData? savedTargets;

    const initial = WellnessTargetsData(waterMl: 2000);

    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: initial,
          volumeUnit: VolumeUnit.flOz,
          onSave: (targets) async => savedTargets = targets,
        ),
      ),
    );

    // Presentation renders in fl oz while canonical storage stays ml.
    expect(find.text('68 fl oz/day'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('daily-wellness-water-field')));
    await tester.pumpAndSettle();
    final waterSliderRect = tester.getRect(find.byType(Slider));
    await tester.tapAt(
      Offset(waterSliderRect.left + waterSliderRect.width * 0.9,
          waterSliderRect.center.dy),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set Goal'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('daily-wellness-save')));
    await tester.pumpAndSettle();

    expect(savedTargets, isNotNull);
    expect(savedTargets!.waterMl, isNot(2000));
    expect(savedTargets!.waterMl! % 100, 0);
  });

  // ── Sleep Schedule (derived duration) ──────────────────────────────────

  for (final testCase in const [
    (bed: TimeOfDay(hour: 23, minute: 0), wake: TimeOfDay(hour: 7, minute: 0), label: '8h'),
    (bed: TimeOfDay(hour: 22, minute: 30), wake: TimeOfDay(hour: 6, minute: 30), label: '8h'),
    (bed: TimeOfDay(hour: 0, minute: 30), wake: TimeOfDay(hour: 8, minute: 0), label: '7h 30m'),
    (bed: TimeOfDay(hour: 23, minute: 15), wake: TimeOfDay(hour: 6, minute: 45), label: '7h 30m'),
    (bed: TimeOfDay(hour: 23, minute: 42), wake: TimeOfDay(hour: 0, minute: 30), label: '48 min'),
  ]) {
    testWidgets(
        'Sleep Schedule computes cross-midnight-safe duration for ${testCase.bed.hour}:${testCase.bed.minute} -> ${testCase.wake.hour}:${testCase.wake.minute}',
        (tester) async {
      final initial = WellnessTargetsData(
        bedTimeMinutes: testCase.bed.hour * 60 + testCase.bed.minute,
        wakeTimeMinutes: testCase.wake.hour * 60 + testCase.wake.minute,
      );

      await tester.pumpWidget(
        buildApp(
          DailyWellnessSettingsPage(
            initialTargets: initial,
            volumeUnit: VolumeUnit.ml,
            onSave: (_) async {},
          ),
        ),
      );

      expect(find.text(testCase.label), findsOneWidget);
      expect(
        find.text(timeRange(tester, testCase.bed, testCase.wake)),
        findsOneWidget,
      );
    });
  }

  testWidgets(
      'Null Sleep Schedule shows Not set and keeps Save disabled until a real change',
      (tester) async {
    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: const WellnessTargetsData(dailySteps: 8000),
          volumeUnit: VolumeUnit.ml,
          onSave: (_) async {},
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('daily-wellness-sleep-schedule-field')),
        matching: find.text('Not set'),
      ),
      findsOneWidget,
    );

    final saveButton = tester
        .widget<TioButton>(find.byKey(const ValueKey('daily-wellness-save')));
    expect(saveButton.onPressed, isNull);
  });

  testWidgets(
      'Partial legacy schedule (only Bedtime known) shows the available time without fabricating the missing side',
      (tester) async {
    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: const WellnessTargetsData(bedTimeMinutes: 23 * 60),
          volumeUnit: VolumeUnit.ml,
          onSave: (_) async {},
        ),
      ),
    );

    // Duration cannot be derived from a single known time.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('daily-wellness-sleep-schedule-field')),
        matching: find.text('Not set'),
      ),
      findsOneWidget,
    );

    expect(
      find.text(
        '${const TimeOfDay(hour: 23, minute: 0).format(tester.element(find.byType(DailyWellnessSettingsPage)))} - Not set',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'Sleep Schedule bottom sheet renders large time values, the timeline, and both draggable handles',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      const initial = WellnessTargetsData(
        bedTimeMinutes: 23 * 60,
        wakeTimeMinutes: 7 * 60,
      );

      await tester.pumpWidget(
        buildApp(
          DailyWellnessSettingsPage(
            initialTargets: initial,
            volumeUnit: VolumeUnit.ml,
            onSave: (_) async {},
          ),
        ),
      );

      await tester.tap(
          find.byKey(const ValueKey('daily-wellness-sleep-schedule-field')));
      await tester.pumpAndSettle();

      expect(find.text('Bedtime'), findsOneWidget);
      expect(find.text('Wake Time'), findsOneWidget);
      expect(
        find.text(const TimeOfDay(hour: 23, minute: 0)
            .format(tester.element(find.byType(DailyWellnessSettingsPage)))),
        findsOneWidget,
      );
      expect(
        find.text(const TimeOfDay(hour: 7, minute: 0)
            .format(tester.element(find.byType(DailyWellnessSettingsPage)))),
        findsOneWidget,
      );
      expect(find.text('8h planned sleep'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('sleep-schedule-timeline-track')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Bedtime handle'), findsOneWidget);
      expect(find.bySemanticsLabel('Wake time handle'), findsOneWidget);

      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
      'Sleep Schedule bottom sheet sets Bedtime and Wake Time together and saves the derived duration',
      (tester) async {
    WellnessTargetsData? savedTargets;

    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: const WellnessTargetsData(),
          volumeUnit: VolumeUnit.ml,
          onSave: (targets) async => savedTargets = targets,
        ),
      ),
    );

    await tester.tap(
        find.byKey(const ValueKey('daily-wellness-sleep-schedule-field')));
    await tester.pumpAndSettle();
    expect(find.text('Sleep Schedule'), findsWidgets);
    expect(find.text('Bedtime'), findsOneWidget);
    expect(find.text('Wake Time'), findsOneWidget);

    // Set Bedtime to 11:00 PM via the existing native time picker.
    await tester.tap(find.text('Bedtime'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Switch to text input mode'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '11');
    await tester.enterText(find.byType(TextFormField).last, '00');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Set Wake Time to 7:00 AM.
    await tester.tap(find.text('Wake Time'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Switch to text input mode'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '7');
    await tester.enterText(find.byType(TextFormField).last, '00');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Live preview inside the sheet reflects the derived duration.
    expect(find.text('8h planned sleep'), findsOneWidget);

    await tester.tap(find.text('Save Schedule'));
    await tester.pumpAndSettle();

    expect(find.text('8h'), findsOneWidget);
    expect(
      find.text(timeRange(
        tester,
        const TimeOfDay(hour: 23, minute: 0),
        const TimeOfDay(hour: 7, minute: 0),
      )),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('daily-wellness-save')));
    await tester.pumpAndSettle();

    expect(savedTargets, isNotNull);
    expect(savedTargets!.bedTimeMinutes, 23 * 60);
    expect(savedTargets!.wakeTimeMinutes, 7 * 60);
    expect(savedTargets!.sleepTargetMinutes, 8 * 60);
  });

  testWidgets('Clear Schedule clears both Bedtime and Wake Time together',
      (tester) async {
    WellnessTargetsData? savedTargets;

    const initial = WellnessTargetsData(
      bedTimeMinutes: 1320,
      wakeTimeMinutes: 390,
    );

    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: initial,
          volumeUnit: VolumeUnit.ml,
          onSave: (targets) async => savedTargets = targets,
        ),
      ),
    );

    await tester.tap(
        find.byKey(const ValueKey('daily-wellness-sleep-schedule-field')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clear Schedule'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Schedule'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('daily-wellness-sleep-schedule-field')),
        matching: find.text('Not set'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('daily-wellness-save')));
    await tester.pumpAndSettle();

    expect(savedTargets, isNotNull);
    expect(savedTargets!.bedTimeMinutes, isNull);
    expect(savedTargets!.wakeTimeMinutes, isNull);
    expect(savedTargets!.sleepTargetMinutes, isNull);
  });

  testWidgets(
      'Dismissing the Sleep Schedule sheet without Save Schedule leaves the page unchanged',
      (tester) async {
    const initial = WellnessTargetsData(
      bedTimeMinutes: 1320, // 10:00 PM
      wakeTimeMinutes: 390, // 6:30 AM
    );

    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: initial,
          volumeUnit: VolumeUnit.ml,
          onSave: (_) async {},
        ),
      ),
    );

    await tester.tap(
        find.byKey(const ValueKey('daily-wellness-sleep-schedule-field')));
    await tester.pumpAndSettle();

    // Change Bedtime inside the sheet, but never tap Save Schedule.
    await tester.tap(find.text('Bedtime'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Switch to text input mode'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '6');
    await tester.enterText(find.byType(TextFormField).last, '00');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Dismiss the sheet by tapping the barrier instead of Save Schedule.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // Page still shows the original, untouched schedule.
    expect(find.text('8h 30m'), findsOneWidget);
    expect(
      find.text(timeRange(
        tester,
        const TimeOfDay(hour: 22, minute: 0),
        const TimeOfDay(hour: 6, minute: 30),
      )),
      findsOneWidget,
    );

    final saveButton = tester
        .widget<TioButton>(find.byKey(const ValueKey('daily-wellness-save')));
    expect(saveButton.onPressed, isNull);
  });

  testWidgets(
      'Editing only Step Goal reconciles a stale legacy sleepTargetMinutes to the real schedule duration',
      (tester) async {
    WellnessTargetsData? savedTargets;

    // sleepTargetMinutes is a stale/inconsistent legacy value that does not
    // match the real 23:00 -> 08:00 schedule (whose real duration is 540
    // minutes, not 480).
    const initial = WellnessTargetsData(
      dailySteps: 8000,
      bedTimeMinutes: 23 * 60,
      wakeTimeMinutes: 8 * 60,
      sleepTargetMinutes: 480,
    );

    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: initial,
          volumeUnit: VolumeUnit.ml,
          onSave: (targets) async => savedTargets = targets,
        ),
      ),
    );

    // The page never trusted the stale 480 in the first place.
    expect(find.text('9h'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('daily-wellness-steps-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear Goal'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('daily-wellness-save')));
    await tester.pumpAndSettle();

    expect(savedTargets, isNotNull);
    expect(savedTargets!.dailySteps, isNull);
    expect(savedTargets!.bedTimeMinutes, 23 * 60);
    expect(savedTargets!.wakeTimeMinutes, 8 * 60);
    expect(savedTargets!.sleepTargetMinutes, 9 * 60);
  });

  // The timeline is displayed 20:00 -> next 20:00; this mirrors the
  // production _fractionOf mapping so drag targets land exactly where the
  // widget itself expects them, independent of any particular pixel width.
  double timelineFraction(TimeOfDay time) {
    const timelineStartMinutes = 20 * 60;
    final minuteOfDay = time.hour * 60 + time.minute;
    return ((minuteOfDay - timelineStartMinutes + 1440) % 1440) / 1440;
  }

  testWidgets(
      'Dragging the Bedtime handle updates Bedtime live and leaves Wake Time untouched',
      (tester) async {
    const initial = WellnessTargetsData(
      bedTimeMinutes: 23 * 60, // 11:00 PM
      wakeTimeMinutes: 7 * 60, // 7:00 AM
    );

    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: initial,
          volumeUnit: VolumeUnit.ml,
          onSave: (_) async {},
        ),
      ),
    );

    await tester.tap(
        find.byKey(const ValueKey('daily-wellness-sleep-schedule-field')));
    await tester.pumpAndSettle();

    final trackRect = tester
        .getRect(find.byKey(const ValueKey('sleep-schedule-timeline-track')));
    final startX = trackRect.left +
        trackRect.width * timelineFraction(const TimeOfDay(hour: 23, minute: 0));
    final endX = trackRect.left +
        trackRect.width * timelineFraction(const TimeOfDay(hour: 22, minute: 0));

    await tester.dragFrom(
      Offset(startX, trackRect.center.dy),
      Offset(endX - startX, 0),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(DailyWellnessSettingsPage));
    expect(
      find.text(const TimeOfDay(hour: 22, minute: 0).format(context)),
      findsOneWidget,
    );
    // Wake Time untouched by the Bedtime drag.
    expect(
      find.text(const TimeOfDay(hour: 7, minute: 0).format(context)),
      findsOneWidget,
    );
    // 22:00 -> 07:00 = 9h.
    expect(find.text('9h planned sleep'), findsOneWidget);

    // Nothing commits to the page until Save Schedule is tapped.
    expect(find.text('8h 30m'), findsNothing);
  });

  testWidgets(
      'Dragging the Wake Time handle to 08:00 updates the preview to 9h and saves 540 minutes',
      (tester) async {
    WellnessTargetsData? savedTargets;

    const initial = WellnessTargetsData(
      bedTimeMinutes: 23 * 60, // 11:00 PM
      wakeTimeMinutes: 7 * 60, // 7:00 AM
    );

    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: initial,
          volumeUnit: VolumeUnit.ml,
          onSave: (targets) async => savedTargets = targets,
        ),
      ),
    );

    await tester.tap(
        find.byKey(const ValueKey('daily-wellness-sleep-schedule-field')));
    await tester.pumpAndSettle();

    final trackRect = tester
        .getRect(find.byKey(const ValueKey('sleep-schedule-timeline-track')));
    final startX = trackRect.left +
        trackRect.width * timelineFraction(const TimeOfDay(hour: 7, minute: 0));
    final endX = trackRect.left +
        trackRect.width * timelineFraction(const TimeOfDay(hour: 8, minute: 0));

    await tester.dragFrom(
      Offset(startX, trackRect.center.dy),
      Offset(endX - startX, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('9h planned sleep'), findsOneWidget);

    await tester.tap(find.text('Save Schedule'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('daily-wellness-save')));
    await tester.pumpAndSettle();

    expect(savedTargets, isNotNull);
    expect(savedTargets!.bedTimeMinutes, 23 * 60);
    expect(savedTargets!.wakeTimeMinutes, 8 * 60);
    expect(savedTargets!.sleepTargetMinutes, 9 * 60);
  });

  testWidgets(
      'Dragging a handle snaps the resulting time to the nearest 15-minute increment',
      (tester) async {
    WellnessTargetsData? savedTargets;

    const initial = WellnessTargetsData(
      bedTimeMinutes: 23 * 60,
      wakeTimeMinutes: 7 * 60,
    );

    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: initial,
          volumeUnit: VolumeUnit.ml,
          onSave: (targets) async => savedTargets = targets,
        ),
      ),
    );

    await tester.tap(
        find.byKey(const ValueKey('daily-wellness-sleep-schedule-field')));
    await tester.pumpAndSettle();

    final trackRect = tester
        .getRect(find.byKey(const ValueKey('sleep-schedule-timeline-track')));
    final startX = trackRect.left +
        trackRect.width * timelineFraction(const TimeOfDay(hour: 7, minute: 0));
    // 08:08 is not on a 15-minute boundary; nearest boundary is 08:15.
    final endX = trackRect.left +
        trackRect.width * timelineFraction(const TimeOfDay(hour: 8, minute: 8));

    await tester.dragFrom(
      Offset(startX, trackRect.center.dy),
      Offset(endX - startX, 0),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Schedule'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('daily-wellness-save')));
    await tester.pumpAndSettle();

    expect(savedTargets, isNotNull);
    expect(savedTargets!.wakeTimeMinutes! % 15, 0);
    expect(savedTargets!.wakeTimeMinutes, 8 * 60 + 15);
  });

  testWidgets('Double tap on Save cannot trigger a second onSave call',
      (tester) async {
    var saveCalls = 0;
    final saveCompleter = Completer<void>();

    const initial = WellnessTargetsData(dailySteps: 5000);

    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: initial,
          volumeUnit: VolumeUnit.ml,
          onSave: (targets) async {
            saveCalls++;
            await saveCompleter.future;
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('daily-wellness-steps-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear Goal'));
    await tester.pumpAndSettle();

    // Fire two taps before the pending save resolves.
    await tester.tap(find.byKey(const ValueKey('daily-wellness-save')));
    await tester.tap(find.byKey(const ValueKey('daily-wellness-save')));
    await tester.pump();

    expect(saveCalls, 1);

    saveCompleter.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('Successful save awaits onSave before the page pops',
      (tester) async {
    final saveCompleter = Completer<void>();
    var poppedBeforeCompletion = false;

    const initial = WellnessTargetsData(dailySteps: 5000);

    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: initial,
          volumeUnit: VolumeUnit.ml,
          onSave: (_) async => saveCompleter.future,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('daily-wellness-steps-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear Goal'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('daily-wellness-save')));
    await tester.pump();

    // Page still present; save is still pending.
    poppedBeforeCompletion =
        find.byKey(const ValueKey('daily-wellness-save')).evaluate().isEmpty;
    expect(poppedBeforeCompletion, isFalse);

    saveCompleter.complete();
    await tester.pumpAndSettle();

    // Page is gone only after the save resolved successfully.
    expect(find.byKey(const ValueKey('daily-wellness-save')), findsNothing);
  });

  testWidgets('Save failure displays error and leaves screen retryable',
      (tester) async {
    var saveAttempts = 0;

    const initial = WellnessTargetsData(dailySteps: 5000);

    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: initial,
          volumeUnit: VolumeUnit.ml,
          onSave: (targets) async {
            saveAttempts++;
            throw Exception('Network error');
          },
        ),
      ),
    );

    // Edit step goal
    await tester.tap(find.byKey(const ValueKey('daily-wellness-steps-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear Goal'));
    await tester.pumpAndSettle();

    // Tap Save
    await tester.tap(find.byKey(const ValueKey('daily-wellness-save')));
    await tester.pumpAndSettle();

    expect(saveAttempts, 1);
    expect(find.byKey(const ValueKey('daily-wellness-save-error')), findsOneWidget);
    expect(find.text('Could not save your wellness targets. Please try again.'),
        findsOneWidget);

    // Retryable
    final retryButton =
        tester.widget<TioButton>(find.byKey(const ValueKey('daily-wellness-save')));
    expect(retryButton.onPressed, isNotNull);
  });

  for (final mode in [TioThemeMode.light, TioThemeMode.dark]) {
    for (final width in [390.0, 320.0]) {
      testWidgets('DailyWellnessSettingsPage renders safely at $mode/$width',
          (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, appChild) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(width == 320 ? 1.6 : 1),
              ),
              child: TioTheme(
                config: TioThemeConfig(mode: mode),
                child: appChild!,
              ),
            ),
            home: DailyWellnessSettingsPage(
              initialTargets: const WellnessTargetsData(
                dailySteps: 10000,
                waterMl: 2500,
                bedTimeMinutes: 1320,
                wakeTimeMinutes: 390,
              ),
              onSave: (_) async {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Daily Wellness'), findsOneWidget);
        expect(find.byKey(const ValueKey('daily-wellness-save')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
