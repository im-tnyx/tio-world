import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';

final class _Repository implements WorkoutRuntimeSettingsRepository {
  bool vibrationEnabled = false;
  bool failNextVibrationRead = false;

  @override
  Future<bool> readRestTimerVibrationEnabled() async {
    if (failNextVibrationRead) {
      failNextVibrationRead = false;
      throw StateError('Simulated vibration storage read failure');
    }
    return vibrationEnabled;
  }

  @override
  Future<void> writeRestTimerVibrationEnabled(bool enabled) async {
    vibrationEnabled = enabled;
  }

  int? seconds;
  int readCount = 0;
  bool failNextRead = false;

  @override
  Future<void> clearDefaultRestSeconds() async => seconds = null;

  @override
  Future<int?> readDefaultRestSeconds() async {
    readCount++;
    if (failNextRead) {
      failNextRead = false;
      throw StateError('Simulated local storage read failure');
    }
    return seconds;
  }

  @override
  Future<void> writeDefaultRestSeconds(int seconds) async =>
      this.seconds = seconds;
}

void main() {
  testWidgets('Default Rest Timer row adapts to theme and compact width',
      (tester) async {
    for (final mode in [TioThemeMode.light, TioThemeMode.dark]) {
      for (final width in [390.0, 320.0]) {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        final repository = _Repository();
        final controller = WorkoutRuntimeSettingsController(
          repository: repository,
        );
        await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(width == 320 ? 1.6 : 1),
            ),
            child: TioTheme(
              config: TioThemeConfig(mode: mode),
              child: child!,
            ),
          ),
          home: WorkoutSettingsPage(controller: controller),
        ));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('workout-default-rest-timer')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
      }
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('failed read shows Retry and recovers to the saved setting',
      (tester) async {
    final repository = _Repository()
      ..seconds = 60
      ..failNextRead = true;
    final controller = WorkoutRuntimeSettingsController(repository: repository);
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(child: child!),
      home: WorkoutSettingsPage(controller: controller),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Could not load Workout Settings.'), findsOneWidget);
    expect(find.byKey(const ValueKey('workout-settings-retry')),
        findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(repository.readCount, 1);

    await tester.tap(find.byKey(const ValueKey('workout-settings-retry')));
    await tester.pumpAndSettle();

    expect(repository.readCount, 2);
    expect(controller.isReady, isTrue);
    expect(find.byKey(const ValueKey('workout-default-rest-timer')),
        findsOneWidget);
    expect(find.text('1min'), findsOneWidget);
    expect(find.byKey(const ValueKey('workout-settings-retry')),
        findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Rest Timer Vibration switch persists independently', (tester) async {
    final repository = _Repository();
    final controller = WorkoutRuntimeSettingsController(repository: repository);
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(child: child!),
      home: WorkoutSettingsPage(controller: controller),
    ));
    await tester.pumpAndSettle();

    final toggle = find.byKey(
      const ValueKey('workout-rest-timer-vibration-switch'),
    );
    expect(toggle, findsOneWidget);
    expect(tester.widget<Switch>(toggle).value, isFalse);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(repository.vibrationEnabled, isTrue);
    expect(tester.widget<Switch>(toggle).value, isTrue);

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(repository.vibrationEnabled, isFalse);
    expect(find.text('Default Rest Timer'), findsOneWidget);
  });

  testWidgets('vibration read error has independent Retry', (tester) async {
    final repository = _Repository()..failNextVibrationRead = true;
    final controller = WorkoutRuntimeSettingsController(repository: repository);
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(child: child!),
      home: WorkoutSettingsPage(controller: controller),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('workout-default-rest-timer')), findsOneWidget);
    final retry = find.byKey(
      const ValueKey('workout-rest-timer-vibration-retry'),
    );
    expect(retry, findsOneWidget);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('workout-rest-timer-vibration-switch')),
        findsOneWidget);
  });

  testWidgets('Default Rest Timer saves duration, cancel, and explicit OFF',
      (tester) async {
    final repository = _Repository();
    final controller = WorkoutRuntimeSettingsController(repository: repository);
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(child: child!),
      home: WorkoutSettingsPage(controller: controller),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Workout Settings'), findsOneWidget);
    expect(find.text('Default Rest Timer'), findsOneWidget);
    expect(find.text('OFF'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('workout-default-rest-timer')));
    await tester.pumpAndSettle();
    await _selectWheelItem(tester, 12); // 60 seconds
    await tester.tap(
      find.byKey(const ValueKey('routine-rest-timer-done-button')),
    );
    await tester.pumpAndSettle();
    expect(repository.seconds, 60);
    expect(find.text('1min'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('workout-default-rest-timer')));
    await tester.pumpAndSettle();
    await _selectWheelItem(tester, 0);
    await tester.tapAt(const Offset(8, 8)); // Dismiss without Done.
    await tester.pumpAndSettle();
    expect(repository.seconds, 60);
    expect(find.text('1min'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('workout-default-rest-timer')));
    await tester.pumpAndSettle();
    await _selectWheelItem(tester, 0);
    await tester.tap(
      find.byKey(const ValueKey('routine-rest-timer-done-button')),
    );
    await tester.pumpAndSettle();
    expect(repository.seconds, 0);
    expect(find.text('OFF'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _selectWheelItem(WidgetTester tester, int index) async {
  final wheel = find.byKey(const ValueKey('routine-rest-timer-wheel'));
  final scrollable = tester.widget<ListWheelScrollView>(wheel);
  (scrollable.controller! as FixedExtentScrollController).jumpToItem(index);
  await tester.pumpAndSettle();
}
