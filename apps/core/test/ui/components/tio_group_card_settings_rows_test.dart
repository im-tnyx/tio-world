import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

Widget _app(Widget child) {
  return MaterialApp(
    theme: ThemeData(extensions: const [TioColors.light]),
    home: Scaffold(body: child),
  );
}

void main() {
  group('TioGroupCard', () {
    testWidgets('uses the neutral clipped group surface and preserves order',
        (tester) async {
      await tester.pumpWidget(
        _app(
          const TioGroupCard(
            children: [Text('First row'), Text('Second row')],
          ),
        ),
      );

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(TioGroupCard),
          matching: find.byType(Material),
        ),
      );
      expect(material.clipBehavior, Clip.antiAlias);
      expect(tester.getTopLeft(find.text('First row')).dy,
          lessThan(tester.getTopLeft(find.text('Second row')).dy));
      expect(tester.takeException(), isNull);
    });
  });

  group('TioSettings rows', () {
    testWidgets('navigation row keeps its leading, supporting text and tap',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          TioSettingsNavigationRow(
            leading: const TioSettingsLeadingIcon(icon: Icons.tune),
            title: 'Preferences',
            supportingText: 'Theme and units',
            onTap: () => taps++,
          ),
        ),
      );

      expect(find.text('Preferences'), findsOneWidget);
      expect(find.text('Theme and units'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      await tester.tap(find.text('Preferences'));
      expect(taps, 1);
    });

    testWidgets('value row supports multiline values and a custom trailing',
        (tester) async {
      await tester.pumpWidget(
        _app(
          const TioSettingsValueRow(
            leading: Icon(Icons.water_drop_outlined),
            label: 'Water Goal',
            value: TioSettingsValueText(
              value: '2.8 litres per day',
              isUnset: false,
            ),
            onTap: null,
            showEditAffordance: false,
            trailing: Icon(Icons.info_outline),
          ),
        ),
      );

      expect(find.text('Water Goal'), findsOneWidget);
      expect(find.text('2.8 litres per day'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.byType(TioSettingsEditAffordance), findsNothing);
    });

    testWidgets('read-only rows have no tap target or edit affordance',
        (tester) async {
      await tester.pumpWidget(
        _app(
          const TioSettingsReadOnlyRow(
            label: 'Goal Started',
            value: 'Not set',
            isUnset: true,
          ),
        ),
      );

      expect(find.text('Goal Started'), findsOneWidget);
      expect(find.text('Not set'), findsOneWidget);
      expect(find.byType(InkWell), findsNothing);
      expect(find.byType(TioSettingsEditAffordance), findsNothing);
    });

    testWidgets('a read-only value wraps on a narrow row instead of spilling',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(
          const TioSettingsReadOnlyRow(
            label: 'Date',
            value: 'Wednesday, September 30, 2026',
            isUnset: false,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.byType(TioSettingsReadOnlyRow)).right,
        lessThanOrEqualTo(320),
      );
    });

    testWidgets('a value that already fits keeps its single-line width',
        (tester) async {
      await tester.pumpWidget(
        _app(
          const TioSettingsReadOnlyRow(
            label: 'Goal Started',
            value: 'Not set',
            isUnset: true,
          ),
        ),
      );

      // The loose Flexible must not stretch a short value across the row. It
      // stays content-sized and right-anchored against the row's own padding,
      // which is where it sat before the wrap was added.
      final row = tester.getRect(find.byType(TioSettingsReadOnlyRow));
      final value = tester.getRect(find.text('Not set'));
      expect(value.right, moreOrLessEquals(row.right - TioSpacing.lg));
      expect(value.width, lessThan(row.width / 2));
    });
  });
}
