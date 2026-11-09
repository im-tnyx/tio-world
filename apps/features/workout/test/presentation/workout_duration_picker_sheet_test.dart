import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/src/presentation/widgets/workout_duration_picker_sheet.dart';

Widget _buildWrapper(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark().copyWith(extensions: const [TioColors.dark]),
    home: Scaffold(body: child),
  );
}

void main() {
  group('WorkoutDurationPickerSheet', () {
    testWidgets('shows one finite wheel and rounds seconds to nearest minute',
        (tester) async {
      await tester.pumpWidget(
        _buildWrapper(
          const WorkoutDurationPickerSheet(
            initialDuration: Duration(hours: 1, minutes: 15, seconds: 30),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Workout Duration'), findsOneWidget);
      expect(
          find.byKey(const ValueKey('workout-duration-wheel')), findsOneWidget);
      expect(find.text('Hours'), findsNothing);
      expect(find.text('Minutes'), findsNothing);
      expect(find.text('Seconds'), findsNothing);
      expect(
        find.byKey(const ValueKey('workout-duration-selection-pill')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('workout-duration-option-76')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('workout-duration-picker-done')),
        findsOneWidget,
      );
    });

    testWidgets('formats boundary values and returns selected duration on Done',
        (tester) async {
      Duration? result;
      await tester.pumpWidget(
        _buildWrapper(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showWorkoutDurationPickerSheet(
                  context: context,
                  initialDuration: const Duration(hours: 1, minutes: 1),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('1h 1min'), findsWidgets);
      final wheel = find.byKey(const ValueKey('workout-duration-wheel'));
      final scrollable = find.descendant(
        of: wheel,
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('workout-duration-option-0')),
        250,
        scrollable: scrollable.first,
      );
      await tester.pumpAndSettle();
      expect(find.text('0min'), findsWidgets);
      await tester
          .tap(find.byKey(const ValueKey('workout-duration-picker-done')));
      await tester.pumpAndSettle();
      expect(result, Duration.zero);

      for (final (minutes, label) in <(int, String)>[
        (1, '1min'),
        (59, '59min'),
        (60, '1h 0min'),
        (61, '1h 1min'),
        (120, '2h 0min'),
        (300, '5h 0min'),
      ]) {
        await tester.pumpWidget(
          _buildWrapper(
            WorkoutDurationPickerSheet(
                initialDuration: Duration(minutes: minutes)),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(ValueKey('workout-duration-option-$minutes')),
          findsOneWidget,
          reason: '$minutes minutes should map to $label',
        );
        expect(find.text(label), findsWidgets);
      }
    });

    testWidgets('does not mutate duration on cancel and reopening restores it',
        (tester) async {
      var storedDuration = const Duration(minutes: 61);
      Future<void> openPicker(BuildContext context) async {
        final result = await showWorkoutDurationPickerSheet(
          context: context,
          initialDuration: storedDuration,
        );
        if (result != null) storedDuration = result;
      }

      await tester.pumpWidget(
        _buildWrapper(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => openPicker(context),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(storedDuration, const Duration(minutes: 61));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('workout-duration-option-61')),
        findsOneWidget,
      );
      expect(storedDuration, const Duration(minutes: 61));
    });

    testWidgets('shows values over five hours and requires an explicit change',
        (tester) async {
      Duration? result;
      await tester.pumpWidget(
        _buildWrapper(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showWorkoutDurationPickerSheet(
                  context: context,
                  initialDuration:
                      const Duration(hours: 6, minutes: 12, seconds: 20),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Current duration: 6h 12min 20sec'),
          findsOneWidget);
      expect(
        find.byKey(const ValueKey('workout-duration-option-300')),
        findsOneWidget,
      );
      await tester
          .tap(find.byKey(const ValueKey('workout-duration-picker-done')));
      await tester.pumpAndSettle();
      expect(result, isNull);

      final wheel = find.byKey(const ValueKey('workout-duration-wheel'));
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('workout-duration-option-299')),
        100,
        scrollable: find
            .descendant(
              of: wheel,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('workout-duration-picker-done')));
      await tester.pumpAndSettle();
      expect(result, const Duration(minutes: 299));
    });
  });
}
