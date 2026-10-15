import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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


  testWidgets('multi Add hides zero footer and preserves ordered selection '
      'across search and deselection', (tester) async {
    final chosen = <Exercise>[];
    final user = _User(() async => [_customExercise()]);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.dark),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push<List<Exercise>>(
              MaterialPageRoute(
                builder: (routeContext) => ProviderScope(
                  child: ExercisesPage(
                    catalogRepository: _catalog(),
                    userExerciseRepository: user,
                    onExercisesAdded: (selected) {
                      chosen.addAll(selected);
                      Navigator.of(routeContext).pop<List<Exercise>>(selected);
                    },
                  ),
                ),
              ),
            ),
            child: const Text('Open batch'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Open batch'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('exercises-add-selected')), findsNothing);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    await tester.tap(find.byKey(const ValueKey('exercise-row-ex_bench_press')));
    await tester.pumpAndSettle();
    expect(find.text('Add 1 exercise'), findsOneWidget);
    final selectedBadge = find.byKey(
      const ValueKey('exercise-selected-ex_bench_press'));
    expect(selectedBadge, findsOneWidget);
    expect(tester.getSize(selectedBadge), const Size(18, 18));
    expect(tester.widget<Icon>(
      find.descendant(of: selectedBadge, matching: find.byType(Icon)),
    ).size, TioSize.dp12);
    await tester.tap(find.byKey(const ValueKey('exercise-row-ex_bench_press')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('exercises-add-selected')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('exercise-row-ex_bench_press')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercises-search-open')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('exercises-search')), 'my');
    await tester.pumpAndSettle();
    expect(find.text('Bench Press'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('exercise-row-$_customId')));
    await tester.pumpAndSettle();
    expect(find.text('Add 2 exercises'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();
    expect(chosen.map((e) => e.ref).toList(), [
      _catalogExercise().ref,
      _customExercise().ref,
    ]);
    expect(user.writeCalls, 0);
  });

  testWidgets('selected thumbnail badge hugs the image top-right rim',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.dark),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: ExerciseListRow(
          item: ExerciseListItem(
            exercise: _catalogExercise(),
            thumbnailUrl: Uri.parse('https://example.invalid/bench.png'),
            metadata: 'Chest',
          ),
          selectionMode: true,
          isSelected: true,
          onTap: () {},
        ),
      ),
    ));
    const key = ValueKey('exercise-selected-ex_bench_press');
    final marker = find.byKey(key);
    expect(marker, findsOneWidget);
    expect(tester.getSize(marker), const Size(18, 18));
    final parent = tester.widget<Positioned>(
      find.ancestor(of: marker, matching: find.byType(Positioned)).first,
    );
    // Thumbnail reserves 12dp for the text gap. Moving to right=4dp
    // places the 18dp check at its corner without shifting the row.
    expect(parent.top, -TioSpacing.xs);
    expect(parent.right, TioSpacing.xs);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
  });


  testWidgets('selected failed-network thumbnail keeps its badge visible',
      (tester) async {
    // Widget tests cannot successfully load external network images.
    // The failure state must not collapse the badge's Stack to zero size.
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.dark),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: ExerciseListRow(
          item: ExerciseListItem(
            exercise: _catalogExercise(),
            thumbnailUrl: Uri.parse('https://example.invalid/bench.png'),
            metadata: 'Chest',
          ),
          selectionMode: true,
          isSelected: true,
          onTap: () {},
        ),
      ),
    ));
    await tester.pumpAndSettle();
    const key = ValueKey('exercise-selected-ex_bench_press');
    final selected = find.byKey(key);
    expect(selected, findsOneWidget);
    expect(tester.getSize(selected), const Size(18, 18));
    final stack = find.ancestor(of: selected, matching: find.byType(Stack)).first;
    expect(tester.getSize(stack).width, greaterThanOrEqualTo(68));
    expect(tester.getSize(stack).height, greaterThanOrEqualTo(56));
    expect(tester.getRect(selected).left,
        greaterThanOrEqualTo(tester.getRect(stack).left));
    expect(find.text('Bench Press'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
    expect(find.byKey(const ValueKey('exercises-page')), findsOneWidget);
    expect(find.text('Add Exercise'), findsOneWidget);
    expect(find.byKey(const ValueKey('custom-exercise-create')), findsNothing);
    expect(find.text('My Lift'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('exercises-search-open')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('exercises-search')),
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

  testWidgets('Add Exercise title and catalog row select canonical Exercise',
      (tester) async {
    Exercise? selected;
    final user = _User(() async => []);
    await _pumpLauncher(
      tester,
      catalog: _catalog(),
      user: user,
      onResult: (result) => selected = result,
    );
    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();
    expect(find.byType(ExercisesPage), findsOneWidget);
    expect(find.text('Add Exercise'), findsOneWidget);
    expect(find.byKey(const ValueKey('custom-exercise-create')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('exercise-row-ex_bench_press')));
    await tester.pumpAndSettle();
    expect(selected?.ref, _catalogExercise().ref);
    expect(user.writeCalls, 0);
  });

  testWidgets('Custom read failure hides all selectable Exercise rows',
      (tester) async {
    Exercise? selected;
    final user = _User(() async => throw StateError('unavailable'));
    await _pumpLauncher(
      tester,
      catalog: _catalog(),
      user: user,
      onResult: (result) => selected = result,
    );
    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();
    expect(find.byType(ExercisesPage), findsOneWidget);
    expect(find.text('Bench Press'), findsNothing);
    expect(find.byKey(const ValueKey('exercises-list')), findsNothing);
    expect(find.textContaining('Could not load custom exercises'),
        findsOneWidget);
    expect(selected, isNull);
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

  testWidgets('source failure never exposes a partial selectable list',
      (tester) async {
    final catalog = _Catalog(() async {
      throw StateError('offline');
    });
    final picked = <Exercise>[];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          builder: (context, child) => TioTheme(
            config: const TioThemeConfig(mode: TioThemeMode.light),
            child: child ?? const SizedBox.shrink(),
          ),
          home: ExercisesPage(
            catalogRepository: catalog,
            onExerciseSelected: picked.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('exercises-page')), findsOneWidget);
    expect(find.text(ExercisesPage.failedMessage), findsOneWidget);
    expect(find.text('Bench Press'), findsNothing);
    expect(find.byKey(const ValueKey('exercises-list')), findsNothing);
    expect(picked, isEmpty);
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
                  builder: (routeContext) => ProviderScope(
                    child: ExercisesPage(
                      catalogRepository: catalog,
                      userExerciseRepository: user,
                      onExerciseSelected: (exercise) =>
                          Navigator.of(routeContext).pop<Exercise>(exercise),
                    ),
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
