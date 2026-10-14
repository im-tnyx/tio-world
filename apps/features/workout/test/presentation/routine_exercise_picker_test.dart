import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _customId = '50000000-0000-4000-8000-000000000001';

Exercise _catalogExercise({ExerciseStatus status = ExerciseStatus.active}) =>
    Exercise(
      ref: ExerciseRef.catalog('ex_bench_press'),
      displayName: 'Bench Press',
      status: status,
    );

Exercise _customExercise({ExerciseStatus status = ExerciseStatus.active}) =>
    Exercise(
      ref: ExerciseRef.userCreated(_customId),
      displayName: 'My Lift',
      status: status,
    );

_Catalog _catalog([List<Exercise>? items]) => _Catalog(
      () async => ExerciseCatalog(items ?? [_catalogExercise()]),
    );

void main() {
  test('picker searches both canonical sources and returns only visible active refs',
      () async {
    final ctrl = RoutineExercisePickerController(
      catalogRepository: _catalog([
        _catalogExercise(),
        Exercise(
          ref: ExerciseRef.catalog('ex_archived'),
          displayName: 'Archived',
          status: ExerciseStatus.archived,
        ),
      ]),
      userExerciseRepository: _User(
        () async => [
          _customExercise(),
          Exercise(
            ref: ExerciseRef.userCreated(
                '50000000-0000-4000-8000-000000000002'),
            displayName: 'Old Lift',
            status: ExerciseStatus.archived,
          ),
        ],
      ),
    );
    addTearDown(ctrl.dispose);

    await ctrl.load();
    expect(ctrl.state.status, RoutineExercisePickerStatus.ready);
    expect(ctrl.state.items.map((item) => item.name), [
      'My Lift',
      'Bench Press',
    ]);
    expect(ctrl.select(_customExercise().ref)?.ref, _customExercise().ref);
    expect(ctrl.select(ExerciseRef.catalog('ex_archived')), isNull);

    ctrl.search('  my    lift ');
    expect(ctrl.state.items.map((item) => item.name), ['My Lift']);
    expect(ctrl.select(_catalogExercise().ref), isNull);
    ctrl.search('no matches');
    expect(ctrl.state.items, isEmpty);
    expect(ctrl.state.hasActiveExercises, isTrue);
  });

  test('unavailable Custom repository selects only catalog and never writes',
      () async {
    final ctrl = RoutineExercisePickerController(catalogRepository: _catalog());
    addTearDown(ctrl.dispose);
    await ctrl.load();
    expect(ctrl.state.items.single.exercise.ref, _catalogExercise().ref);
    expect(ctrl.select(_customExercise().ref), isNull);
  });

  test('Custom read failure fails closed, then Retry loads both sources',
      () async {
    var attempts = 0;
    final user = _User(() async {
      if (attempts++ == 0) throw StateError('not signed in');
      return [_customExercise()];
    });
    final ctrl = RoutineExercisePickerController(
      catalogRepository: _catalog(),
      userExerciseRepository: user,
    );
    addTearDown(ctrl.dispose);

    await ctrl.load();
    expect(ctrl.state.status, RoutineExercisePickerStatus.failed);
    expect(ctrl.state.items, isEmpty);
    expect(ctrl.select(_catalogExercise().ref), isNull);
    await ctrl.load();
    expect(ctrl.state.status, RoutineExercisePickerStatus.ready);
    expect(ctrl.state.items.length, 2);
    expect(user.listCalls, 2);
  });

  test('invalid foreign-shaped or duplicated owner refs fail closed', () async {
    for (final invalid in [
      [_catalogExercise()],
      [_customExercise(), _customExercise()],
    ]) {
      final ctrl = RoutineExercisePickerController(
        catalogRepository: _catalog(),
        userExerciseRepository: _User(() async => invalid),
      );
      await ctrl.load();
      expect(ctrl.state.status, RoutineExercisePickerStatus.failed);
      expect(ctrl.state.items, isEmpty);
      ctrl.dispose();
    }
  });

  test('late old source load cannot overwrite newer results', () async {
    final held = Completer<ExerciseCatalog>();
    var calls = 0;
    final ctrl = RoutineExercisePickerController(
      catalogRepository: _Catalog(() {
        if (calls++ == 0) return held.future;
        return Future.value(ExerciseCatalog([_catalogExercise()]));
      }),
    );
    addTearDown(ctrl.dispose);

    final first = ctrl.load();
    await ctrl.load();
    expect(ctrl.state.status, RoutineExercisePickerStatus.ready);
    held.complete(ExerciseCatalog(const []));
    await first;
    expect(ctrl.state.items.single.exercise.ref, _catalogExercise().ref);
  });

  testWidgets('search, pick Custom result and return without persistence',
      (tester) async {
    Exercise? selected;
    final catalog = _catalog();
    final user = _User(() async => [_customExercise()]);
    await _pumpLauncher(
      tester,
      catalog: catalog,
      user: user,
      onResult: (result) => selected = result,
    );
    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-exercise-picker-page')),
        findsOneWidget);
    expect(find.text('My Lift'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('routine-exercise-picker-search')),
      'my',
    );
    await tester.pumpAndSettle();
    expect(find.text('Bench Press'), findsNothing);
    await tester.tap(find.text('My Lift'));
    await tester.pumpAndSettle();
    expect(selected?.ref, _customExercise().ref);
    expect(user.listCalls, 1);
    expect(user.writeCalls, 0);
  });

  testWidgets('Back cancels selection, no database write', (tester) async {
    Exercise? selected;
    var returned = false;
    final user = _User(() async => [_customExercise()]);
    await _pumpLauncher(
      tester,
      catalog: _catalog(),
      user: user,
      onResult: (result) {
        returned = true;
        selected = result;
      },
      mode: TioThemeMode.dark,
    );
    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(returned, isTrue);
    expect(selected, isNull);
    expect(user.writeCalls, 0);
  });

  testWidgets('source error disables selection until retry', (tester) async {
    var reads = 0;
    final catalog = _Catalog(() async {
      if (reads++ == 0) throw StateError('offline');
      return ExerciseCatalog([_catalogExercise()]);
    });
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.light),
          child: child ?? const SizedBox.shrink(),
        ),
        home: RoutineExercisePickerPage(catalogRepository: catalog),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-exercise-picker-failed')),
        findsOneWidget);
    expect(find.text('Bench Press'), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('routine-exercise-picker-retry')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bench Press'), findsOneWidget);
  });
}

Future<void> _pumpLauncher(
  WidgetTester tester, {
  required ExerciseCatalogRepository catalog,
  required UserExerciseRepository user,
  required void Function(Exercise?) onResult,
  TioThemeMode mode = TioThemeMode.light,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: mode),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            child: const Text('Open picker'),
            onPressed: () async {
              final result = await Navigator.of(context).push<Exercise>(
                MaterialPageRoute(
                  builder: (_) => RoutineExercisePickerPage(
                    catalogRepository: catalog,
                    userExerciseRepository: user,
                  ),
                ),
              );
              onResult(result);
            },
          ),
        ),
      ),
    ),
  );
}

final class _Catalog implements ExerciseCatalogRepository {
  _Catalog(this.fetch);

  final Future<ExerciseCatalog> Function() fetch;

  @override
  Future<ExerciseCatalog> load() => fetch();
}

final class _User implements UserExerciseRepository {
  _User(this.fetch);

  final Future<List<Exercise>> Function() fetch;
  int listCalls = 0;
  int writeCalls = 0;

  @override
  Future<List<Exercise>> list({bool includeArchived = false}) {
    listCalls++;
    return fetch();
  }

  @override
  Future<void> create({
    required UserCreatedExerciseRef id,
    required String displayName,
    CatalogExerciseRef? basedOnCatalogExercise,
    UserExerciseDefinition? definition,
  }) async {
    writeCalls++;
    throw UnimplementedError();
  }

  @override
  Future<void> updateDefinition({
    required UserCreatedExerciseRef id,
    required UserExerciseDefinition definition,
  }) async {
    writeCalls++;
    throw UnimplementedError();
  }

  @override
  Future<void> rename({
    required UserCreatedExerciseRef id,
    required String displayName,
  }) async {
    writeCalls++;
    throw UnimplementedError();
  }

  @override
  Future<void> archive(UserCreatedExerciseRef id) async {
    writeCalls++;
    throw UnimplementedError();
  }
}
