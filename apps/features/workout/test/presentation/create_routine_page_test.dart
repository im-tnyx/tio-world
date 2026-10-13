import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets('picker adds Set 1 and enables a single atomic Save',
      (tester) async {
    final create = _Create();
    var index = 0;
    final uuids = [
      '44444444-4444-4444-8444-444444444444',
      '55555555-5555-4555-8555-555555555555',
      '22222222-2222-4222-8222-222222222222',
      '33333333-3333-4333-8333-333333333333',
    ];
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: TioThemeMode.dark),
        child: child ?? const SizedBox.shrink(),
      ),
      home: CreateRoutinePage(
        program: Program(
          id: ProgramId('11111111-1111-4111-8111-111111111111'),
          name: 'Program 1',
        ),
        initialName: 'Routine 1',
        createRepository: create,
        catalogRepository: _Catalog(),
        weightUnit: WeightUnit.kg,
        newUuid: () => uuids[index++],
      ),
    ));
    await tester.tap(
      find.byKey(const ValueKey('create-routine-add-exercise')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-exercise-picker-page')),
        findsOneWidget);
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey(
        'create-routine-set-55555555-5555-4555-8555-555555555555')),
        findsOneWidget);
    expect(find.text('KG'), findsOneWidget);
    expect(find.text('REPS'), findsOneWidget);
    expect(tester.widget<TextButton>(
        find.byKey(const ValueKey('create-routine-save'))).onPressed,
        isNotNull);
    expect(create.calls, 0);
    await tester.tap(find.byKey(const ValueKey('create-routine-save')));
    await tester.pump();
    expect(create.calls, 1);
    expect(create.command!.entries.single.sets.single.prescription.reps, 1);
    expect(create.command!.entries.single.sets.single.prescription.loadKg,
        isNull);
  });

  testWidgets('Create reference empty state has disabled Save and Add exercise',
      (tester) async {
    final create = _Create();
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: TioThemeMode.dark),
        child: child ?? const SizedBox.shrink(),
      ),
      home: CreateRoutinePage(
        program: Program(
          id: ProgramId('11111111-1111-4111-8111-111111111111'),
          name: 'Program 1',
        ),
        initialName: 'Routine 1',
        createRepository: create,
        catalogRepository: _Catalog(),
        weightUnit: WeightUnit.kg,
      ),
    ));
    expect(find.text('Create Routine'), findsOneWidget);
    final name = find.descendant(
      of: find.byKey(const ValueKey('create-routine-name')),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(name).controller.text, 'Routine 1');
    expect(find.textContaining('Get started by adding'), findsOneWidget);
    expect(find.byKey(const ValueKey('create-routine-add-exercise')),
        findsOneWidget);
    final save = tester.widget<TextButton>(
        find.byKey(const ValueKey('create-routine-save')));
    expect(save.onPressed, isNull);
    expect(create.calls, 0);
    await tester.tap(find.byKey(const ValueKey('create-routine-cancel')));
    await tester.pumpAndSettle();
    expect(create.calls, 0);
  });
}

class _Catalog implements ExerciseCatalogRepository {
  @override
  Future<ExerciseCatalog> load() async => ExerciseCatalog([
        Exercise(
          ref: ExerciseRef.catalog('ex_bench_press'),
          displayName: 'Bench Press',
          status: ExerciseStatus.active,
        ),
      ]);
}

class _Create implements RoutineCreateRepository {
  int calls = 0;
  RoutineCreateCommand? command;
  @override
  Future<int> create(RoutineCreateCommand value) async {
    calls++;
    command = value;
    return 1;
  }
}
