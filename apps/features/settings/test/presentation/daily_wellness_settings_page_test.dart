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

  testWidgets('DailyWellnessSettingsPage renders populated targets cleanly',
      (tester) async {
    const initial = WellnessTargetsData(
      dailySteps: 10000,
      waterMl: 2500,
      sleepTargetMinutes: 480,
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
    expect(find.text('DAILY SCHEDULE'), findsOneWidget);

    expect(find.text('10000 steps/day'), findsOneWidget);
    expect(find.text('2500 ml/day (2.5 L)'), findsOneWidget);
    expect(find.text('8 hrs'), findsOneWidget);
    expect(find.text('10:00 PM'), findsOneWidget);
    expect(find.text('6:30 AM'), findsOneWidget);

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

  testWidgets('DailyWellnessSettingsPage renders "Not set" when initial targets are null',
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

    expect(find.text('Not set'), findsNWidgets(5));
    final button =
        tester.widget<TioButton>(find.byKey(const ValueKey('daily-wellness-save')));
    expect(button.onPressed, isNull);
  });

  testWidgets('DailyWellnessSettingsPage displays water in fl oz when volumeUnit is flOz',
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

  testWidgets('Pristine editor rehydrates new initialTargets when provider updates and keeps Save disabled',
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
    var saveButton =
        tester.widget<TioButton>(find.byKey(const ValueKey('daily-wellness-save')));
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
    saveButton =
        tester.widget<TioButton>(find.byKey(const ValueKey('daily-wellness-save')));
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

    var saveButton =
        tester.widget<TioButton>(find.byKey(const ValueKey('daily-wellness-save')));
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

  testWidgets('Editing step goal updates value, enables save, and preserves untouched nulls',
      (tester) async {
    WellnessTargetsData? savedTargets;

    const initial = WellnessTargetsData(
      dailySteps: 8000,
      waterMl: null,
      sleepTargetMinutes: null,
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

    expect(find.text('Not set'), findsNWidgets(5));

    // Save should now be enabled because steps changed from 8000 -> null
    final saveButton =
        tester.widget<TioButton>(find.byKey(const ValueKey('daily-wellness-save')));
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

  testWidgets('Partial edit preserves all untouched populated values on save',
      (tester) async {
    WellnessTargetsData? savedTargets;

    const initial = WellnessTargetsData(
      dailySteps: 10000,
      waterMl: 3000,
      sleepTargetMinutes: 480,
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
    expect(savedTargets!.sleepTargetMinutes, 480); // Preserved!
    expect(savedTargets!.bedTimeMinutes, 1320); // Preserved!
    expect(savedTargets!.wakeTimeMinutes, 390); // Preserved!
  });

  testWidgets(
      'Provider refresh preserves only the edited field and adopts fresh canonical values for untouched fields',
      (tester) async {
    const targetsA = WellnessTargetsData(
      dailySteps: 8000,
      waterMl: 2000,
      sleepTargetMinutes: 480,
      bedTimeMinutes: 1320,
      wakeTimeMinutes: 390,
    );

    const targetsB = WellnessTargetsData(
      dailySteps: 12000,
      waterMl: 3500,
      sleepTargetMinutes: 510,
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
    expect(find.text('3500 ml/day (3.5 L)'), findsOneWidget);
    expect(find.text('8 hrs 30 mins'), findsOneWidget);
    expect(find.text(const TimeOfDay(hour: 22, minute: 30).format(
      tester.element(find.byType(DailyWellnessSettingsPage)),
    )), findsOneWidget);
    expect(find.text(const TimeOfDay(hour: 7, minute: 0).format(
      tester.element(find.byType(DailyWellnessSettingsPage)),
    )), findsOneWidget);

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

  testWidgets('Editing sleep goal saves expected minutes and preserves other fields',
      (tester) async {
    WellnessTargetsData? savedTargets;

    const initial = WellnessTargetsData(
      dailySteps: 10000,
      waterMl: 2500,
      sleepTargetMinutes: 480,
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

    await tester.tap(find.byKey(const ValueKey('daily-wellness-sleep-field')));
    await tester.pumpAndSettle();
    final sleepSliderRect = tester.getRect(find.byType(Slider));
    await tester.tapAt(
      Offset(sleepSliderRect.left + sleepSliderRect.width * 0.1,
          sleepSliderRect.center.dy),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set Goal'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('daily-wellness-save')));
    await tester.pumpAndSettle();

    expect(savedTargets, isNotNull);
    expect(savedTargets!.sleepTargetMinutes, isNot(480));
    expect(savedTargets!.sleepTargetMinutes! % 30, 0);
    expect(savedTargets!.dailySteps, 10000);
    expect(savedTargets!.waterMl, 2500);
    expect(savedTargets!.bedTimeMinutes, 1320);
    expect(savedTargets!.wakeTimeMinutes, 390);
  });

  testWidgets('Editing bedtime saves expected minutes since midnight',
      (tester) async {
    WellnessTargetsData? savedTargets;

    const initial = WellnessTargetsData(bedTimeMinutes: 1320); // 10:00 PM

    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: initial,
          volumeUnit: VolumeUnit.ml,
          onSave: (targets) async => savedTargets = targets,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('daily-wellness-bedtime-field')));
    await tester.pumpAndSettle();

    // Switch to text input entry mode to set a deterministic new time.
    await tester.tap(find.byTooltip('Switch to text input mode'));
    await tester.pumpAndSettle();

    final hourField = find.byType(TextFormField).first;
    final minuteField = find.byType(TextFormField).last;

    await tester.enterText(hourField, '9');
    await tester.enterText(minuteField, '15');
    // Initial time (10:00 PM) is already in the PM period; leave it as PM.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('9:15 PM'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('daily-wellness-save')));
    await tester.pumpAndSettle();

    expect(savedTargets, isNotNull);
    expect(savedTargets!.bedTimeMinutes, 21 * 60 + 15);
  });

  testWidgets('Editing wake time saves expected minutes since midnight',
      (tester) async {
    WellnessTargetsData? savedTargets;

    const initial = WellnessTargetsData(wakeTimeMinutes: 390); // 06:30 AM

    await tester.pumpWidget(
      buildApp(
        DailyWellnessSettingsPage(
          initialTargets: initial,
          volumeUnit: VolumeUnit.ml,
          onSave: (targets) async => savedTargets = targets,
        ),
      ),
    );

    await tester.ensureVisible(
        find.byKey(const ValueKey('daily-wellness-wake-time-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('daily-wellness-wake-time-field')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Switch to text input mode'));
    await tester.pumpAndSettle();

    final hourField = find.byType(TextFormField).first;
    final minuteField = find.byType(TextFormField).last;

    await tester.enterText(hourField, '7');
    await tester.enterText(minuteField, '45');
    // Initial time (6:30 AM) is already in the AM period; leave it as AM.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('7:45 AM'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('daily-wellness-save')));
    await tester.pumpAndSettle();

    expect(savedTargets, isNotNull);
    expect(savedTargets!.wakeTimeMinutes, 7 * 60 + 45);
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
                sleepTargetMinutes: 480,
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
