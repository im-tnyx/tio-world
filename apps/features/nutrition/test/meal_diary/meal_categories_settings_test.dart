import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

/// Records every repository call so a test can assert what did *not* happen —
/// most importantly that opening the screen never writes.
class _RecordingRepository implements MealCategoriesRepository {
  _RecordingRepository({MealCategoriesConfig? stored}) : _stored = stored;

  MealCategoriesConfig? _stored;
  int reads = 0;
  int writes = 0;
  Object? failNextRead;
  Object? failNextWrite;

  /// When set, `read` waits on it. Without a gate the read resolves in a
  /// microtask and the loading state is never observable.
  Completer<void>? readGate;

  /// Same idea for writes, so the in-flight `saving` state can be inspected.
  Completer<void>? writeGate;

  @override
  Future<MealCategoriesConfig> read() async {
    reads++;
    final gate = readGate;
    if (gate != null) await gate.future;
    final failure = failNextRead;
    if (failure != null) {
      failNextRead = null;
      throw failure;
    }
    return MealCategoriesConfig.resolve(_stored);
  }

  @override
  Future<void> upsert(MealCategoriesConfig config) async {
    writes++;
    final gate = writeGate;
    if (gate != null) await gate.future;
    final failure = failNextWrite;
    if (failure != null) {
      failNextWrite = null;
      throw failure;
    }
    config.validate();
    final previous = _stored;
    if (previous != null) {
      MealCategoriesTransitionPolicy.validate(previous: previous, next: config);
    }
    _stored = config;
  }
}

/// Deterministic identities so a test can assert an exact generated id without
/// depending on real UUID output.
class _SequenceIdGenerator implements MealCategoryIdGenerator {
  int _next = 0;

  static const _suffixes = [
    '11111111-1111-4111-8111-111111111111',
    '22222222-2222-4222-8222-222222222222',
    '33333333-3333-4333-8333-333333333333',
    '44444444-4444-4444-8444-444444444444',
    '55555555-5555-4555-8555-555555555555',
  ];

  @override
  String generate(Iterable<String> retainedIds) {
    final retained = retainedIds.toSet();
    while (_next < _suffixes.length) {
      final candidate = 'meal_slot_${_suffixes[_next++]}';
      if (!retained.contains(candidate)) return candidate;
    }
    throw StateError('sequence exhausted');
  }
}

MealCategory _category({
  required String id,
  required String displayName,
  required int order,
  MealCategoryDefaultKey? defaultKey,
  bool active = true,
}) =>
    MealCategory(
      id: id,
      defaultKey: defaultKey,
      displayName: displayName,
      active: active,
      order: order,
    );

/// Canonical four plus [extra] custom actives, and any [archived] items.
MealCategoriesConfig _config({
  int extraActive = 0,
  List<String> archived = const [],
}) {
  final items = <MealCategory>[
    _category(
      id: 'meal_slot_1',
      defaultKey: MealCategoryDefaultKey.breakfast,
      displayName: 'Breakfast',
      order: 0,
    ),
    _category(
      id: 'meal_slot_2',
      defaultKey: MealCategoryDefaultKey.lunch,
      displayName: 'Lunch',
      order: 1,
    ),
    _category(
      id: 'meal_slot_3',
      defaultKey: MealCategoryDefaultKey.dinner,
      displayName: 'Dinner',
      order: 2,
    ),
    _category(
      id: 'meal_slot_4',
      defaultKey: MealCategoryDefaultKey.snacks,
      displayName: 'Snacks',
      order: 3,
    ),
  ];
  var order = 4;
  for (var index = 0; index < extraActive; index++) {
    items.add(
      _category(
        id: 'meal_slot_aaaaaaaa-aaaa-4aaa-8aaa-00000000000$index',
        displayName: 'Custom $index',
        order: order++,
      ),
    );
  }
  for (var index = 0; index < archived.length; index++) {
    items.add(
      _category(
        id: 'meal_slot_bbbbbbbb-bbbb-4bbb-8bbb-00000000000$index',
        displayName: archived[index],
        order: order++,
        active: false,
      ),
    );
  }
  return MealCategoriesConfig(items: items);
}

Widget _host(
  Widget child, {
  TioThemeMode mode = TioThemeMode.light,
  double textScale = 1,
}) =>
    MaterialApp(
      builder: (context, appChild) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: TioTheme(
          config: TioThemeConfig(mode: mode),
          child: appChild ?? const SizedBox.shrink(),
        ),
      ),
      home: child,
    );

Future<_RecordingRepository> _pumpPage(
  WidgetTester tester, {
  MealCategoriesConfig? stored,
  _RecordingRepository? repository,
  TioThemeMode mode = TioThemeMode.light,
  double textScale = 1,
  MealCategoryIdGenerator? idGenerator,
}) async {
  final repo = repository ?? _RecordingRepository(stored: stored);
  await tester.pumpWidget(
    _host(
      MealCategoriesDestinationPage(
        repository: repo,
        idGenerator: idGenerator,
      ),
      mode: mode,
      textScale: textScale,
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

const _activeList = ValueKey('meal-categories-active-list');
const _archivedHeader = ValueKey('meal-categories-archived-header');
const _addButton = ValueKey('meal-categories-add');
const _addCapReason = ValueKey('meal-categories-add-cap-reason');
const _nameField = ValueKey('meal-category-name-field');
const _nameSubmit = ValueKey('meal-category-name-submit');

Future<void> _enterName(WidgetTester tester, String value) async {
  await tester.enterText(find.byKey(_nameField), value);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(_nameSubmit));
  await tester.pumpAndSettle();
}

/// The page's own scroll view. The active list nests a second `Scrollable`
/// inside it, so every scroll helper has to say which one it means.
Finder get _pageScrollable => find.byType(Scrollable).first;

Future<void> _revealAdd(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(_addButton),
    200,
    scrollable: _pageScrollable,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('load', () {
    testWidgets('shows a loading state before the read resolves',
        (tester) async {
      final gate = Completer<void>();
      final repo = _RecordingRepository()..readGate = gate;
      await tester.pumpWidget(
        _host(MealCategoriesDestinationPage(repository: repo)),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('meal-categories-loading')),
        findsOneWidget,
      );
      expect(find.text('Breakfast'), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Breakfast'), findsOneWidget);
    });

    testWidgets('resolves canonical defaults from unstored state and never '
        'writes merely because the screen opened', (tester) async {
      final repo = await _pumpPage(tester);

      for (final name in ['Breakfast', 'Lunch', 'Dinner', 'Snacks']) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      expect(repo.reads, 1);
      expect(
        repo.writes,
        0,
        reason: 'opening the screen must not materialise defaults',
      );
      expect(find.byKey(_archivedHeader), findsNothing);
    });

    testWidgets('a failed read is reported and can be retried',
        (tester) async {
      final repo = _RecordingRepository()
        ..failNextRead = StateError('offline');
      await _pumpPage(tester, repository: repo);

      expect(
        find.byKey(const ValueKey('meal-categories-load-failure')),
        findsOneWidget,
      );
      expect(find.byKey(_activeList), findsNothing);

      await tester.tap(find.byKey(const ValueKey('meal-categories-retry')));
      await tester.pumpAndSettle();

      expect(find.text('Breakfast'), findsOneWidget);
      expect(repo.reads, 2);
      expect(repo.writes, 0);
    });

    testWidgets('internal identity is never rendered', (tester) async {
      await _pumpPage(tester, stored: _config());

      for (final hidden in [
        'meal_slot_1',
        'meal_slot_2',
        'breakfast',
        'schemaVersion',
      ]) {
        expect(find.textContaining(hidden), findsNothing, reason: hidden);
      }
    });
  });

  group('rename', () {
    testWidgets('renames without changing the stable identity', (tester) async {
      final repo = await _pumpPage(tester, stored: _config());

      await tester.tap(
        find.byKey(const ValueKey('meal-category-rename-meal_slot_2')),
      );
      await tester.pumpAndSettle();
      await _enterName(tester, 'Pre Workout');

      expect(find.text('Pre Workout'), findsOneWidget);
      expect(find.text('Lunch'), findsNothing);
      expect(repo.writes, 1);

      final stored = await repo.read();
      final renamed = stored.findById('meal_slot_2');
      expect(renamed, isNotNull);
      expect(renamed!.displayName, 'Pre Workout');
      expect(
        renamed.defaultKey,
        MealCategoryDefaultKey.lunch,
        reason: 'rename changes the label only',
      );
      expect(renamed.order, 1);
      expect(renamed.active, isTrue);
    });

    testWidgets('a blank name cannot be submitted', (tester) async {
      final repo = await _pumpPage(tester, stored: _config());

      await tester.tap(
        find.byKey(const ValueKey('meal-category-rename-meal_slot_1')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(_nameField), '   ');
      await tester.pumpAndSettle();

      expect(
        tester.widget<TioButton>(find.byKey(_nameSubmit)).onPressed,
        isNull,
        reason: 'blank is refused before it can reach the domain',
      );
      expect(repo.writes, 0);
    });

    testWidgets('a normalized duplicate active name is rejected by the domain',
        (tester) async {
      final repo = await _pumpPage(tester, stored: _config());

      await tester.tap(
        find.byKey(const ValueKey('meal-category-rename-meal_slot_2')),
      );
      await tester.pumpAndSettle();
      // Different case and spacing, same normalized name as Breakfast.
      await _enterName(tester, '  breakfast ');

      expect(
        find.text('That name is already used by another active category.'),
        findsOneWidget,
      );
      expect(find.text('Lunch'), findsOneWidget, reason: 'draft not applied');
      final stored = await repo.read();
      expect(stored.findById('meal_slot_2')!.displayName, 'Lunch');
    });
  });

  group('add', () {
    testWidgets('adds a custom category through the domain generator',
        (tester) async {
      final repo = await _pumpPage(
        tester,
        stored: _config(),
        idGenerator: _SequenceIdGenerator(),
      );

      await tester.tap(find.byKey(_addButton));
      await tester.pumpAndSettle();
      await _enterName(tester, 'Pre Workout');

      expect(find.text('Pre Workout'), findsOneWidget);
      final stored = await repo.read();
      final added = stored.activeItems.last;
      expect(added.displayName, 'Pre Workout');
      expect(added.defaultKey, isNull, reason: 'custom categories have no key');
      expect(MealCategoriesPolicy.isValidCustomId(added.id), isTrue);
      // The generated id exists but is not shown anywhere.
      expect(find.textContaining(added.id), findsNothing);
    });
  });

  group('reorder', () {
    testWidgets('moves an active category and renumbers order only',
        (tester) async {
      final repo = await _pumpPage(tester, stored: _config());

      final list = tester.widget<SliverReorderableList>(
        find.byKey(_activeList),
      );
      // Move Breakfast (0) to the end of the four active items.
      list.onReorderItem!(0, 3);
      await tester.pumpAndSettle();

      final stored = await repo.read();
      expect(
        stored.activeItems.map((item) => item.displayName).toList(),
        ['Lunch', 'Dinner', 'Snacks', 'Breakfast'],
      );
      expect(
        stored.activeItems.map((item) => item.order).toList(),
        [0, 1, 2, 3],
        reason: 'orders stay unique and gapless',
      );
      expect(
        stored.findById('meal_slot_1')!.defaultKey,
        MealCategoryDefaultKey.breakfast,
        reason: 'reorder never touches identity',
      );
    });

    testWidgets('reordering active items leaves archived identities alone',
        (tester) async {
      final repo = await _pumpPage(
        tester,
        stored: _config(archived: ['Late Night']),
      );

      final before = await repo.read();
      final archivedBefore =
          before.orderedItems.firstWhere((item) => !item.active);

      tester
          .widget<SliverReorderableList>(find.byKey(_activeList))
          .onReorderItem!(0, 2);
      await tester.pumpAndSettle();

      final after = await repo.read();
      final archivedAfter =
          after.orderedItems.firstWhere((item) => !item.active);
      expect(archivedAfter.id, archivedBefore.id);
      expect(archivedAfter.displayName, archivedBefore.displayName);
      expect(archivedAfter.active, isFalse);
    });
  });

  group('archive and reactivate', () {
    testWidgets('archiving reveals the Archived section and frees a slot',
        (tester) async {
      final repo = await _pumpPage(tester, stored: _config());
      expect(find.byKey(_archivedHeader), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('meal-category-archive-meal_slot_4')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      expect(find.byKey(_archivedHeader), findsOneWidget);
      expect(
        find.byKey(const ValueKey('meal-category-archived-meal_slot_4')),
        findsOneWidget,
      );

      final stored = await repo.read();
      expect(stored.activeItems.length, 3);
      final archived = stored.findById('meal_slot_4');
      expect(archived, isNotNull, reason: 'identity is retained, not deleted');
      expect(archived!.active, isFalse);
      expect(archived.displayName, 'Snacks');
      expect(archived.defaultKey, MealCategoryDefaultKey.snacks);
    });

    testWidgets('an archived row exposes Reactivate and no drag handle',
        (tester) async {
      await _pumpPage(tester, stored: _config(archived: ['Late Night']));

      final archivedRow =
          find.byKey(const ValueKey('meal-category-archived-'
              'meal_slot_bbbbbbbb-bbbb-4bbb-8bbb-000000000000'));
      expect(archivedRow, findsOneWidget);
      expect(
        find.descendant(
          of: archivedRow,
          matching: find.byIcon(Icons.drag_handle_rounded),
        ),
        findsNothing,
        reason: 'archived rows are not reorderable',
      );
      expect(
        find.descendant(of: archivedRow, matching: find.text('Reactivate')),
        findsOneWidget,
      );
      // Active rows still have theirs.
      expect(
        find.byKey(const ValueKey('meal-category-drag-meal_slot_1')),
        findsOneWidget,
      );
    });

    testWidgets('reactivation restores the same identity', (tester) async {
      final repo = await _pumpPage(
        tester,
        stored: _config(archived: ['Late Night']),
      );
      final before = await repo.read();
      final archivedId =
          before.orderedItems.firstWhere((item) => !item.active).id;

      await tester.tap(
        find.byKey(ValueKey('meal-category-reactivate-$archivedId')),
      );
      await tester.pumpAndSettle();

      final after = await repo.read();
      final restored = after.findById(archivedId);
      expect(restored, isNotNull, reason: 'same id, not a new one');
      expect(restored!.active, isTrue);
      expect(restored.displayName, 'Late Night');
      expect(
        after.activeItems.last.id,
        archivedId,
        reason: 'reactivated items land last, deterministically',
      );
      expect(find.byKey(_archivedHeader), findsNothing);
    });
  });

  group('eight active maximum', () {
    testWidgets('Add stays available at seven active', (tester) async {
      await _pumpPage(tester, stored: _config(extraActive: 3));
      await _revealAdd(tester);

      expect(tester.widget<TioButton>(find.byKey(_addButton)).onPressed,
          isNotNull);
      expect(find.byKey(_addCapReason), findsNothing);
    });

    testWidgets('at eight active, Add is unavailable with the exact reason',
        (tester) async {
      await _pumpPage(tester, stored: _config(extraActive: 4));
      await _revealAdd(tester);

      expect(tester.widget<TioButton>(find.byKey(_addButton)).onPressed, isNull);
      expect(
        tester.widget<Text>(find.byKey(_addCapReason)).data,
        'Maximum 8 active meal categories',
      );
    });

    testWidgets('at eight active, Reactivate is unavailable with the reason',
        (tester) async {
      await _pumpPage(
        tester,
        stored: _config(extraActive: 4, archived: ['Late Night']),
      );

      final reactivate = find.byKey(const ValueKey(
        'meal-category-reactivate-meal_slot_bbbbbbbb-bbbb-4bbb-8bbb-'
        '000000000000',
      ));
      await tester.scrollUntilVisible(
        reactivate,
        200,
        scrollable: _pageScrollable,
      );
      await tester.pumpAndSettle();
      expect(reactivate, findsOneWidget);
      expect(tester.widget<TioButton>(reactivate).onPressed, isNull);
      expect(
        tester
            .widget<Text>(find.byKey(
              const ValueKey('meal-categories-reactivate-cap-reason'),
            ))
            .data,
        'Maximum 8 active meal categories',
      );
    });

    testWidgets('archiving from eight frees exactly one slot', (tester) async {
      await _pumpPage(tester, stored: _config(extraActive: 4));
      await _revealAdd(tester);
      expect(tester.widget<TioButton>(find.byKey(_addButton)).onPressed, isNull);

      final archiveSnacks =
          find.byKey(const ValueKey('meal-category-archive-meal_slot_4'));
      await tester.scrollUntilVisible(
        archiveSnacks,
        -200,
        scrollable: _pageScrollable,
      );
      await tester.pumpAndSettle();
      await tester.tap(archiveSnacks);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      await _revealAdd(tester);
      expect(
        tester.widget<TioButton>(find.byKey(_addButton)).onPressed,
        isNotNull,
        reason: 'one slot freed, not more',
      );
    });

    // The disabled button is the visible guard; these cover the controller's
    // own refusal, so removing either one is caught.
    test('the controller refuses to reactivate past the cap', () async {
      final repo = _RecordingRepository(
        stored: _config(extraActive: 4, archived: ['Late Night']),
      );
      final controller = MealCategoriesController(repository: repo);
      addTearDown(controller.dispose);
      await controller.load();

      final archivedId = controller.state.archivedItems.single.id;
      final result = await controller.reactivate(archivedId);

      expect(result, isFalse);
      expect(repo.writes, 0, reason: 'nothing reaches the repository');
      expect(
        controller.state.actionError,
        'Maximum 8 active meal categories',
      );
      expect(controller.state.activeCount, 8);
    });

    test('the controller refuses to add past the cap', () async {
      final repo = _RecordingRepository(stored: _config(extraActive: 4));
      final controller = MealCategoriesController(repository: repo);
      addTearDown(controller.dispose);
      await controller.load();

      final result = await controller.addCustom('Ninth');

      expect(result, isFalse);
      expect(repo.writes, 0);
      expect(
        controller.state.actionError,
        'Maximum 8 active meal categories',
      );
      expect(controller.state.activeCount, 8);
    });

    testWidgets('the domain rejects a ninth active rather than truncating',
        (tester) async {
      // Bypasses the UI guard to prove the invariant is enforced below it.
      final items = _config(extraActive: 4).orderedItems;
      expect(
        () => MealCategoriesConfig(
          items: [
            ...items,
            _category(
              id: 'meal_slot_cccccccc-cccc-4ccc-8ccc-cccccccccccc',
              displayName: 'Ninth',
              order: 99,
            ),
          ],
        ),
        throwsA(
          isA<MealCategoriesValidationException>().having(
            (error) => error.code,
            'code',
            MealCategoriesValidationCode.tooManyActiveCategories,
          ),
        ),
      );
    });
  });

  group('failure safety', () {
    testWidgets('a failed write keeps the previous confirmed state and retries',
        (tester) async {
      final repo = _RecordingRepository(stored: _config());
      await _pumpPage(tester, repository: repo);

      repo.failNextWrite = StateError('network down');
      await tester.tap(
        find.byKey(const ValueKey('meal-category-rename-meal_slot_2')),
      );
      await tester.pumpAndSettle();
      await _enterName(tester, 'Pre Workout');

      expect(find.text('Could not save your change.'), findsOneWidget);
      expect(
        find.text('Lunch'),
        findsOneWidget,
        reason: 'confirmed state is untouched by a failed write',
      );
      expect(find.text('Pre Workout'), findsNothing);
      expect((await repo.read()).findById('meal_slot_2')!.displayName, 'Lunch');

      // The same edit succeeds once the repository recovers.
      await tester.tap(
        find.byKey(const ValueKey('meal-category-rename-meal_slot_2')),
      );
      await tester.pumpAndSettle();
      await _enterName(tester, 'Pre Workout');

      expect(find.text('Pre Workout'), findsOneWidget);
      expect((await repo.read()).findById('meal_slot_2')!.displayName,
          'Pre Workout');
    });

    testWidgets('a repository rejection is surfaced, not swallowed',
        (tester) async {
      final repo = _RecordingRepository(stored: _config());
      await _pumpPage(tester, repository: repo);

      repo.failNextWrite = const MealCategoriesValidationException(
        code: MealCategoriesValidationCode.retainedIdentityRemoved,
        message: 'internal detail that must not be shown',
      );
      await tester.tap(
        find.byKey(const ValueKey('meal-category-archive-meal_slot_3')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'That category is kept for your meal history and cannot be removed.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('internal detail'), findsNothing);
      expect(find.byKey(_archivedHeader), findsNothing);
    });
  });

  group('review findings', () {
    testWidgets('a rename that changes nothing does not write',
        (tester) async {
      // Persisting here would materialise a customized configuration out of an
      // unstored one, and that user would silently stop inheriting future
      // canonical default updates.
      final repo = await _pumpPage(tester);
      expect(repo.writes, 0);

      await tester.tap(
        find.byKey(const ValueKey('meal-category-rename-meal_slot_1')),
      );
      await tester.pumpAndSettle();
      await _enterName(tester, 'Breakfast');

      expect(repo.writes, 0, reason: 'no visible edit, no persisted config');
      expect(find.text('Breakfast'), findsOneWidget);
    });

    test('reactivation lands last even when the archived order is low',
        () async {
      // The domain only requires orders to be unique and non-negative, so an
      // archived category can legitimately hold a lower order than the active
      // ones. Sorting alone would drop it back into the middle of the list.
      final repo = _RecordingRepository(
        stored: MealCategoriesConfig(
          items: [
            _category(
              id: 'meal_slot_bbbbbbbb-bbbb-4bbb-8bbb-000000000000',
              displayName: 'Late Night',
              order: 0,
              active: false,
            ),
            _category(
              id: 'meal_slot_1',
              defaultKey: MealCategoryDefaultKey.breakfast,
              displayName: 'Breakfast',
              order: 1,
            ),
            _category(
              id: 'meal_slot_2',
              defaultKey: MealCategoryDefaultKey.lunch,
              displayName: 'Lunch',
              order: 2,
            ),
            _category(
              id: 'meal_slot_3',
              defaultKey: MealCategoryDefaultKey.dinner,
              displayName: 'Dinner',
              order: 3,
            ),
            _category(
              id: 'meal_slot_4',
              defaultKey: MealCategoryDefaultKey.snacks,
              displayName: 'Snacks',
              order: 4,
            ),
          ],
        ),
      );
      final controller = MealCategoriesController(repository: repo);
      addTearDown(controller.dispose);
      await controller.load();

      final archivedId = controller.state.archivedItems.single.id;
      expect(await controller.reactivate(archivedId), isTrue);

      expect(
        controller.state.activeItems.map((item) => item.displayName).toList(),
        ['Breakfast', 'Lunch', 'Dinner', 'Snacks', 'Late Night'],
        reason: 'reactivated categories append after every active item',
      );
      expect(controller.state.activeItems.last.id, archivedId);
    });

    test('a read-time validation failure gets read-time copy', () async {
      final repo = _RecordingRepository()
        ..failNextRead = const MealCategoriesValidationException(
          code: MealCategoriesValidationCode.blankDisplayName,
          message: 'internal',
        );
      final controller = MealCategoriesController(repository: repo);
      addTearDown(controller.dispose);
      await controller.load();

      expect(controller.state.status, MealCategoriesStatus.loadFailed);
      // The mutation copy for this code is "Enter a category name.", which is
      // advice a reader cannot act on with no editor open.
      expect(controller.state.loadError, isNot(contains('Enter a category')));
      expect(controller.state.loadError, contains('could not be read'));
    });

    test('an unsupported schema version explains what to do', () async {
      final repo = _RecordingRepository()
        ..failNextRead = const MealCategoriesValidationException(
          code: MealCategoriesValidationCode.unsupportedSchemaVersion,
          message: 'internal',
        );
      final controller = MealCategoriesController(repository: repo);
      addTearDown(controller.dispose);
      await controller.load();

      expect(controller.state.loadError, contains('Update Tio'));
    });

    test('a failed write is retryable without repeating the action', () async {
      final repo = _RecordingRepository(stored: _config());
      final controller = MealCategoriesController(repository: repo);
      addTearDown(controller.dispose);
      await controller.load();

      repo.failNextWrite = StateError('offline');
      expect(
        await controller.rename(id: 'meal_slot_2', displayName: 'Pre Workout'),
        isFalse,
      );
      expect(controller.state.canRetryAction, isTrue);
      expect(
        controller.state.confirmed!.findById('meal_slot_2')!.displayName,
        'Lunch',
        reason: 'confirmed state is untouched by a failed write',
      );

      // The retry replays the attempt itself, so the typed name is not lost.
      expect(await controller.retryPendingAction(), isTrue);
      expect(
        controller.state.confirmed!.findById('meal_slot_2')!.displayName,
        'Pre Workout',
      );
      expect(controller.state.canRetryAction, isFalse);
      expect(controller.state.actionError, isNull);
    });

    test('a rejected configuration is not offered as a retry', () async {
      // Replaying it would fail identically, so only transport-shaped
      // failures are retryable.
      final repo = _RecordingRepository(stored: _config());
      final controller = MealCategoriesController(repository: repo);
      addTearDown(controller.dispose);
      await controller.load();

      repo.failNextWrite = const MealCategoriesValidationException(
        code: MealCategoriesValidationCode.retainedIdentityRemoved,
        message: 'internal',
      );
      expect(await controller.archive('meal_slot_3'), isFalse);

      expect(controller.state.canRetryAction, isFalse);
      expect(controller.state.actionError, isNotNull);
    });

    testWidgets('the failure snack bar offers Retry and it succeeds',
        (tester) async {
      final repo = _RecordingRepository(stored: _config());
      await _pumpPage(tester, repository: repo);

      repo.failNextWrite = StateError('offline');
      await tester.tap(
        find.byKey(const ValueKey('meal-category-rename-meal_slot_2')),
      );
      await tester.pumpAndSettle();
      await _enterName(tester, 'Pre Workout');

      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Pre Workout'), findsOneWidget);
      expect(
        (await repo.read()).findById('meal_slot_2')!.displayName,
        'Pre Workout',
      );
    });

    testWidgets('controls read as disabled while a write is in flight',
        (tester) async {
      final repo = _RecordingRepository(stored: _config());
      final controller = MealCategoriesController(repository: repo);
      addTearDown(controller.dispose);

      final gate = Completer<void>();
      repo.writeGate = gate;

      await tester.pumpWidget(
        _host(
          MealCategoriesDestinationPage(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Start a write and hold it open.
      await tester.tap(
        find.byKey(const ValueKey('meal-category-archive-meal_slot_4')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
      await tester.pump();

      final renameIcon = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(const ValueKey('meal-category-rename-meal_slot_1')),
          matching: find.byType(Icon),
        ),
      );
      expect(
        renameIcon.color,
        TioColors.light.textMuted,
        reason: 'a control that ignores taps must not look tappable',
      );
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('meal-category-rename-meal_slot_1')),
            )
            .onPressed,
        isNull,
      );

      gate.complete();
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<Icon>(
              find.descendant(
                of: find.byKey(
                  const ValueKey('meal-category-rename-meal_slot_1'),
                ),
                matching: find.byType(Icon),
              ),
            )
            .color,
        TioColors.light.textSecondary,
        reason: 'and it returns to normal once the write finishes',
      );
    });

    testWidgets('the active list is a sliver in the page scroll view',
        (tester) async {
      // A shrink-wrapped reorderable list nested in another scroll view has no
      // scroll extent of its own, so a drag toward an off-screen position
      // cannot auto-scroll. Eight rows on a short viewport is exactly that
      // case, so the reorderable surface has to be the real viewport.
      tester.view.physicalSize = const Size(390, 560);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpPage(tester, stored: _config(extraActive: 4));

      expect(find.byType(SliverReorderableList), findsOneWidget);
      expect(find.byType(ReorderableListView), findsNothing);

      final scrollables = find.byType(Scrollable).evaluate();
      expect(
        scrollables.length,
        1,
        reason: 'exactly one scroll view, so a drag can auto-scroll it',
      );

      // And that one viewport genuinely scrolls with eight rows on screen.
      // The offset is the assertion rather than a row's position: a lazy
      // sliver destroys rows once they leave the viewport, so a scrolled-away
      // row cannot be measured. Dragged on a row because a sliver has no
      // RenderBox of its own to target.
      final position =
          tester.state<ScrollableState>(find.byType(Scrollable)).position;
      expect(position.pixels, 0);
      expect(
        position.maxScrollExtent,
        greaterThan(0),
        reason: 'eight rows do not fit, so there is somewhere to scroll to',
      );

      await tester.drag(find.text('Lunch'), const Offset(0, -150));
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
    });
  });

  group('presentation', () {
    for (final testCase in const [
      (name: 'Light', mode: TioThemeMode.light, expected: TioColors.light),
      (name: 'Dark', mode: TioThemeMode.dark, expected: TioColors.dark),
      (name: 'OLED', mode: TioThemeMode.oled, expected: TioColors.oled),
      (
        name: 'System-dark',
        mode: TioThemeMode.system,
        expected: TioColors.dark
      ),
    ]) {
      testWidgets('${testCase.name} resolves and fits a compact phone',
          (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.platformBrightnessTestValue =
            Brightness.dark;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(
          tester.platformDispatcher.clearPlatformBrightnessTestValue,
        );

        await _pumpPage(
          tester,
          stored: _config(archived: ['Late Night']),
          mode: testCase.mode,
          textScale: 1.6,
        );

        final scaffold = tester.widget<Scaffold>(
          find.byKey(const ValueKey('meal-categories-destination-page')),
        );
        expect(scaffold.backgroundColor, testCase.expected.background);
        expect(find.byKey(_archivedHeader), findsOneWidget);
        expect(tester.takeException(), isNull, reason: testCase.name);
      });
    }

    testWidgets('controls carry reachable labels and tap targets',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpPage(tester, stored: _config(archived: ['Late Night']));

      for (final key in const [
        ValueKey('meal-category-rename-meal_slot_1'),
        ValueKey('meal-category-archive-meal_slot_1'),
      ]) {
        final size = tester.getSize(find.byKey(key));
        expect(size.width, greaterThanOrEqualTo(kMinInteractiveDimension));
        expect(size.height, greaterThanOrEqualTo(kMinInteractiveDimension));
      }

      expect(find.bySemanticsLabel('Reorder Breakfast'), findsOneWidget);
      expect(find.byTooltip('Rename Breakfast'), findsOneWidget);
      expect(find.byTooltip('Archive Breakfast'), findsOneWidget);
      semantics.dispose();
    });
  });
}
