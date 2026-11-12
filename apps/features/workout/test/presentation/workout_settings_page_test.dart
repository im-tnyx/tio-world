import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';

final class _Repository implements WorkoutRuntimeSettingsRepository {
  int? seconds;

  @override
  Future<void> clearDefaultRestSeconds() async => seconds = null;

  @override
  Future<int?> readDefaultRestSeconds() async => seconds;

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
