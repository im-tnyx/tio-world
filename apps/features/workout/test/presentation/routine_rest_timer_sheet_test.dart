import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/src/domain/models/routine_rest_timer_preset.dart';
import 'package:tio_feature_workout/src/presentation/library/routines/routine_rest_timer_sheet.dart';

void main() {
  Widget buildSheet({
    int? initialNormalRestSeconds,
    int? initialWarmUpRestSeconds,
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

  testWidgets('renders Normal and Warm-up tabs with initial values and Done button',
      (tester) async {
    RoutineRestTimerPreset? emitted;
    await tester.pumpWidget(
      buildSheet(
        initialNormalRestSeconds: 90,
        initialWarmUpRestSeconds: 45,
        onResult: (res) => emitted = res,
      ),
    );

    // Open sheet
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    // Verify Title and Tabs
    expect(find.text('Rest Timer'), findsOneWidget);
    expect(find.text('Normal set'), findsOneWidget);
    expect(find.text('Warm-up Set'), findsOneWidget);
    expect(find.text('Normal Rest Timer'), findsOneWidget);
    expect(find.text('1min 30s'), findsOneWidget);

    // Switch is ON
    final toggle = find.byKey(const ValueKey('routine-rest-timer-switch'));
    expect(toggle, findsOneWidget);
    expect(tester.widget<Switch>(toggle).value, isTrue);

    // Switch tab to Warm-up Set
    await tester.tap(find.text('Warm-up Set'));
    await tester.pumpAndSettle();

    expect(find.text('Warm-up Rest Timer'), findsOneWidget);
    expect(find.text('45s'), findsOneWidget);
    expect(tester.widget<Switch>(toggle).value, isTrue);

    // Tap Done
    final doneBtn = find.byKey(const ValueKey('routine-rest-timer-done-button'));
    expect(doneBtn, findsOneWidget);
    await tester.tap(doneBtn);
    await tester.pumpAndSettle();

    expect(emitted, isNotNull);
    expect(emitted!.normalRestSeconds, 90);
    expect(emitted!.warmUpRestSeconds, 45);
  });

  testWidgets('can toggle category OFF and Done returns null duration',
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

    // Toggle Normal to OFF
    final toggle = find.byKey(const ValueKey('routine-rest-timer-switch'));
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(find.text('OFF'), findsOneWidget);
    expect(find.text('Timer is OFF for this category.\nTurn on the switch to set a duration.'), findsOneWidget);

    // Done
    await tester.tap(find.byKey(const ValueKey('routine-rest-timer-done-button')));
    await tester.pumpAndSettle();

    expect(emitted, isNotNull);
    expect(emitted!.normalRestSeconds, isNull);
    expect(emitted!.warmUpRestSeconds, 45);
  });

  testWidgets('initially OFF category can be toggled ON', (tester) async {
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

    // Normal is initially OFF
    expect(find.text('OFF'), findsOneWidget);

    // Toggle Normal to ON
    final toggle = find.byKey(const ValueKey('routine-rest-timer-switch'));
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    // Now it is ON with default duration
    expect(tester.widget<Switch>(toggle).value, isTrue);
    expect(find.byKey(const ValueKey('routine-rest-timer-minutes-wheel')), findsOneWidget);
    expect(find.byKey(const ValueKey('routine-rest-timer-seconds-wheel')), findsOneWidget);

    // Done
    await tester.tap(find.byKey(const ValueKey('routine-rest-timer-done-button')));
    await tester.pumpAndSettle();

    expect(emitted, isNotNull);
    expect(emitted!.normalRestSeconds, isNotNull);
    expect(emitted!.warmUpRestSeconds, isNull);
  });
}
