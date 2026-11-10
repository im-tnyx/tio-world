import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_feature_workout/src/presentation/widgets/workout_activity_type_sheet.dart';
import 'package:tio_feature_workout/src/presentation/widgets/workout_duration_picker_sheet.dart';
import 'package:tio_feature_workout/src/presentation/widgets/workout_rpe_sheet.dart';

class _FakeGymLocationRepository implements GymLocationRepository {
  static const gyms = [
    GymLocation(
      id: 'test-gym',
      name: 'Test Fitness',
      address: 'Test Street',
      distanceKm: 1.2,
    ),
  ];

  @override
  Future<List<GymLocation>> searchGyms({
    double? latitude,
    double? longitude,
    String? query,
    int? radiusMeters,
  }) async {
    if (query == null || query.isEmpty) return gyms;
    return gyms
        .where((gym) => gym.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}

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
  testWidgets(
      'Back keeps raw blank title and blocks exit on draft write failure',
      (tester) async {
    var shouldPersist = false;
    String? retainedTitle;
    DateTime? retainedDate;
    int? retainedOffset;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(extensions: const [TioColors.dark]),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SaveWorkoutPage(
                    duration: const Duration(minutes: 35),
                    volumeKg: 0,
                    completedSets: 1,
                    initialWorkoutDateTime: DateTime(2026, 11, 1, 21),
                    initialWorkoutUtcOffsetMinutes: 330,
                    onLeaveDraft: ({
                      required title,
                      required description,
                      required date,
                      required utcOffsetMinutes,
                      required rpe,
                      required activityType,
                      required gym,
                      required duration,
                    }) async {
                      retainedTitle = title;
                      retainedDate = date;
                      retainedOffset = utcOffsetMinutes;
                      return shouldPersist;
                    },
                  ),
                ),
              ),
              child: const Text('Open Save'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Save'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('save-workout-title-input')),
      '   ',
    );
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(retainedTitle, '   ');
    expect(retainedDate, DateTime(2026, 11, 1, 21));
    expect(retainedOffset, 330);
    expect(find.byType(SaveWorkoutPage), findsOneWidget);
    expect(find.text('Workout draft could not be saved.'), findsOneWidget);

    shouldPersist = true;
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(SaveWorkoutPage), findsNothing);
  });

  testWidgets('pending draft Back blocks Date, Gym, Save and Discard',
      (tester) async {
    final leave = Completer<bool>();
    var saveCalls = 0;
    await tester.pumpWidget(_buildWrapper(Scaffold(
      body: Builder(
          builder: (context) => TextButton(
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => SaveWorkoutPage(
                    duration: const Duration(minutes: 20),
                    volumeKg: 0,
                    completedSets: 1,
                    onLeaveDraft: ({
                      required title,
                      required description,
                      required date,
                      required utcOffsetMinutes,
                      required rpe,
                      required activityType,
                      required gym,
                      required duration,
                    }) =>
                        leave.future,
                    onSave: ({
                      required title,
                      required description,
                      required date,
                      required utcOffsetMinutes,
                      required rpe,
                      required activityType,
                      required gym,
                      duration,
                    }) {
                      saveCalls++;
                      return true;
                    },
                  ),
                )),
                child: const Text('Open Save'),
              )),
    )));
    await tester.tap(find.text('Open Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump();
    expect(
        tester
            .widget<TioButton>(find.byKey(
              const ValueKey('save-workout-submit-button'),
            ))
            .enabled,
        isFalse);
    await tester.tap(find.byKey(const ValueKey('save-workout-date-tile')));
    await tester.tap(find.byKey(const ValueKey('save-workout-gym-tile')));
    await tester.tap(find.byKey(const ValueKey('save-workout-submit-button')));
    await tester.tap(find.byKey(const ValueKey('save-workout-discard-button')));
    await tester.pump();
    expect(find.text('Workout Date & Time'), findsNothing);
    expect(find.byType(GymSelectionPage), findsNothing);
    expect(find.text('Discard workout?'), findsNothing);
    expect(saveCalls, 0);
    leave.complete(true);
    await tester.pumpAndSettle();
    expect(find.byType(SaveWorkoutPage), findsNothing);
  });

  testWidgets('restores local Save review selections without visual changes',
      (tester) async {
    await tester.pumpWidget(
      _buildWrapper(
        const SaveWorkoutPage(
          initialTitle: 'Custom Workout',
          initialDescription: 'Description',
          initialGym: 'Gym One',
          initialActivityType: 'Cardio',
          initialRpe: 7.5,
          duration: Duration(minutes: 35),
          volumeKg: 0,
          completedSets: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Custom Workout'), findsOneWidget);
    expect(find.text('Gym One'), findsOneWidget);
    expect(find.text('Cardio'), findsOneWidget);
    expect(find.textContaining('7.5'), findsWidgets);
    expect(find.text('35min'), findsWidgets);
  });

  group('SaveWorkoutPage', () {
    testWidgets(
        'renders initial title or empty placeholder, duration, volume, and sets',
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
      expect(find.byKey(const ValueKey('save-workout-title-input')),
          findsOneWidget);
      expect(find.text('Legs'), findsOneWidget);
      expect(find.text('1h 11min'), findsOneWidget);
      expect(find.text('6,960 kg'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('Add a photo / video'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Weight Training'), findsOneWidget);
      expect(find.text('Rate workout'), findsOneWidget);
      expect(find.text('Select'), findsOneWidget); // Default gym is Select
      expect(find.text('Discard Workout'), findsOneWidget);
    });

    testWidgets(
        'renders empty title when initialTitle is null and user can type without box',
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

      final titleFinder =
          find.byKey(const ValueKey('save-workout-title-input'));
      final textField = tester.widget<TextField>(titleFinder);
      expect(textField.controller?.text, isEmpty);
      expect(textField.decoration?.border, InputBorder.none);
      expect(textField.decoration?.filled, isFalse);

      await tester.enterText(titleFinder, 'My Custom Workout');
      await tester.pumpAndSettle();

      expect(find.text('My Custom Workout'), findsOneWidget);
      expect(find.byKey(const ValueKey('save-workout-title-clear')),
          findsOneWidget);
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
      expect(
          find.byKey(const ValueKey('save-workout-title-clear')), findsNothing);
    });

    testWidgets('description input is borderless and filled=false',
        (tester) async {
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

      final descFinder =
          find.byKey(const ValueKey('save-workout-description-input'));
      final textField = tester.widget<TextField>(descFinder);
      expect(textField.decoration?.border, InputBorder.none);
      expect(textField.decoration?.filled, isFalse);
    });

    testWidgets('notes-only session save keeps unsupported metadata read-only',
        (tester) async {
      await tester.pumpWidget(
        _buildWrapper(
          const SaveWorkoutPage(
            initialTitle: 'Leg Day',
            initialDescription: 'Earlier note',
            duration: Duration(minutes: 45),
            volumeKg: 2500,
            completedSets: 10,
            notesOnly: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('save-workout-title-input')),
            )
            .readOnly,
        isTrue,
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('save-workout-description-input')),
            )
            .controller!
            .text,
        'Earlier note',
      );
      for (final key in [
        'save-workout-date-tile',
        'save-workout-gym-tile',
        'save-workout-activity-type-tile',
        'save-workout-rpe-tile',
      ]) {
        await tester.tap(find.byKey(ValueKey(key)));
        await tester.pumpAndSettle();
        expect(find.byType(GymSelectionPage), findsNothing);
        expect(find.byType(WorkoutActivityTypeSheet), findsNothing);
        expect(find.byType(WorkoutRpeSheet), findsNothing);
      }
      await tester
          .tap(find.byKey(const ValueKey('save-workout-duration-stat')));
      await tester.pumpAndSettle();
      expect(find.byType(WorkoutDurationPickerSheet), findsNothing);
    });

    testWidgets('blank title uses selected past local time only at submission',
        (tester) async {
      String? submittedTitle;
      DateTime? submittedDate;
      await tester.pumpWidget(
        _buildWrapper(
          SaveWorkoutPage(
            initialTitle: '',
            startedAt: DateTime(2024, 2, 3, 21),
            clock: () => DateTime(2025, 1, 1, 12),
            duration: const Duration(minutes: 30),
            volumeKg: 0,
            completedSets: 1,
            onSave: ({
              required String title,
              required String? description,
              required DateTime date,
              required int utcOffsetMinutes,
              required double? rpe,
              required String activityType,
              required String? gym,
              Duration? duration,
            }) {
              submittedTitle = title;
              submittedDate = date;
              return true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(submittedTitle, isNull,
          reason: 'fallback is not generated while editing');
      await tester
          .tap(find.byKey(const ValueKey('save-workout-submit-button')));
      await tester.pumpAndSettle();

      expect(submittedTitle, 'Night Workout');
      expect(submittedDate, DateTime(2024, 2, 3, 21));
    });

    testWidgets('does not pop or claim success when persistence rejects Save',
        (tester) async {
      await tester.pumpWidget(
        _buildWrapper(
          SaveWorkoutPage(
            duration: const Duration(minutes: 30),
            volumeKg: 0,
            completedSets: 1,
            onSave: ({
              required String title,
              required String? description,
              required DateTime date,
              required int utcOffsetMinutes,
              required double? rpe,
              required String activityType,
              required String? gym,
              Duration? duration,
            }) async =>
                false,
          ),
        ),
      );
      await tester
          .tap(find.byKey(const ValueKey('save-workout-submit-button')));
      await tester.pumpAndSettle();
      expect(find.text('Save Workout'), findsOneWidget);
      expect(find.text('Workout could not be saved.'), findsOneWidget);
    });

    testWidgets('Save pending blocks Discard until Save resolves',
        (tester) async {
      final saveResult = Completer<bool>();
      var discardCalls = 0;
      await tester.pumpWidget(
        _buildWrapper(
          SaveWorkoutPage(
            duration: const Duration(minutes: 30),
            volumeKg: 0,
            completedSets: 1,
            sessionMetadataOnly: true,
            onSave: ({
              required String title,
              required String? description,
              required DateTime date,
              required int utcOffsetMinutes,
              required double? rpe,
              required String activityType,
              required String? gym,
              Duration? duration,
            }) =>
                saveResult.future,
            onDiscard: () {
              discardCalls++;
              return true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(const ValueKey('save-workout-submit-button')));
      await tester.pump();

      final saveButton = tester.widget<TioButton>(
        find.byKey(const ValueKey('save-workout-submit-button')),
      );
      final discardButton = tester.widget<TextButton>(
        find.byKey(const ValueKey('save-workout-discard-button')),
      );
      expect(saveButton.loading, isTrue);
      expect(saveButton.enabled, isFalse);
      expect(discardButton.onPressed, isNull);
      expect(find.text('Discard workout?'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('save-workout-date-tile')));
      await tester.pump();
      expect(find.text('Workout Date & Time'), findsNothing);

      saveResult.complete(true);
      await tester.pumpAndSettle();
      expect(discardCalls, 0);
      expect(find.text('Workout could not be saved.'), findsNothing);
    });

    testWidgets(
        'tapping Gym opens GymSelectionPage, searches and selects gym, then clears it',
        (tester) async {
      await tester.pumpWidget(
        _buildWrapper(
          SaveWorkoutPage(
            duration: const Duration(minutes: 45),
            volumeKg: 2500.0,
            completedSets: 10,
            gymLocationRepository: _FakeGymLocationRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Select'), findsOneWidget);

      // Open Gym selection
      await tester.tap(find.byKey(const ValueKey('save-workout-gym-tile')));
      await tester.pumpAndSettle();

      expect(find.text('Gym'), findsWidgets);
      expect(find.text('Suggestions'), findsOneWidget);
      expect(find.text('Home gym'), findsOneWidget);
      expect(find.text('Popular gyms'), findsOneWidget);

      // Search gym
      await tester.enterText(
          find.byKey(const ValueKey('gym-search-input')), 'Test');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Test Fitness'), findsOneWidget);

      // Select Sky Fitness
      await tester.tap(find.text('Test Fitness'));
      await tester.pumpAndSettle();

      // Verified selected on SaveWorkoutPage
      expect(find.text('Test Fitness'), findsOneWidget);
      expect(
          find.byKey(const ValueKey('save-workout-gym-clear')), findsOneWidget);

      // Clear gym back to Select
      await tester.tap(find.byKey(const ValueKey('save-workout-gym-clear')));
      await tester.pumpAndSettle();

      expect(find.text('Select'), findsOneWidget);
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

      await tester
          .tap(find.byKey(const ValueKey('save-workout-activity-type-tile')));
      await tester.pumpAndSettle();

      expect(find.text('Activity Type'), findsNWidgets(2));
      expect(find.text('Running'), findsOneWidget);
      expect(find.text('HIIT'), findsOneWidget);
      expect(find.text('Yoga'), findsOneWidget);

      // Select Running
      await tester
          .tap(find.byKey(const ValueKey('activity-type-option-running')));
      await tester.pumpAndSettle();

      expect(find.text('Running'), findsOneWidget);
    });

    testWidgets(
        'tapping Date tile opens date picker sheet and caps at current local time',
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

    testWidgets(
        'tapping Save button triggers onSave callback with values including gym',
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
              required int utcOffsetMinutes,
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
              return true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('save-workout-title-input')),
        '  Legs  Day  ',
      );
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

      await tester
          .tap(find.byKey(const ValueKey('save-workout-submit-button')));
      await tester.pumpAndSettle();

      expect(savedTitle, 'Legs  Day');
      expect(savedDesc, 'Great session, new PR!');
      expect(savedActivity, 'Weight Training');
      expect(savedGym, 'Home gym');
      expect(savedRpe, isNull);
      expect(savedDuration, const Duration(hours: 1));
    });

    testWidgets(
        'tapping Duration stat opens duration picker sheet and updates duration on Done',
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
      await tester
          .tap(find.byKey(const ValueKey('save-workout-duration-stat')));
      await tester.pumpAndSettle();

      expect(find.text('Workout Duration'), findsOneWidget);
      expect(find.text('Hours'), findsNothing);
      expect(find.text('Minutes'), findsNothing);
      expect(find.text('Seconds'), findsNothing);
      expect(
          find.byKey(const ValueKey('workout-duration-wheel')), findsOneWidget);

      // Advance the unified wheel by one minute.
      await tester.drag(
        find.byKey(const ValueKey('workout-duration-wheel')),
        const Offset(0, -44),
      );
      await tester.pumpAndSettle();

      // Tap Done
      await tester
          .tap(find.byKey(const ValueKey('workout-duration-picker-done')));
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

      await tester.ensureVisible(
          find.byKey(const ValueKey('save-workout-discard-button')));
      await tester
          .tap(find.byKey(const ValueKey('save-workout-discard-button')));
      await tester.pumpAndSettle();

      expect(find.text('Discard workout?'), findsOneWidget);

      await tester.tap(find.text('Discard workout').last);
      await tester.pumpAndSettle();

      expect(discarded, isTrue);
    });

    testWidgets('waits for discard persistence before closing', (tester) async {
      final discardResult = Completer<bool>();

      await tester.pumpWidget(
        _buildWrapper(
          SaveWorkoutPage(
            duration: const Duration(minutes: 20),
            volumeKg: 1000.0,
            completedSets: 4,
            onDiscard: () => discardResult.future,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const ValueKey('save-workout-discard-button')),
      );
      await tester.tap(
        find.byKey(const ValueKey('save-workout-discard-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard workout').last);
      await tester.pump();

      expect(find.text('Save Workout'), findsOneWidget);
      expect(
        tester
            .widget<TioButton>(
              find.byKey(const ValueKey('save-workout-submit-button')),
            )
            .enabled,
        isFalse,
      );

      discardResult.complete(true);
      await tester.pumpAndSettle();

      expect(find.text('Save Workout'), findsNothing);
    });

    testWidgets('keeps the screen open when discard persistence fails',
        (tester) async {
      await tester.pumpWidget(
        _buildWrapper(
          SaveWorkoutPage(
            duration: const Duration(minutes: 20),
            volumeKg: 1000.0,
            completedSets: 4,
            onDiscard: () => false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const ValueKey('save-workout-discard-button')),
      );
      await tester.tap(
        find.byKey(const ValueKey('save-workout-discard-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard workout').last);
      await tester.pumpAndSettle();

      expect(find.text('Save Workout'), findsOneWidget);
      expect(find.text('Workout could not be discarded.'), findsOneWidget);
    });
  });
}
