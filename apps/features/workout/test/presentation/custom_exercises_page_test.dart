import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

Future<void> _pump(WidgetTester tester, UserExerciseRepository? repository) async {
  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => TioTheme(
      config: const TioThemeConfig(mode: TioThemeMode.light),
      child: child ?? const SizedBox.shrink(),
    ),
    home: CustomExercisesPage(repository: repository),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('missing durable repository fails closed', (tester) async {
    await _pump(tester, null);
    expect(find.byKey(const ValueKey('custom-exercises-unavailable')), findsOneWidget);
    expect(find.text('Custom Exercises are unavailable right now.'), findsOneWidget);
    expect(tester.widget<IconButton>(find.byKey(const ValueKey('custom-exercise-create'))).onPressed, isNull);
  });

  testWidgets('empty collection opens structured create editor', (tester) async {
    final repository = _FakeRepository();
    await _pump(tester, repository);
    await tester.tap(find.byKey(const ValueKey('custom-exercises-empty-create')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('custom-exercise-editor')), findsOneWidget);
    expect(find.byKey(const ValueKey('custom-exercise-name')), findsOneWidget);
    expect(find.byKey(const ValueKey('custom-exercise-description')), findsOneWidget);
    expect(find.text('Exercise Type'), findsOneWidget);
    expect(find.text('Primary muscle'), findsOneWidget);
    expect(find.text('Secondary muscles'), findsOneWidget);
    expect(find.text('Equipment'), findsOneWidget);
    expect(find.byKey(const ValueKey('custom-exercise-archive')), findsNothing);
  });

  testWidgets('create persists name and definition then returns to list', (tester) async {
    final repository = _FakeRepository();
    await _pump(tester, repository);
    await tester.tap(find.byKey(const ValueKey('custom-exercises-empty-create')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(of: find.byKey(const ValueKey('custom-exercise-name')), matching: find.byType(EditableText)),
      'Tempo Squat',
    );
    await tester.enterText(
      find.descendant(of: find.byKey(const ValueKey('custom-exercise-description')), matching: find.byType(EditableText)),
      'Three second eccentric',
    );
    await tester.tap(find.byKey(const ValueKey('custom-exercise-save')));
    await tester.pumpAndSettle();

    expect(repository.exercises, hasLength(1));
    expect(repository.exercises.single.displayName, 'Tempo Squat');
    expect(repository.exercises.single.description, 'Three second eccentric');
    expect(find.text('Tempo Squat'), findsOneWidget);
  });

  testWidgets('existing exercise opens edit and archive removes it', (tester) async {
    final repository = _FakeRepository(exercises: [
      Exercise(
        ref: _id(1),
        displayName: 'Tempo Squat',
        exerciseType: ExerciseType.weightReps,
        primaryMuscles: const ['quadriceps'],
        status: ExerciseStatus.active,
      ),
    ]);
    await _pump(tester, repository);
    await tester.tap(find.byKey(ValueKey('custom-exercise-row-${_id(1).value}')));
    await tester.pumpAndSettle();

    expect(find.text('Edit Exercise'), findsOneWidget);
    expect(find.byKey(const ValueKey('custom-exercise-archive')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('custom-exercise-archive')));
    await tester.tap(find.byKey(const ValueKey('custom-exercise-archive')));
    await tester.pumpAndSettle();

    expect(repository.exercises, isEmpty);
    expect(find.byKey(const ValueKey('custom-exercises-empty')), findsOneWidget);
  });
}

UserCreatedExerciseRef _id(int value) => UserCreatedExerciseRef(
  '00000000-0000-4000-8000-${value.toString().padLeft(12, '0')}',
);

final class _FakeRepository implements UserExerciseRepository {
  _FakeRepository({List<Exercise>? exercises}) : exercises = [...?exercises];
  final List<Exercise> exercises;

  @override
  Future<List<Exercise>> list({bool includeArchived = false}) async =>
      List.unmodifiable(exercises.where((e) => includeArchived || e.status == ExerciseStatus.active));

  @override
  Future<void> create({
    required UserCreatedExerciseRef id,
    required String displayName,
    CatalogExerciseRef? basedOnCatalogExercise,
    UserExerciseDefinition? definition,
  }) async {
    exercises.add(Exercise(
      ref: id,
      displayName: displayName,
      description: definition?.description,
      exerciseType: definition?.exerciseType,
      primaryMuscles: definition?.primaryMuscle == null ? const [] : [definition!.primaryMuscle!],
      secondaryMuscles: definition?.secondaryMuscles ?? const [],
      primaryEquipment: definition?.primaryEquipment,
      status: ExerciseStatus.active,
    ));
  }

  @override
  Future<void> rename({required UserCreatedExerciseRef id, required String displayName}) async {
    final i = exercises.indexWhere((e) => e.ref == id);
    final old = exercises[i];
    exercises[i] = Exercise(
      ref: old.ref, displayName: displayName, description: old.description,
      exerciseType: old.exerciseType, primaryMuscles: old.primaryMuscles,
      secondaryMuscles: old.secondaryMuscles, primaryEquipment: old.primaryEquipment,
      status: old.status,
    );
  }

  @override
  Future<void> updateDefinition({required UserCreatedExerciseRef id, required UserExerciseDefinition definition}) async {
    final i = exercises.indexWhere((e) => e.ref == id);
    final old = exercises[i];
    exercises[i] = Exercise(
      ref: old.ref, displayName: old.displayName, description: definition.description,
      exerciseType: definition.exerciseType,
      primaryMuscles: definition.primaryMuscle == null ? const [] : [definition.primaryMuscle!],
      secondaryMuscles: definition.secondaryMuscles, primaryEquipment: definition.primaryEquipment,
      status: old.status,
    );
  }

  @override
  Future<void> archive(UserCreatedExerciseRef id) async {
    exercises.removeWhere((e) => e.ref == id);
  }
}
