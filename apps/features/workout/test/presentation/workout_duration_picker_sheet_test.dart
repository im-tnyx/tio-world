import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/src/presentation/widgets/workout_duration_picker_sheet.dart';

Widget _buildWrapper(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark().copyWith(
      extensions: const [
        TioColors.dark,
      ],
    ),
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  group('WorkoutDurationPickerSheet', () {
    testWidgets('renders title, column headers, 3 wheels and Done button',
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
      expect(find.text('Hours'), findsOneWidget);
      expect(find.text('Minutes'), findsOneWidget);
      expect(find.text('Seconds'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('workout-duration-selection-pill')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('workout-duration-hours-wheel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('workout-duration-minutes-wheel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('workout-duration-seconds-wheel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('workout-duration-picker-done')),
        findsOneWidget,
      );
    });

    testWidgets('handles negative or zero initial duration safely',
        (tester) async {
      await tester.pumpWidget(
        _buildWrapper(
          const WorkoutDurationPickerSheet(
            initialDuration: Duration(seconds: -10),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Workout Duration'), findsOneWidget);
    });

    testWidgets('showWorkoutDurationPickerSheet returns selected duration on Done',
        (tester) async {
      Duration? result;

      await tester.pumpWidget(
        _buildWrapper(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showWorkoutDurationPickerSheet(
                  context: context,
                  initialDuration: const Duration(hours: 2, minutes: 10),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Workout Duration'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('workout-duration-picker-done')));
      await tester.pumpAndSettle();

      expect(find.text('Workout Duration'), findsNothing);
      expect(result, const Duration(hours: 2, minutes: 10));
    });
  });
}
