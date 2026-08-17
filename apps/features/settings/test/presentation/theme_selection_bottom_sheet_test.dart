import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_settings/settings.dart';

void main() {
  testWidgets('ThemeSelectionBottomSheet renders all 4 theme options and pre-selects current mode', (tester) async {
    TioThemeMode? selectedMode;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showThemeSelectionBottomSheet(
                  context: context,
                  currentMode: TioThemeMode.dark,
                  onThemeSelected: (mode) async {
                    selectedMode = mode;
                  },
                );
              },
              child: const Text('Open Theme Sheet'),
            ),
          ),
        ),
      ),
    );

    // Tap button to open sheet
    await tester.tap(find.text('Open Theme Sheet'));
    await tester.pumpAndSettle();

    // Verify sheet contents
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Choose how Tio looks on this device'), findsOneWidget);
    expect(find.byKey(const ValueKey('theme-option-system')), findsOneWidget);
    expect(find.byKey(const ValueKey('theme-option-light')), findsOneWidget);
    expect(find.byKey(const ValueKey('theme-option-dark')), findsOneWidget);
    expect(find.byKey(const ValueKey('theme-option-oled')), findsOneWidget);

    // Tap OLED option
    await tester.tap(find.byKey(const ValueKey('theme-option-oled')));
    await tester.pumpAndSettle();

    // Verify selection callback and bottom sheet dismissed
    expect(selectedMode, TioThemeMode.oled);
    expect(find.text('Appearance'), findsNothing);
  });
}
