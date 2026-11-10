import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';

Widget _app(Widget home) => MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [TioColors.dark]),
      home: home,
    );

void main() {
  testWidgets('shows owner conflict card with three actions', (tester) async {
    WorkoutInProgressAction? chosen;

    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                chosen = await showWorkoutInProgressDialog(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('You have a workout in progress'), findsOneWidget);
    expect(
      find.text(
        'If you start a new workout, your old workout will be permanently deleted.',
      ),
      findsOneWidget,
    );
    expect(find.text('Resume workout in progress'), findsOneWidget);
    expect(find.text('Start new workout'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('workout-in-progress-resume')));
    await tester.pumpAndSettle();
    expect(chosen, WorkoutInProgressAction.resume);
  });

  testWidgets('Cancel dismisses without starting', (tester) async {
    WorkoutInProgressAction? chosen;

    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                chosen = await showWorkoutInProgressDialog(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('workout-in-progress-cancel')));
    await tester.pumpAndSettle();
    expect(chosen, WorkoutInProgressAction.cancel);
  });
}
