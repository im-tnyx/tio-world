import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';

void main() {
  testWidgets('shows resume and discard actions for an in-progress workout',
      (tester) async {
    var resumed = 0;
    var discarded = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(extensions: const [TioColors.dark]),
        home: Scaffold(
          body: ActiveWorkoutMiniBar(
            duration: const Duration(minutes: 12, seconds: 5),
            subtitle: 'Bench Press',
            isPaused: false,
            onResume: () => resumed++,
            onDiscard: () => discarded++,
          ),
        ),
      ),
    );

    expect(find.text('Workout 0:12:05'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('active-workout-mini-bar-resume')));
    await tester.tap(
        find.byKey(const ValueKey('active-workout-mini-bar-discard')));
    expect(resumed, 1);
    expect(discarded, 1);
  });
}
