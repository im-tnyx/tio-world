import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/src/presentation/library/routines/routine_set_type_badge.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

double _contrast(Color first, Color second) {
  final a = first.computeLuminance();
  final b = second.computeLuminance();
  return a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05);
}

void main() {
  test('Normal choice number is contextual and excludes other Set types', () {
    final sets = [
      RoutineCompositionSet(
        id: '10000000-0000-4000-8000-000000000001',
        prescription: SetPrescription(reps: 8),
      ),
      RoutineCompositionSet(
        id: '10000000-0000-4000-8000-000000000002',
        prescription: SetPrescription(setType: RoutineSetType.warmUp),
      ),
      RoutineCompositionSet(
        id: '10000000-0000-4000-8000-000000000003',
        prescription: SetPrescription(reps: 8),
      ),
      RoutineCompositionSet(
        id: '10000000-0000-4000-8000-000000000004',
        prescription: SetPrescription(setType: RoutineSetType.failure),
      ),
    ];
    expect(routineNormalNumberForSelection(sets, sets[0].id), 1);
    expect(routineNormalNumberForSelection(sets, sets[1].id), 2);
    expect(routineNormalNumberForSelection(sets, sets[2].id), 2);
    expect(routineNormalNumberForSelection(sets, sets[3].id), 3);
  });

  for (final mode in [
    TioThemeMode.light,
    TioThemeMode.dark,
    TioThemeMode.tioDark,
  ]) {
    for (final highContrast in [false, true]) {
      testWidgets('Set badges preserve type colors and contrast in ${mode.name} '
          'highContrast=$highContrast', (tester) async {
        tester.view.physicalSize = const Size(320, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final base = switch (mode) {
          TioThemeMode.light => TioColors.light,
          TioThemeMode.dark => TioColors.oled,
          TioThemeMode.tioDark => TioColors.dark,
          TioThemeMode.system => throw StateError('Unexpected system mode'),
        };
        final colors = highContrast ? base.highContrast : base;
        for (final edit in [false, true]) {
          await tester.pumpWidget(MaterialApp(
            builder: (context, child) => TioTheme(
              config: TioThemeConfig(mode: mode, highContrast: highContrast),
              child: child ?? const SizedBox.shrink(),
            ),
            home: Scaffold(
              body: Column(
                children: [
                  for (final type in RoutineSetType.values)
                    RoutineSetTypeBadge(
                      setType: type,
                      normalNumber: 2,
                      useEditSetNumberColor: edit,
                    ),
                ],
              ),
            ),
          ));
          for (final type in RoutineSetType.values) {
            final index = RoutineSetType.values.indexOf(type);
            final badge = find.byType(RoutineSetTypeBadge).at(index);
            final box = find.descendant(
              of: badge,
              matching: find.byType(Container),
            );
            expect(box, findsOneWidget);
            final decoration = tester.widget<Container>(box).decoration!
                as BoxDecoration;
            expect(decoration.color, colors.surfaceVariant);
            expect(decoration.borderRadius,
                BorderRadius.circular(TioInputTokens.radius));
            expect(tester.getSize(box), const Size(TioSize.dp38, TioSize.dp38));
            final label = tester.widget<Text>(find.descendant(
              of: box,
              matching: find.byType(Text),
            ));
            expect(label.data, switch (type) {
              RoutineSetType.normal => '2',
              RoutineSetType.warmUp => 'W',
              RoutineSetType.failure => 'F',
              RoutineSetType.drop => 'D',
            });
            final preferred = switch (type) {
              RoutineSetType.normal =>
                edit ? colors.primary : colors.textPrimary,
              RoutineSetType.warmUp => colors.warning,
              RoutineSetType.failure => colors.danger,
              RoutineSetType.drop => colors.info,
            };
            final expected = _contrast(preferred, colors.surfaceVariant) >= 4.5
                ? preferred
                : colors.surfaceVariant.computeLuminance() > 0.179
                    ? TioPalette.black
                    : TioPalette.white;
            expect(label.style!.color, expected);
            expect(_contrast(label.style!.color!, colors.surfaceVariant),
                greaterThanOrEqualTo(4.5));
          }
        }
      });
    }
  }
}
