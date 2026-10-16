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
      testWidgets('54dp Core outlined Set Type and Remove cards at 320dp '
          '${mode.name}, highContrast=$highContrast', (tester) async {
        tester.view.physicalSize = const Size(320, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var selectedCount = 0;
        var removedCount = 0;

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
                    onTap: () => selectedCount++,
                  ),
                RoutineRemoveSetOption(
                  key: const ValueKey('option-remove'),
                  onTap: () => removedCount++,
                ),
              ],
            ),
          ),
        ));

        for (final type in RoutineSetType.values) {
          final option = find.byKey(ValueKey('option-${type.wireValue}'));
          final card = find.descendant(
            of: option,
            matching: find.byType(TioCard),
          );
          expect(card, findsOneWidget);
          final rendered = tester.widget<TioCard>(card);
          expect(rendered.variant, TioCardVariant.outlined);
          expect(rendered.padding, const EdgeInsets.symmetric(
            horizontal: TioSpacing.md,
            vertical: TioSpacing.sm,
          ));
          expect(tester.getSize(card).height, TioSize.dp54);

          final semantics = tester.widget<Semantics>(find.descendant(
            of: option,
            matching: find.byType(Semantics),
          ).first);
          expect(semantics.properties.button, isTrue);
          expect(semantics.properties.selected,
              type == RoutineSetType.failure);
          expect(semantics.properties.label, isNotEmpty);

          final outlined = find.descendant(
            of: card,
            matching: find.byType(Container),
          ).first;
          final outline = tester.widget<Container>(outlined).decoration!
              as BoxDecoration;
          expect((outline.border! as Border).top.color, colors.outlineStrong);

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

          expect(find.descendant(
            of: option,
            matching: find.byIcon(Icons.check),
          ), type == RoutineSetType.failure ? findsOneWidget : findsNothing);
        }

        final remove = find.byKey(const ValueKey('option-remove'));
        final removeCard = find.descendant(
          of: remove, matching: find.byType(TioCard));
        expect(removeCard, findsOneWidget);
        expect(tester.widget<TioCard>(removeCard).variant,
            TioCardVariant.outlined);
        expect(tester.getSize(removeCard).height, TioSize.dp54);
        final trash = find.descendant(
          of: remove, matching: find.byIcon(Icons.delete_outline));
        expect(trash, findsOneWidget);
        expect(tester.widget<Icon>(trash).color, colors.danger);
        expect(find.descendant(
          of: remove, matching: find.text('Remove Set')),
          findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('option-drop')));
        await tester.tap(remove);
        await tester.pumpAndSettle();
        expect(selectedCount, 1);
        expect(removedCount, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('compact outlined option grows for large accessible text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.dark),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(3),
          ),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: Scaffold(
        body: ListView(
          children: [
            RoutineSetTypeOption(
              type: RoutineSetType.warmUp,
              normalNumber: 1,
              selected: true,
              onTap: () {},
            ),
          ],
        ),
      ),
    ));
    expect(tester.getSize(find.byType(TioCard)),
        greaterThanOrEqualTo(const Size(0, 0)));
    expect(tester.getSize(find.byType(TioCard)).height,
        greaterThanOrEqualTo(TioSize.dp54));
    expect(tester.takeException(), isNull);
  });
}
