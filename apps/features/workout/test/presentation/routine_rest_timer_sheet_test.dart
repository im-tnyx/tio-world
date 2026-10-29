import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/src/domain/models/routine_rest_timer_preset.dart';
import 'package:tio_feature_workout/src/presentation/library/routines/routine_rest_timer_sheet.dart';

void main() {
  Widget buildSheet({
    int? initialNormalRestSeconds,
    int? initialWarmUpRestSeconds,
    String? exerciseName,
    void Function(RoutineRestTimerPreset?)? onResult,
  }) {
    return MaterialApp(
      builder: (context, child) =>
          TioTheme(child: child ?? const SizedBox.shrink()),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                final result = await showRoutineRestTimerSheet(
                  context: context,
                  initialNormalRestSeconds: initialNormalRestSeconds,
                  initialWarmUpRestSeconds: initialWarmUpRestSeconds,
                  exerciseName: exerciseName,
                );
                onResult?.call(result);
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
      'renders Centered Rest Timer title, exercise name, Normal and Warm-up tabs, and Done button',
      (tester) async {
    RoutineRestTimerPreset? emitted;
    await tester.pumpWidget(
      buildSheet(
        initialNormalRestSeconds: 90,
        initialWarmUpRestSeconds: 45,
        exerciseName: 'Barbell Hip Thrust',
        onResult: (res) => emitted = res,
      ),
    );

    // Open sheet
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    // Verify Drag Handle
    expect(find.byKey(const ValueKey('routine-rest-timer-handle')), findsOneWidget);

    // Verify Title and Exercise Subtitle
    expect(find.text('Rest Timer'), findsOneWidget);
    expect(find.text('Barbell Hip Thrust'), findsOneWidget);

    // Verify Tabs
    expect(find.text('Normal set'), findsOneWidget);
    expect(find.text('Warm-up Set'), findsOneWidget);

    // Verify Single Wheel exists
    final wheel = find.byKey(const ValueKey('routine-rest-timer-wheel'));
    expect(wheel, findsOneWidget);

    // Verify selection pill exists
    expect(
      find.byKey(const ValueKey('routine-rest-timer-selection-pill')),
      findsOneWidget,
    );

    // Verify initial selection for 90s (index 18: '1m 30s')
    final scrollable = tester.widget<ListWheelScrollView>(wheel);
    final ctrl = scrollable.controller! as FixedExtentScrollController;
    expect(ctrl.selectedItem, 18);
    expect(find.text('1m 30s'), findsWidgets);

    // Switch tab to Warm-up Set
    await tester.tap(find.text('Warm-up Set'));
    await tester.pumpAndSettle();

    // Warm-up has 45s (index 9)
    expect(ctrl.selectedItem, 9);
    expect(find.text('45s'), findsWidgets);

    // Tap Done
    final doneBtn =
        find.byKey(const ValueKey('routine-rest-timer-done-button'));
    expect(doneBtn, findsOneWidget);
    await tester.tap(doneBtn);
    await tester.pumpAndSettle();

    expect(emitted, isNotNull);
    expect(emitted!.normalRestSeconds, 90);
    expect(emitted!.warmUpRestSeconds, 45);
  });

  testWidgets('selecting Off in wheel returns null duration on Done',
      (tester) async {
    RoutineRestTimerPreset? emitted;
    await tester.pumpWidget(
      buildSheet(
        initialNormalRestSeconds: 90,
        initialWarmUpRestSeconds: 45,
        onResult: (res) => emitted = res,
      ),
    );

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    // Scroll wheel to item 0 ('Off')
    final wheel = find.byKey(const ValueKey('routine-rest-timer-wheel'));
    final scrollable = tester.widget<ListWheelScrollView>(wheel);
    final ctrl = scrollable.controller! as FixedExtentScrollController;
    ctrl.jumpToItem(0);
    await tester.pumpAndSettle();

    expect(find.text('Off'), findsWidgets);

    // Tap Done
    await tester.tap(
      find.byKey(const ValueKey('routine-rest-timer-done-button')),
    );
    await tester.pumpAndSettle();

    expect(emitted, isNotNull);
    expect(emitted!.normalRestSeconds, isNull);
    expect(emitted!.warmUpRestSeconds, 45);
  });

  testWidgets('initially OFF category can be set to active duration',
      (tester) async {
    RoutineRestTimerPreset? emitted;
    await tester.pumpWidget(
      buildSheet(
        initialNormalRestSeconds: null,
        initialWarmUpRestSeconds: null,
        onResult: (res) => emitted = res,
      ),
    );

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    final wheel = find.byKey(const ValueKey('routine-rest-timer-wheel'));
    final scrollable = tester.widget<ListWheelScrollView>(wheel);
    final ctrl = scrollable.controller! as FixedExtentScrollController;
    expect(ctrl.selectedItem, 0); // 'Off'

    // Select 5m 0s (index 60 = 300s)
    ctrl.jumpToItem(60);
    await tester.pumpAndSettle();

    expect(find.text('5m 0s'), findsWidgets);

    // Tap Done
    await tester.tap(
      find.byKey(const ValueKey('routine-rest-timer-done-button')),
    );
    await tester.pumpAndSettle();

    expect(emitted, isNotNull);
    expect(emitted!.normalRestSeconds, 300);
    expect(emitted!.warmUpRestSeconds, isNull);
  });

  testWidgets('clamps initial duration exceeding 600s to maximum 600 seconds',
      (tester) async {
    RoutineRestTimerPreset? emitted;
    await tester.pumpWidget(
      buildSheet(
        initialNormalRestSeconds: 700,
        initialWarmUpRestSeconds: 45,
        onResult: (res) => emitted = res,
      ),
    );

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    final wheel = find.byKey(const ValueKey('routine-rest-timer-wheel'));
    final scrollable = tester.widget<ListWheelScrollView>(wheel);
    final ctrl = scrollable.controller! as FixedExtentScrollController;
    expect(ctrl.selectedItem, 120); // 120 * 5s = 600s ('10m 0s')

    expect(find.text('10m 0s'), findsWidgets);

    // Tap Done
    await tester.tap(
      find.byKey(const ValueKey('routine-rest-timer-done-button')),
    );
    await tester.pumpAndSettle();

    expect(emitted, isNotNull);
    expect(emitted!.normalRestSeconds, 600);
    expect(emitted!.warmUpRestSeconds, 45);
  });
}
