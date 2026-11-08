import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';

Widget _buildWrapper(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark().copyWith(
      extensions: const [
        TioColors.dark,
      ],
    ),
    home: child,
  );
}

void main() {
  group('SaveWorkoutPage', () {
    testWidgets('renders initial title or empty placeholder, duration, volume, and sets',
        (tester) async {
      await tester.pumpWidget(
        _buildWrapper(
          const SaveWorkoutPage(
            initialTitle: 'Legs',
            duration: Duration(hours: 1, minutes: 11),
            volumeKg: 6960.0,
            completedSets: 20,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Save Workout'), findsOneWidget);
      expect(find.byKey(const ValueKey('save-workout-title-input')), findsOneWidget);
      expect(find.text('Legs'), findsOneWidget);
      expect(find.text('1h 11min'), findsOneWidget);
      expect(find.text('6,960 kg'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('Add a photo / video'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Weight Training'), findsOneWidget);
      expect(find.text('Rate workout'), findsOneWidget);
      expect(find.text('None'), findsOneWidget); // Default gym is None
      expect(find.text('Discard Workout'), findsOneWidget);
    });

    testWidgets('renders empty title when initialTitle is null and user can type without box',
        (tester) async {
      await tester.pumpWidget(
        _buildWrapper(
          const SaveWorkoutPage(
            duration: Duration(minutes: 30),
            volumeKg: 1000.0,
            completedSets: 5,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final titleFinder = find.byKey(const ValueKey('save-workout-title-input'));
      final textField = tester.widget<TextField>(titleFinder);
      expect(textField.controller?.text, isEmpty);
      expect(textField.decoration?.border, InputBorder.none);
      expect(textField.decoration?.filled, isFalse);

      await tester.enterText(titleFinder, 'My Custom Workout');
      await tester.pumpAndSettle();

      expect(find.text('My Custom Workout'), findsOneWidget);
      expect(find.byKey(const ValueKey('save-workout-title-clear')), findsOneWidget);
    });

    testWidgets('clear button clears the workout title input', (tester) async {
      await tester.pumpWidget(
        _buildWrapper(
          const SaveWorkoutPage(
            initialTitle: 'Chest Day',
            duration: Duration(minutes: 45),
            volumeKg: 2000.0,
            completedSets: 12,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chest Day'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('save-workout-title-clear')));
      await tester.pumpAndSettle();

      expect(find.text('Chest Day'), findsNothing);
      expect(find.byKey(const ValueKey('save-workout-title-clear')), findsNothing);
    });

    testWidgets('description input is borderless and filled=false', (tester) async {
      await tester.pumpWidget(
        _buildWrapper(
          const SaveWorkoutPage(
            duration: Duration(minutes: 40),
            volumeKg: 1500.0,
            completedSets: 8,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final descFinder = find.byKey(const ValueKey('save-workout-description-input'));
      final textField = tester.widget<TextField>(descFinder);
      expect(textField.decoration?.border, InputBorder.none);
      expect(textField.decoration?.filled, isFalse);
    });

    testWidgets('tapping Gym opens GymSelectionPage, searches and selects gym, then clears it',
        (tester) async {
      await tester.pumpWidget(
        _buildWrapper(
          const SaveWorkoutPage(
            duration: Duration(minutes: 45),
            volumeKg: 2500.0,
            completedSets: 10,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('None'), findsOneWidget);

      // Open Gym selection
      await tester.tap(find.byKey(const ValueKey('save-workout-gym-tile')));
      await tester.pumpAndSettle();

      expect(find.text('Gym'), findsWidgets);
      expect(find.text('Suggestions'), findsOneWidget);
      expect(find.text('Home gym'), findsOneWidget);
      expect(find.text('Popular gyms'), findsOneWidget);

      // Search gym
      await tester.enterText(find.byKey(const ValueKey('gym-search-input')), 'Sky');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Sky Fitness - Best Gym in Mangyawas, Mansarovar'), findsOneWidget);

      // Select Sky Fitness
      await tester.tap(find.text('Sky Fitness - Best Gym in Mangyawas, Mansarovar'));
      await tester.pumpAndSettle();

      // Verified selected on SaveWorkoutPage
      expect(find.text('Sky Fitness - Best Gym in Mangyawas, Mansarovar'), findsOneWidget);
      expect(find.byKey(const ValueKey('save-workout-gym-clear')), findsOneWidget);

      // Clear gym back to None
      await tester.tap(find.byKey(const ValueKey('save-workout-gym-clear')));
      await tester.pumpAndSettle();

      expect(find.text('None'), findsOneWidget);
    });

    testWidgets('tapping Activity Type opens sheet and updates selection',
        (tester) async {
      await tester.pumpWidget(
        _buildWrapper(
          const SaveWorkoutPage(
            duration: Duration(minutes: 30),
            volumeKg: 0.0,
            completedSets: 5,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Weight Training'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('save-workout-activity-type-tile')));
      await tester.pumpAndSettle();

      expect(find.text('Activity Type'), findsNWidgets(2));
      expect(find.text('Running'), findsOneWidget);
      expect(find.text('HIIT'), findsOneWidget);
      expect(find.text('Yoga'), findsOneWidget);

      // Select Running
      await tester.tap(find.byKey(const ValueKey('activity-type-option-running')));
      await tester.pumpAndSettle();

      expect(find.text('Running'), findsOneWidget);
    });

    testWidgets('tapping Date tile opens date picker sheet and caps at current local time',
        (tester) async {
      final fixedNow = DateTime(2026, 8, 3, 10, 30);
      final testDate = DateTime(2026, 8, 3, 6, 21);
      await tester.pumpWidget(
        _buildWrapper(
          SaveWorkoutPage(
            duration: const Duration(hours: 1, minutes: 11),
            volumeKg: 6960.0,
            completedSets: 20,
            startedAt: testDate,
            clock: () => fixedNow,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('3 Aug 2026, 6:21 AM'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('save-workout-date-tile')));
      await tester.pumpAndSettle();

      expect(find.text('Workout Date & Time'), findsOneWidget);
      final pickerFinder = find.byType(TioDateTimeWheelPicker);
      expect(pickerFinder, findsOneWidget);
      final picker = tester.widget<TioDateTimeWheelPicker>(pickerFinder);
      expect(picker.maximumDate, fixedNow);

      // Verify resolver clamps any future candidate to fixedNow
      final futureCandidate = fixedNow.add(const Duration(hours: 2));
      expect(picker.resolveDateTime?.call(futureCandidate), fixedNow);

      await tester.tap(find.byKey(const ValueKey('workout-date-picker-done')));
      await tester.pumpAndSettle();

      expect(find.text('Workout Date & Time'), findsNothing);
      expect(find.textContaining('3 Aug 2026, 6:21 AM'), findsOneWidget);
    });

    testWidgets('future startedAt date is automatically clamped to current now',
        (tester) async {
      final fixedNow = DateTime(2026, 8, 3, 10, 30);
      final futureDate = DateTime(2026, 8, 5, 12, 00); // 2 days in the future
      await tester.pumpWidget(
        _buildWrapper(
          SaveWorkoutPage(
            duration: const Duration(minutes: 30),
            volumeKg: 1000.0,
            completedSets: 5,
            startedAt: futureDate,
            clock: () => fixedNow,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verified clamped to fixedNow
      expect(find.textContaining('3 Aug 2026, 10:30 AM'), findsOneWidget);
    });

    testWidgets('tapping Workout RPE opens sheet and updates rating',
        (tester) async {
      await tester.pumpWidget(
        _buildWrapper(
          const SaveWorkoutPage(
            duration: Duration(minutes: 50),
            volumeKg: 3500.0,
            completedSets: 15,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rate workout'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('save-workout-rpe-tile')));
      await tester.pumpAndSettle();

      expect(find.text('Workout RPE'), findsNWidgets(2));
      expect(find.text('How hard was this workout?'), findsOneWidget);

      // Select 8.0
      await tester.tap(find.byKey(const ValueKey('rpe-option-8')));
      await tester.pumpAndSettle();

      // Tap Done
      await tester.tap(find.byKey(const ValueKey('rpe-sheet-done-button')));
      await tester.pumpAndSettle();

      expect(find.text('8 • Hard Effort'), findsOneWidget);
    });

    testWidgets('tapping Save button triggers onSave callback with values including gym',
        (tester) async {
      String? savedTitle;
      String? savedDesc;
      String? savedActivity;
      String? savedGym;
      double? savedRpe;
      Duration? savedDuration;

      await tester.pumpWidget(
        _buildWrapper(
          SaveWorkoutPage(
            initialTitle: 'Legs Day',
            duration: const Duration(hours: 1),
            volumeKg: 5000.0,
            completedSets: 16,
            onSave: ({
              required String title,
              required String? description,
              required DateTime date,
              required double? rpe,
              required String activityType,
              required String? gym,
              Duration? duration,
            }) {
              savedTitle = title;
              savedDesc = description;
              savedActivity = activityType;
              savedGym = gym;
              savedRpe = rpe;
              savedDuration = duration;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('save-workout-description-input')),
        'Great session, new PR!',
      );
      await tester.pumpAndSettle();

      // Select Home gym
      await tester.tap(find.byKey(const ValueKey('save-workout-gym-tile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('gym-option-home-gym')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('save-workout-submit-button')));
      await tester.pumpAndSettle();

      expect(savedTitle, 'Legs Day');
      expect(savedDesc, 'Great session, new PR!');
      expect(savedActivity, 'Weight Training');
      expect(savedGym, 'Home gym');
      expect(savedRpe, isNull);
      expect(savedDuration, const Duration(hours: 1));
    });

    testWidgets('tapping Duration stat opens duration picker sheet and updates duration on Done',
        (tester) async {
      await tester.pumpWidget(
        _buildWrapper(
          const SaveWorkoutPage(
            duration: Duration(minutes: 44),
            volumeKg: 1000.0,
            completedSets: 3,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('44min'), findsOneWidget);

      // Tap duration stat
      await tester.tap(find.byKey(const ValueKey('save-workout-duration-stat')));
      await tester.pumpAndSettle();

      expect(find.text('Workout Duration'), findsOneWidget);
      expect(find.text('Hours'), findsOneWidget);
      expect(find.text('Minutes'), findsOneWidget);
      expect(find.text('Seconds'), findsOneWidget);
      expect(find.byKey(const ValueKey('workout-duration-hours-wheel')), findsOneWidget);
      expect(find.byKey(const ValueKey('workout-duration-minutes-wheel')), findsOneWidget);
      expect(find.byKey(const ValueKey('workout-duration-seconds-wheel')), findsOneWidget);

      // Drag minutes wheel forward by 1 item extent
      await tester.drag(
        find.byKey(const ValueKey('workout-duration-minutes-wheel')),
        const Offset(0, -44),
      );
      await tester.pumpAndSettle();

      // Tap Done
      await tester.tap(find.byKey(const ValueKey('workout-duration-picker-done')));
      await tester.pumpAndSettle();

      expect(find.text('Workout Duration'), findsNothing);
      expect(find.text('45min'), findsOneWidget);
    });

    testWidgets('tapping Discard Workout asks confirmation and calls onDiscard',
        (tester) async {
      var discarded = false;

      await tester.pumpWidget(
        _buildWrapper(
          SaveWorkoutPage(
            duration: const Duration(minutes: 20),
            volumeKg: 1000.0,
            completedSets: 4,
            onDiscard: () => discarded = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const ValueKey('save-workout-discard-button')));
      await tester.tap(find.byKey(const ValueKey('save-workout-discard-button')));
      await tester.pumpAndSettle();

      expect(find.text('Discard workout?'), findsOneWidget);

      await tester.tap(find.text('Discard workout').last);
      await tester.pumpAndSettle();

      expect(discarded, isTrue);
    });
  });
}
