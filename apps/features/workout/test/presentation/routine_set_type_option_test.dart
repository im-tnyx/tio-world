import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/src/presentation/library/routines/routine_set_type_badge.dart';
import 'package:tio_feature_workout/src/presentation/library/routines/routine_set_type_option.dart';
import 'package:tio_shared/shared.dart';

void main() {
  for (final mode in [
    TioThemeMode.light,
    TioThemeMode.dark,
    TioThemeMode.tioDark,
  ]) {
    for (final highContrast in [false, true]) {
      testWidgets('Set Type outlined options and 38dp badge at 320dp '
          '${mode.name}, highContrast=$highContrast', (tester) async {
        tester.view.physicalSize = const Size(320, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var tapped = 0;

        final base = switch (mode) {
          TioThemeMode.light => TioColors.light,
          TioThemeMode.dark => TioColors.oled,
          TioThemeMode.tioDark => TioColors.dark,
          TioThemeMode.system => throw StateError('Unexpected system mode'),
        };
        final colors = highContrast ? base.highContrast : base;
        await tester.pumpWidget(MaterialApp(
          builder: (context, child) => TioTheme(
            config: TioThemeConfig(mode: mode, highContrast: highContrast),
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(
            body: ListView(
              children: [
                for (final type in RoutineSetType.values)
                  RoutineSetTypeOption(
                    key: ValueKey('option-${type.wireValue}'),
                    type: type,
                    normalNumber: 2,
                    selected: type == RoutineSetType.failure,
                    onTap: () => tapped++,
                  ),
              ],
            ),
          ),
        ));

        for (final type in RoutineSetType.values) {
          final option = find.byKey(ValueKey('option-${type.wireValue}'));
          final selectable = find.descendant(
            of: option,
            matching: find.byType(TioSelectableCard),
          );
          expect(selectable, findsOneWidget);
          expect(tester.widget<TioSelectableCard>(selectable).selected,
              type == RoutineSetType.failure);

          final badge = find.descendant(
            of: option,
            matching: find.byType(RoutineSetTypeBadge),
          );
          expect(badge, findsOneWidget);
          final container = find.descendant(
            of: badge,
            matching: find.byType(Container),
          );
          expect(tester.getSize(container),
              const Size(TioSize.dp38, TioSize.dp38));
          final decoration = tester.widget<Container>(container).decoration!
              as BoxDecoration;
          expect(decoration.color, colors.surfaceVariant);

          final outlined = find.descendant(
            of: selectable,
            matching: find.byType(AnimatedContainer),
          );
          expect(outlined, findsOneWidget);
          final border = (tester.widget<AnimatedContainer>(outlined)
              .decoration! as BoxDecoration).border! as Border;
          final expected = type == RoutineSetType.failure
              ? colors.primary
              : colors.outlineStrong.withValues(
                  alpha: TioCardTokens.unselectedOutlineAlpha);
          expect(border.top.color, expected);
          expect(find.descendant(
            of: option,
            matching: find.byIcon(Icons.check),
          ), type == RoutineSetType.failure ? findsOneWidget : findsNothing);
        }

        await tester.tap(find.byKey(const ValueKey('option-drop')));
        await tester.pumpAndSettle();
        expect(tapped, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
