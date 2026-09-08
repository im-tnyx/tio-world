import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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
  Future<void> Function()? onArchivedPressed,
}) async {
  final repo = repository ?? _RecordingRepository(stored: stored);
  await tester.pumpWidget(
    _host(
      MealCategoriesDestinationPage(
        repository: repo,
        idGenerator: idGenerator,
        onArchivedPressed: onArchivedPressed ?? () async {},
      ),
      mode: mode,
      textScale: textScale,
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

const _activeList = ValueKey('meal-categories-active-list');
const _addButton = ValueKey('meal-categories-add');
const _addCapReason = ValueKey('meal-categories-add-cap-reason');
const _archivedEntry = ValueKey('meal-categories-archived-entry');
ValueKey<String> _swipeAction(String id) =>
    ValueKey('meal-category-swipe-action-$id');

ValueKey<String> _swipeRow(String id) => ValueKey('meal-category-swipe-$id');
const _nameField = ValueKey('meal-category-name-field');
const _nameSubmit = ValueKey('meal-category-name-submit');

Future<void> _enterName(WidgetTester tester, String value) async {
  await tester.enterText(find.byKey(_nameField), value);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(_nameSubmit));
  await tester.pumpAndSettle();
}

/// The page's own scroll view. The active list is a sliver inside it.
Finder get _pageScrollable => find.byType(Scrollable).first;

Future<void> _revealAdd(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(_addButton),
    200,
    scrollable: _pageScrollable,
  );
  await tester.pumpAndSettle();
}

/// Swipes a row left far enough to settle open, the way a reader would.
Future<void> _swipeOpen(WidgetTester tester, String name) async {
  await tester.drag(find.text(name), const Offset(-90, 0));
  await tester.pumpAndSettle();
}

Future<void> _confirmArchive(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(_swipeAction(id)));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Archive'));
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

    testWidgets('resolves canonical defaults and never writes on open',
        (tester) async {
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

  group('row contents', () {
    testWidgets('a row shows a drag handle, a name and an edit action',
        (tester) async {
      await _pumpPage(tester, stored: _config());

      expect(
        find.byKey(const ValueKey('meal-category-drag-meal_slot_1')),
        findsOneWidget,
      );
      expect(find.text('Breakfast'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('meal-category-rename-meal_slot_1')),
        findsOneWidget,
      );
    });

    testWidgets('no permanent archive button sits in the row', (tester) async {
      await _pumpPage(tester, stored: _config());

      // Archive is a swipe action now. The action exists behind each row, but
      // at rest it is fully transparent and unreachable, so nothing
      // archive-shaped is offered in the row itself.
      expect(
        find.byKey(const ValueKey('meal-category-archive-meal_slot_1')),
        findsNothing,
        reason: 'the old always-visible archive button is gone',
      );
      expect(
        tester
            .widget<IconButton>(find.byKey(_swipeAction('meal_slot_1')))
            .onPressed,
        isNull,
      );
      final veil = tester.widget<Opacity>(
        find
            .ancestor(
              of: find.byKey(_swipeAction('meal_slot_1')),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(veil.opacity, 0, reason: 'and it is not visible at rest');

      // The row's own trailing control is the pencil, nothing else.
      final rowIcons = tester
          .widgetList<Icon>(
            find.descendant(
              of: find.byKey(const ValueKey('meal-category-active-meal_slot_1')),
              matching: find.byType(Icon),
            ),
          )
          .map((icon) => icon.icon)
          .toList();
      expect(rowIcons, [Icons.drag_handle_rounded, Icons.edit_outlined]);
    });

    testWidgets('rows are separated by an inset rule, with none after the last',
        (tester) async {
      await _pumpPage(tester, stored: _config());

      final dividers = find.byWidgetPredicate((widget) =>
          widget is Divider &&
          widget.key.toString().contains('meal-category-divider'));
      expect(
        dividers,
        findsNWidgets(3),
        reason: 'four rows means three rules, and none under the last',
      );
      expect(
        find.byKey(const ValueKey('meal-category-divider-meal_slot_4')),
        findsNothing,
        reason: 'the card edge ends the list',
      );

      // Inset rather than full-bleed: the rule starts at the content, leaving
      // the drag-handle column clear.
      final divider = tester.widget<Divider>(dividers.first);
      expect(divider.indent, greaterThan(TioSpacing.lg));
      expect(divider.endIndent, greaterThan(0));
      expect(divider.color, isNot(TioPalette.transparent));
    });
  });

  group('archive by swipe', () {
    testWidgets('a left swipe reveals the archive action', (tester) async {
      await _pumpPage(tester, stored: _config());

      expect(
        tester.widget<IconButton>(find.byKey(_swipeAction('meal_slot_2'))).onPressed,
        isNull,
        reason: 'not reachable while closed',
      );

      await _swipeOpen(tester, 'Lunch');

      expect(
        tester.widget<IconButton>(find.byKey(_swipeAction('meal_slot_2'))).onPressed,
        isNotNull,
      );
    });

    testWidgets('the swipe alone never archives', (tester) async {
      final repo = await _pumpPage(tester, stored: _config());

      await _swipeOpen(tester, 'Lunch');

      expect(repo.writes, 0, reason: 'revealing is not deciding');
      expect(find.text('Lunch'), findsOneWidget);
    });

    testWidgets('the row settles open rather than dismissing', (tester) async {
      await _pumpPage(tester, stored: _config());

      final nameBefore = tester.getTopLeft(find.text('Lunch')).dx;

      // A hard fling must not throw the row off screen.
      await tester.fling(find.text('Lunch'), const Offset(-500, 0), 2000);
      await tester.pumpAndSettle();

      expect(find.text('Lunch'), findsOneWidget, reason: 'still on screen');
      expect(
        tester.getTopLeft(find.text('Lunch')).dx,
        nameBefore,
        reason: 'the row compresses, so the name never moves or truncates',
      );
      // The reveal is clamped: even a hard fling opens exactly one action.
      expect(
        tester.getSize(find.byKey(_swipeAction('meal_slot_2'))).width,
        lessThanOrEqualTo(MealCategorySwipeRow.revealWidth),
      );
    });

    testWidgets('tapping the revealed action asks before archiving',
        (tester) async {
      final repo = await _pumpPage(tester, stored: _config());

      await _swipeOpen(tester, 'Lunch');
      await tester.tap(find.byKey(_swipeAction('meal_slot_2')));
      await tester.pumpAndSettle();

      expect(find.text('Archive "Lunch"?'), findsOneWidget);
      expect(repo.writes, 0, reason: 'asking is not archiving');
    });

    testWidgets('cancelling keeps the category active', (tester) async {
      final repo = await _pumpPage(tester, stored: _config());

      await _swipeOpen(tester, 'Lunch');
      await tester.tap(find.byKey(_swipeAction('meal_slot_2')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repo.writes, 0);
      expect(find.text('Lunch'), findsOneWidget);
      expect((await repo.read()).findById('meal_slot_2')!.active, isTrue);
    });

    testWidgets('confirming archives through the domain and retains identity',
        (tester) async {
      final repo = await _pumpPage(tester, stored: _config());

      await _swipeOpen(tester, 'Lunch');
      await _confirmArchive(tester, 'meal_slot_2');

      expect(find.text('Lunch'), findsNothing, reason: 'no longer active');
      final stored = await repo.read();
      final archived = stored.findById('meal_slot_2');
      expect(archived, isNotNull, reason: 'identity retained, not deleted');
      expect(archived!.active, isFalse);
      expect(archived.defaultKey, MealCategoryDefaultKey.lunch);
      expect(stored.activeItems.length, 3);
    });

    testWidgets('only one row stays revealed at a time', (tester) async {
      await _pumpPage(tester, stored: _config());

      await _swipeOpen(tester, 'Lunch');
      await _swipeOpen(tester, 'Dinner');

      // The first row closes, so exactly one action is reachable.
      expect(
        tester
            .widget<IconButton>(find.byKey(_swipeAction('meal_slot_2')))
            .onPressed,
        isNull,
        reason: 'revealing the second closes the first',
      );
      expect(
        tester
            .widget<IconButton>(find.byKey(_swipeAction('meal_slot_3')))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('archive is reachable without the gesture', (tester) async {
      final semantics = tester.ensureSemantics();
      final repo = await _pumpPage(tester, stored: _config());

      // A screen-reader user invokes the custom action directly.
      final node = tester.getSemantics(find.byKey(_swipeRow('meal_slot_2')));
      final ids = node.getSemanticsData().customSemanticsActionIds ?? const [];
      expect(
        ids
            .map((id) => CustomSemanticsAction.getAction(id)?.label)
            .whereType<String>(),
        contains('Archive meal category'),
      );
      expect(repo.writes, 0);
      semantics.dispose();
    });
  });

  group('archived destination', () {
    testWidgets('the top bar opens archived categories', (tester) async {
      var opened = 0;
      await _pumpPage(
        tester,
        stored: _config(),
        onArchivedPressed: () async => opened++,
      );

      final entry = find.byKey(_archivedEntry);
      expect(entry, findsOneWidget);
      expect(find.byTooltip('Archived meal categories'), findsOneWidget);
      final size = tester.getSize(entry);
      expect(size.width, greaterThanOrEqualTo(kMinInteractiveDimension));
      expect(size.height, greaterThanOrEqualTo(kMinInteractiveDimension));

      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(opened, 1);
    });

    testWidgets('archived categories are not listed on the active screen',
        (tester) async {
      await _pumpPage(tester, stored: _config(archived: ['Late Night']));

      expect(find.text('Late Night'), findsNothing);
      expect(find.text('ARCHIVED'), findsNothing);
      expect(find.text('Breakfast'), findsOneWidget);
    });

    testWidgets('returning from archived refreshes the list', (tester) async {
      final repo = _RecordingRepository(stored: _config(archived: ['Late']));
      await _pumpPage(
        tester,
        repository: repo,
        onArchivedPressed: () async {
          // Stand-in for restoring while away.
          final current = await repo.read();
          await repo.upsert(
            MealCategoriesConfig(
              items: [
                for (final item in current.orderedItems)
                  if (item.active) item else item.withActive(true),
              ],
            ),
          );
        },
      );
      expect(find.text('Late'), findsNothing);

      await tester.tap(find.byKey(_archivedEntry));
      await tester.pumpAndSettle();

      expect(
        find.text('Late'),
        findsOneWidget,
        reason: 'the list re-reads on return rather than showing stale state',
      );
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

      final renamed = (await repo.read()).findById('meal_slot_2');
      expect(renamed!.displayName, 'Pre Workout');
      expect(renamed.defaultKey, MealCategoryDefaultKey.lunch);
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
      );
      expect(repo.writes, 0);
    });

    testWidgets('a normalized duplicate active name is rejected',
        (tester) async {
      final repo = await _pumpPage(tester, stored: _config());

      await tester.tap(
        find.byKey(const ValueKey('meal-category-rename-meal_slot_2')),
      );
      await tester.pumpAndSettle();
      await _enterName(tester, '  breakfast ');

      expect(
        find.text('That name is already used by another active category.'),
        findsOneWidget,
      );
      expect((await repo.read()).findById('meal_slot_2')!.displayName, 'Lunch');
    });

    testWidgets('a rename that changes nothing does not write', (tester) async {
      final repo = await _pumpPage(tester);
      expect(repo.writes, 0);

      await tester.tap(
        find.byKey(const ValueKey('meal-category-rename-meal_slot_1')),
      );
      await tester.pumpAndSettle();
      await _enterName(tester, 'Breakfast');

      expect(repo.writes, 0, reason: 'no visible edit, no persisted config');
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

      await _revealAdd(tester);
      await tester.tap(find.byKey(_addButton));
      await tester.pumpAndSettle();
      await _enterName(tester, 'Pre Workout');

      expect(find.text('Pre Workout'), findsOneWidget);
      final added = (await repo.read()).activeItems.last;
      expect(added.displayName, 'Pre Workout');
      expect(added.defaultKey, isNull);
      expect(MealCategoriesPolicy.isValidCustomId(added.id), isTrue);
      expect(find.textContaining(added.id), findsNothing);
    });
  });

  group('reorder', () {
    testWidgets('moves an active category and renumbers order only',
        (tester) async {
      final repo = await _pumpPage(tester, stored: _config());

      tester
          .widget<SliverReorderableList>(find.byKey(_activeList))
          .onReorderItem!(0, 3);
      await tester.pumpAndSettle();

      final stored = await repo.read();
      expect(
        stored.activeItems.map((item) => item.displayName).toList(),
        ['Lunch', 'Dinner', 'Snacks', 'Breakfast'],
      );
      expect(stored.activeItems.map((item) => item.order).toList(), [0, 1, 2, 3]);
      expect(
        stored.findById('meal_slot_1')!.defaultKey,
        MealCategoryDefaultKey.breakfast,
      );
    });

    testWidgets('reordering leaves archived identities alone', (tester) async {
      final repo = await _pumpPage(
        tester,
        stored: _config(archived: ['Late Night']),
      );
      final before =
          (await repo.read()).orderedItems.firstWhere((item) => !item.active);

      tester
          .widget<SliverReorderableList>(find.byKey(_activeList))
          .onReorderItem!(0, 2);
      await tester.pumpAndSettle();

      final after =
          (await repo.read()).orderedItems.firstWhere((item) => !item.active);
      expect(after.id, before.id);
      expect(after.displayName, before.displayName);
      expect(after.active, isFalse);
    });

    testWidgets('the drag handle still starts a reorder', (tester) async {
      await _pumpPage(tester, stored: _config());

      final handle =
          find.byKey(const ValueKey('meal-category-drag-meal_slot_1'));
      expect(
        find.ancestor(
          of: handle,
          matching: find.byType(ReorderableDragStartListener),
        ),
        findsOneWidget,
      );
    });
  });

  group('eight active maximum', () {
    testWidgets('Add stays available at seven active', (tester) async {
      await _pumpPage(tester, stored: _config(extraActive: 3));
      await _revealAdd(tester);

      expect(
        tester.widget<TioButton>(find.byKey(_addButton)).onPressed,
        isNotNull,
      );
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

    testWidgets('archiving from eight frees exactly one slot', (tester) async {
      await _pumpPage(tester, stored: _config(extraActive: 4));
      await _revealAdd(tester);
      expect(tester.widget<TioButton>(find.byKey(_addButton)).onPressed, isNull);

      await tester.scrollUntilVisible(
        find.text('Snacks'),
        -200,
        scrollable: _pageScrollable,
      );
      await tester.pumpAndSettle();
      await _swipeOpen(tester, 'Snacks');
      await _confirmArchive(tester, 'meal_slot_4');

      await _revealAdd(tester);
      expect(
        tester.widget<TioButton>(find.byKey(_addButton)).onPressed,
        isNotNull,
        reason: 'one slot freed, not more',
      );
    });

    test('the controller refuses to reactivate past the cap', () async {
      final repo = _RecordingRepository(
        stored: _config(extraActive: 4, archived: ['Late Night']),
      );
      final controller = MealCategoriesController(repository: repo);
      addTearDown(controller.dispose);
      await controller.load();

      final archivedId = controller.state.archivedItems.single.id;
      expect(await controller.reactivate(archivedId), isFalse);
      expect(repo.writes, 0);
      expect(controller.state.actionError, 'Maximum 8 active meal categories');
      expect(controller.state.activeCount, 8);
    });

    test('the controller refuses to add past the cap', () async {
      final repo = _RecordingRepository(stored: _config(extraActive: 4));
      final controller = MealCategoriesController(repository: repo);
      addTearDown(controller.dispose);
      await controller.load();

      expect(await controller.addCustom('Ninth'), isFalse);
      expect(repo.writes, 0);
      expect(controller.state.actionError, 'Maximum 8 active meal categories');
    });

    testWidgets('the domain rejects a ninth active rather than truncating',
        (tester) async {
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
    testWidgets('a failed write keeps the previous confirmed state',
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
      expect(find.text('Lunch'), findsOneWidget);
      expect((await repo.read()).findById('meal_slot_2')!.displayName, 'Lunch');
    });

    testWidgets('the failure offers Retry and it succeeds', (tester) async {
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
      );

      expect(await controller.retryPendingAction(), isTrue);
      expect(
        controller.state.confirmed!.findById('meal_slot_2')!.displayName,
        'Pre Workout',
      );
      expect(controller.state.canRetryAction, isFalse);
    });

    test('a rejected configuration is not offered as a retry', () async {
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

    test('a read-time validation failure gets read-time copy', () async {
      final repo = _RecordingRepository()
        ..failNextRead = const MealCategoriesValidationException(
          code: MealCategoriesValidationCode.blankDisplayName,
          message: 'internal',
        );
      final controller = MealCategoriesController(repository: repo);
      addTearDown(controller.dispose);
      await controller.load();

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

    test('reactivation lands last even when the archived order is low',
        () async {
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
      );
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
          stored: _config(),
          mode: testCase.mode,
          textScale: 1.6,
        );

        final scaffold = tester.widget<Scaffold>(
          find.byKey(const ValueKey('meal-categories-destination-page')),
        );
        expect(scaffold.backgroundColor, testCase.expected.background);
        // The rule follows the theme rather than a fixed grey.
        final divider = tester.widget<Divider>(
          find.byKey(const ValueKey('meal-category-divider-meal_slot_1')),
        );
        expect(
          divider.color,
          testCase.expected.outlineStrong.withAlpha(TioAlpha.alpha20),
        );
        expect(tester.takeException(), isNull, reason: testCase.name);
      });
    }

    testWidgets('controls carry reachable labels and tap targets',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpPage(tester, stored: _config());

      final size = tester.getSize(
        find.byKey(const ValueKey('meal-category-rename-meal_slot_1')),
      );
      expect(size.width, greaterThanOrEqualTo(kMinInteractiveDimension));
      expect(size.height, greaterThanOrEqualTo(kMinInteractiveDimension));

      expect(find.bySemanticsLabel('Reorder Breakfast'), findsOneWidget);
      expect(find.byTooltip('Edit Breakfast'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('controls read as disabled while a write is in flight',
        (tester) async {
      final repo = _RecordingRepository(stored: _config());
      final gate = Completer<void>();
      repo.writeGate = gate;

      await _pumpPage(tester, repository: repo);

      await _swipeOpen(tester, 'Snacks');
      await tester.tap(find.byKey(_swipeAction('meal_slot_4')));
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
      );
    });

    testWidgets('the active list is the page scroll view', (tester) async {
      tester.view.physicalSize = const Size(390, 560);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpPage(tester, stored: _config(extraActive: 4));

      expect(find.byType(SliverReorderableList), findsOneWidget);
      expect(find.byType(ReorderableListView), findsNothing);
      expect(find.byType(Scrollable).evaluate().length, 1);

      final position =
          tester.state<ScrollableState>(find.byType(Scrollable)).position;
      expect(position.pixels, 0);
      expect(position.maxScrollExtent, greaterThan(0));

      await tester.drag(find.text('Lunch'), const Offset(0, -150));
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
    });
  });
}
