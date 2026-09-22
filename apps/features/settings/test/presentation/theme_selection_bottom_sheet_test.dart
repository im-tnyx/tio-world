import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_settings/settings.dart';

void main() {
  Future<void> openSheet(
    WidgetTester tester, {
    required TioThemeMode currentMode,
    ValueChanged<TioThemeMode>? onSelected,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showThemeSelectionBottomSheet(
                  context: context,
                  currentMode: currentMode,
                  onThemeSelected: (mode) async => onSelected?.call(mode),
                );
              },
              child: const Text('Open Theme Sheet'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Theme Sheet'));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'ThemeSelectionBottomSheet renders the four theme options in order',
      (tester) async {
    await openSheet(tester, currentMode: TioThemeMode.system);

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Choose how Tio looks on this device'), findsOneWidget);

    const keys = [
      'theme-option-system',
      'theme-option-light',
      'theme-option-dark',
      'theme-option-tio-dark',
    ];
    final tops = [
      for (final key in keys) tester.getTopLeft(find.byKey(ValueKey(key))).dy,
    ];
    expect(tops, orderedEquals([...tops]..sort()));
    expect(find.byKey(const ValueKey('theme-option-oled')), findsNothing);

    for (final entry in const [
      (key: 'theme-option-system', title: 'System default'),
      (key: 'theme-option-light', title: 'Light'),
      (key: 'theme-option-dark', title: 'Dark'),
      (key: 'theme-option-tio-dark', title: 'Tio Dark'),
    ]) {
      expect(
        find.descendant(
          of: find.byKey(ValueKey(entry.key)),
          matching: find.text(entry.title),
        ),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('theme-option-dark')),
        matching: find.text('Pure black appearance'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('theme-option-tio-dark')),
        matching: find.text("Tio's signature midnight navy theme"),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('OLED'), findsNothing);
  });

  for (final testCase in const [
    (
      key: 'theme-option-tio-dark',
      currentMode: TioThemeMode.dark,
      expected: TioThemeMode.tioDark,
    ),
    (
      key: 'theme-option-dark',
      currentMode: TioThemeMode.tioDark,
      expected: TioThemeMode.dark,
    ),
  ]) {
    testWidgets('tapping ${testCase.key} selects ${testCase.expected.name}',
        (tester) async {
      TioThemeMode? selectedMode;
      await openSheet(
        tester,
        currentMode: testCase.currentMode,
        onSelected: (mode) => selectedMode = mode,
      );

      await tester.tap(find.byKey(ValueKey(testCase.key)));
      await tester.pumpAndSettle();

      expect(selectedMode, testCase.expected);
      expect(find.text('Appearance'), findsNothing);
    });
  }
}
