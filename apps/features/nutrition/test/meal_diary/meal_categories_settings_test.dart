import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
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

/// The first custom category `_config(extraActive: n)` produces.
const _customId = 'meal_slot_aaaaaaaa-aaaa-4aaa-8aaa-000000000000';

const _activeList = ValueKey('meal-categories-active-list');
const _addButton = ValueKey('meal-categories-add');
const _addCapReason = ValueKey('meal-categories-add-cap-reason');
const _archivedEntry = ValueKey('meal-categories-archived-entry');
ValueKey<String> _swipeAction(String id) =>
    ValueKey('meal-category-swipe-action-$id');

ValueKey<String> _swipeRow(String id) => ValueKey('meal-category-swipe-$id');

/// The moving foreground layer, used to measure how far a row has travelled.
ValueKey<String> _rowContent(String id) =>
    ValueKey('meal-category-active-$id');
const _nameField = ValueKey('meal-category-name-field');
const _nameSubmit = ValueKey('meal-category-name-submit');

Future<void> _enterName(WidgetTester tester, String value) async {
  await tester.enterText(find.byKey(_nameField), value);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(_nameSubmit));
  await tester.pumpAndSettle();
}

/// The category names as the screen actually paints them, top to bottom.
///
/// Read off the rendered rows rather than off the controller, so a test can
/// tell what the reader sees from what the repository holds.
List<String> _renderedOrder(WidgetTester tester) {
  final entries = <(double, String)>[];
  for (final element in tester.elementList(
    find.byWidgetPredicate(
      (widget) => widget.key.toString().contains('meal-category-active-'),
    ),
  )) {
    final row = find.byWidget(element.widget);
    entries.add((
      tester.getTopLeft(row).dy,
      tester
          .widget<Text>(
            find.descendant(of: row, matching: find.byType(Text)).first,
          )
          .data!,
    ));
  }
  entries.sort((a, b) => a.$1.compareTo(b.$1));
  return [for (final entry in entries) entry.$2];
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

  group('page description', () {
    testWidgets('explains the screen above the ACTIVE section', (tester) async {
      await _pumpPage(tester, stored: _config());

      final description =
          find.byKey(const ValueKey('meal-categories-description'));
      final note = find.byKey(const ValueKey('meal-categories-minimum-note'));
      final header =
          find.byKey(const ValueKey('meal-categories-active-header'));

      expect(description, findsOneWidget);
      expect(note, findsOneWidget);

      // Order on screen rather than exact coordinates: description, then the
      // rule, then the section it introduces.
      final descriptionY = tester.getTopLeft(description).dy;
      final noteY = tester.getTopLeft(note).dy;
      final headerY = tester.getTopLeft(header).dy;
      expect(descriptionY, lessThan(noteY));
      expect(noteY, lessThan(headerY));
    });

    testWidgets('the copy names custom categories as the reorderable ones',
        (tester) async {
      // The canonical four are fixed, so "categories can be reordered" would
      // promise something the screen refuses.
      await _pumpPage(tester, stored: _config());

      final text =
          tester.widget<Text>(find.byKey(const ValueKey('meal-categories-description'))).data!;
      expect(text, contains('Custom categories can be reordered.'));
      expect(text, isNot(contains('Categories can be reordered')));
    });

    testWidgets('the copy sits outside the category card', (tester) async {
      await _pumpPage(tester, stored: _config());

      expect(
        find.descendant(
          of: find.byKey(_swipeRow('meal_slot_1')),
          matching: find.byKey(const ValueKey('meal-categories-description')),
        ),
        findsNothing,
      );
    });

    testWidgets('the minimum note is informational, not an error',
        (tester) async {
      await _pumpPage(tester, stored: _config());

      final note = tester.widget<Text>(
        find.byKey(const ValueKey('meal-categories-minimum-note')),
      );
      expect(note.style!.color, TioColors.light.textMuted);
      expect(
        note.style!.color,
        isNot(TioColors.light.danger),
        reason: 'it is true before anything goes wrong',
      );
    });

    testWidgets('no Learn More affordance is offered', (tester) async {
      await _pumpPage(tester, stored: _config());

      expect(find.text('Learn More'), findsNothing);
      expect(find.text('Learn more'), findsNothing);
    });

    for (final testCase in const [
      (name: 'Dark', mode: TioThemeMode.dark, expected: TioColors.dark),
      (name: 'OLED', mode: TioThemeMode.oled, expected: TioColors.oled),
    ]) {
      testWidgets('the copy follows the ${testCase.name} palette',
          (tester) async {
        await _pumpPage(tester, stored: _config(), mode: testCase.mode);

        expect(
          tester
              .widget<Text>(
                find.byKey(const ValueKey('meal-categories-description')),
              )
              .style!
              .color,
          testCase.expected.textSecondary,
        );
        expect(
          tester
              .widget<Text>(
                find.byKey(const ValueKey('meal-categories-minimum-note')),
              )
              .style!
              .color,
          testCase.expected.textMuted,
        );
      });
    }
  });

  group('row contents', () {
    testWidgets('a custom row shows a drag handle, a name and an edit action',
        (tester) async {
      await _pumpPage(tester, stored: _config(extraActive: 1));

      expect(
        find.byKey(const ValueKey('meal-category-drag-$_customId')),
        findsOneWidget,
      );
      expect(find.text('Custom 0'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('meal-category-rename-$_customId')),
        findsOneWidget,
      );
    });

    testWidgets('a default row shows a name and an edit action only',
        (tester) async {
      await _pumpPage(tester, stored: _config());

      expect(find.text('Breakfast'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('meal-category-rename-meal_slot_1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('meal-category-drag-meal_slot_1')),
        findsNothing,
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
      // At rest the row covers the action completely, so nothing archive
      // shaped is on offer.
      final rowRect = tester.getRect(find.byKey(_rowContent('meal_slot_1')));
      final cardRect = tester.getRect(find.byKey(_swipeRow('meal_slot_1')));
      expect(rowRect.left, closeTo(cardRect.left, 0.5));
      expect(rowRect.right, greaterThanOrEqualTo(cardRect.right - 0.5));

      // A default row's only control is still the pencil. It also carries the
      // decorative glyph that fills its leading column — deliberately not a
      // grip and not an archive, so it offers nothing the row cannot do.
      final rowIcons = tester
          .widgetList<Icon>(
            find.descendant(
              of: find.byKey(const ValueKey('meal-category-active-meal_slot_1')),
              matching: find.byType(Icon),
            ),
          )
          .map((icon) => icon.icon)
          .toList();
      expect(rowIcons, [Icons.free_breakfast_outlined, Icons.edit_outlined]);
      expect(
        rowIcons,
        isNot(contains(Icons.drag_handle_rounded)),
        reason: 'a fixed row must not look draggable',
      );
      expect(rowIcons, isNot(contains(Icons.archive_outlined)));
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

      // Inset at the start so the handle column stays clear, flush at the end
      // so the rule reaches the card rather than stopping short of it.
      final divider = tester.widget<Divider>(dividers.first);
      expect(divider.indent, greaterThan(TioSpacing.lg));
      expect(divider.endIndent, TioSpacing.none);
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

      final before = tester.getTopLeft(find.byKey(_rowContent('meal_slot_2')));

      // A hard fling must not carry the row off screen: it stops at exactly
      // one action's width, whatever the velocity.
      await tester.fling(find.text('Lunch'), const Offset(-500, 0), 2000);
      await tester.pumpAndSettle();

      expect(find.text('Lunch'), findsOneWidget, reason: 'still mounted');
      final travelled =
          before.dx - tester.getTopLeft(find.byKey(_rowContent('meal_slot_2'))).dx;
      expect(
        travelled,
        closeTo(MealCategorySwipeRow.revealWidth, 0.5),
        reason: 'clamped to the reveal, never dismissed',
      );
    });

    testWidgets('the action layer is behind the row, matching its geometry',
        (tester) async {
      await _pumpPage(tester, stored: _config());

      final rowRect = tester.getRect(find.byKey(_swipeRow('meal_slot_2')));
      // The strip, not the icon inside it: the icon is centred and so is
      // inset by design.
      final stripRect = tester.getRect(
        find
            .ancestor(
              of: find.byKey(_swipeAction('meal_slot_2')),
              matching: find.byType(ColoredBox),
            )
            .first,
      );

      // Flush with the row's right edge and filling its full height. An action
      // parked beside the row, or shorter than it, fails both.
      expect(stripRect.right, closeTo(rowRect.right, 0.5));
      expect(stripRect.top, closeTo(rowRect.top, 0.5));
      expect(stripRect.bottom, closeTo(rowRect.bottom, 0.5));
      expect(
        stripRect.width,
        closeTo(MealCategorySwipeRow.revealWidth, 0.5),
      );

      // Inert while covered, so a closed row hides no live target.
      expect(
        tester.widget<IconButton>(find.byKey(_swipeAction('meal_slot_2')))
            .onPressed,
        isNull,
      );

      await _swipeOpen(tester, 'Lunch');

      expect(
        tester.widget<ColoredBox>(
          find
              .ancestor(
                of: find.byKey(_swipeAction('meal_slot_2')),
                matching: find.byType(ColoredBox),
              )
              .first,
        ).color,
        TioColors.light.danger.withAlpha(TioAlpha.alpha35),
        reason: 'the repo destructive surface, not a hardcoded red',
      );
      expect(
        tester.widget<IconButton>(find.byKey(_swipeAction('meal_slot_2')))
            .onPressed,
        isNotNull,
      );

      // The row itself is untouched — only the layer behind is destructive.
      expect(
        tester
            .widget<Material>(
              find
                  .ancestor(
                    of: find.byKey(_rowContent('meal_slot_2')),
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .color,
        TioColors.light.surfaceRaised,
      );
    });

    for (final testCase in const [
      (name: 'Dark', mode: TioThemeMode.dark, expected: TioColors.dark),
      (name: 'OLED', mode: TioThemeMode.oled, expected: TioColors.oled),
    ]) {
      testWidgets('the reveal follows the ${testCase.name} palette',
          (tester) async {
        await _pumpPage(tester, stored: _config(), mode: testCase.mode);
        await _swipeOpen(tester, 'Lunch');

        expect(
          tester
              .widget<ColoredBox>(
                find
                    .ancestor(
                      of: find.byKey(_swipeAction('meal_slot_2')),
                      matching: find.byType(ColoredBox),
                    )
                    .first,
              )
              .color,
          testCase.expected.danger.withAlpha(TioAlpha.alpha35),
        );
      });
    }

    testWidgets('the reveal ticks once per crossing, not per frame',
        (tester) async {
      final ticks = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            ticks.add(call.arguments as String? ?? '');
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await _pumpPage(tester, stored: _config());

      // Drag past the threshold in many small steps: one crossing, so one
      // tick, however many frames the finger takes to get there.
      final gesture =
          await tester.startGesture(tester.getCenter(find.text('Lunch')));
      for (var step = 0; step < 12; step++) {
        await gesture.moveBy(const Offset(-8, 0));
        await tester.pump();
      }
      expect(ticks, hasLength(1), reason: 'one crossing, one tick');

      // Continuing to move past it must not tick again.
      for (var step = 0; step < 6; step++) {
        await gesture.moveBy(const Offset(-8, 0));
        await tester.pump();
      }
      expect(ticks, hasLength(1));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a row swiped open and shut repeatedly still settles exactly',
        (tester) async {
      // Guards the settle refactor. One curve and one listener now serve every
      // swipe, where a fresh animation used to be built each time; the leak
      // that caused is not observable from a widget test, but a settle landing
      // anywhere other than exactly open or exactly closed would be.
      await _pumpPage(tester, stored: _config());
      final shut = tester.getTopLeft(find.byKey(_rowContent('meal_slot_2'))).dx;

      for (var cycle = 0; cycle < 6; cycle++) {
        await _swipeOpen(tester, 'Lunch');
        expect(
          shut - tester.getTopLeft(find.byKey(_rowContent('meal_slot_2'))).dx,
          closeTo(MealCategorySwipeRow.revealWidth, 0.5),
          reason: 'open lands on the reveal, cycle $cycle',
        );

        await tester.drag(find.text('Lunch'), const Offset(90, 0));
        await tester.pumpAndSettle();
        expect(
          tester.getTopLeft(find.byKey(_rowContent('meal_slot_2'))).dx,
          closeTo(shut, 0.5),
          reason: 'and shut lands back at the edge, cycle $cycle',
        );
      }
    });

    testWidgets('the row is clamped while the finger is still down',
        (tester) async {
      // The release animation snaps to the reveal either way, so the clamp has
      // to be observed mid-drag: without it the row follows the finger across
      // the screen before settling back.
      await _pumpPage(tester, stored: _config());
      final before = tester.getTopLeft(find.byKey(_rowContent('meal_slot_2')));

      final gesture =
          await tester.startGesture(tester.getCenter(find.text('Lunch')));
      for (var step = 0; step < 10; step++) {
        await gesture.moveBy(const Offset(-40, 0));
        await tester.pump();
      }

      final travelled =
          before.dx - tester.getTopLeft(find.byKey(_rowContent('meal_slot_2'))).dx;
      expect(
        travelled,
        closeTo(MealCategorySwipeRow.revealWidth, 0.5),
        reason: '400px of drag still stops at one action width',
      );

      await gesture.up();
      await tester.pumpAndSettle();
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
        stored: _config(archived: ['Late Night']),
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

    testWidgets('the archived entry is absent while nothing is archived',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpPage(tester, stored: _config());

      expect(find.byKey(_archivedEntry), findsNothing);
      expect(
        find.byTooltip('Archived meal categories'),
        findsNothing,
        reason: 'no invisible tappable target is left behind',
      );
      expect(
        find.bySemanticsLabel('Archived meal categories'),
        findsNothing,
        reason: 'and nothing for a screen reader to land on either',
      );
      semantics.dispose();
    });

    testWidgets('archiving the first category reveals the entry',
        (tester) async {
      await _pumpPage(tester, stored: _config());
      expect(find.byKey(_archivedEntry), findsNothing);

      await _swipeOpen(tester, 'Lunch');
      await _confirmArchive(tester, 'meal_slot_2');

      expect(
        find.byKey(_archivedEntry),
        findsOneWidget,
        reason: 'it appears reactively, without a restart',
      );
    });

    testWidgets('restoring the last archived category hides the entry again',
        (tester) async {
      final repo = _RecordingRepository(stored: _config(archived: ['Late']));
      await _pumpPage(
        tester,
        repository: repo,
        onArchivedPressed: () async {
          // Stands in for restoring on the archived destination.
          final current = await repo.read();
          await repo.upsert(
            MealCategoriesConfig(
              items: [
                for (final item in current.orderedItems) item.withActive(true),
              ],
            ),
          );
        },
      );
      expect(find.byKey(_archivedEntry), findsOneWidget);

      await tester.tap(find.byKey(_archivedEntry));
      await tester.pumpAndSettle();

      expect(
        find.byKey(_archivedEntry),
        findsNothing,
        reason: 'nothing archived, so nowhere to go',
      );
      expect(find.text('Late'), findsOneWidget, reason: 'it came back active');
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
    testWidgets('a custom category moves between the canonical anchors',
        (tester) async {
      final repo = await _pumpPage(tester, stored: _config(extraActive: 1));

      // The custom starts after Snacks; move it to just after Breakfast.
      tester
          .widget<SliverReorderableList>(find.byKey(_activeList))
          .onReorderItem!(4, 1);
      await tester.pumpAndSettle();

      final stored = await repo.read();
      expect(
        stored.activeItems.map((item) => item.displayName).toList(),
        ['Breakfast', 'Custom 0', 'Lunch', 'Dinner', 'Snacks'],
      );
      // The anchors keep their relative order, and their identities are
      // untouched by a neighbour moving.
      expect(
        stored.activeItems
            .where((item) => item.defaultKey != null)
            .map((item) => item.defaultKey)
            .toList(),
        [
          MealCategoryDefaultKey.breakfast,
          MealCategoryDefaultKey.lunch,
          MealCategoryDefaultKey.dinner,
          MealCategoryDefaultKey.snacks,
        ],
      );
    });

    testWidgets('a custom category can move to every gap between anchors',
        (tester) async {
      final repo = await _pumpPage(tester, stored: _config(extraActive: 1));

      for (final target in [0, 2, 3, 4]) {
        final before = (await repo.read())
            .activeItems
            .indexWhere((item) => item.id == _customId);
        tester
            .widget<SliverReorderableList>(find.byKey(_activeList))
            .onReorderItem!(before, target);
        await tester.pumpAndSettle();

        final defaults = (await repo.read())
            .activeItems
            .where((item) => item.defaultKey != null)
            .map((item) => item.defaultKey)
            .toList();
        expect(
          defaults,
          [
            MealCategoryDefaultKey.breakfast,
            MealCategoryDefaultKey.lunch,
            MealCategoryDefaultKey.dinner,
            MealCategoryDefaultKey.snacks,
          ],
          reason: 'anchors survive a move to position $target',
        );
      }
    });

    testWidgets('two custom categories reorder relative to each other',
        (tester) async {
      final repo = await _pumpPage(tester, stored: _config(extraActive: 2));
      expect(
        (await repo.read()).activeItems.map((item) => item.displayName).toList(),
        ['Breakfast', 'Lunch', 'Dinner', 'Snacks', 'Custom 0', 'Custom 1'],
      );

      tester
          .widget<SliverReorderableList>(find.byKey(_activeList))
          .onReorderItem!(5, 4);
      await tester.pumpAndSettle();

      expect(
        (await repo.read()).activeItems.map((item) => item.displayName).toList(),
        ['Breakfast', 'Lunch', 'Dinner', 'Snacks', 'Custom 1', 'Custom 0'],
      );
    });

    testWidgets('reordering leaves archived identities alone', (tester) async {
      final repo = await _pumpPage(
        tester,
        stored: _config(extraActive: 1, archived: ['Late Night']),
      );
      final before =
          (await repo.read()).orderedItems.firstWhere((item) => !item.active);

      tester
          .widget<SliverReorderableList>(find.byKey(_activeList))
          .onReorderItem!(4, 1);
      await tester.pumpAndSettle();

      final after =
          (await repo.read()).orderedItems.firstWhere((item) => !item.active);
      expect(after.id, before.id);
      expect(after.displayName, before.displayName);
      expect(after.active, isFalse);
    });

    testWidgets('both row kinds use the shared Nutrition edit affordance',
        (tester) async {
      // Reused rather than reimplemented: a third bare pencil would drift from
      // the rest of Settings the first time either changed.
      await _pumpPage(tester, stored: _config(extraActive: 1));

      for (final id in ['meal_slot_1', _customId]) {
        expect(
          find.byKey(ValueKey('meal-category-rename-$id')),
          findsOneWidget,
          reason: id,
        );
        expect(
          tester.widget(find.byKey(ValueKey('meal-category-rename-$id'))),
          isA<NutritionEditPencil>(),
          reason: '$id uses the shared affordance, not a local pencil',
        );
      }
    });

    testWidgets('the edit affordance travels with the row on swipe',
        (tester) async {
      await _pumpPage(tester, stored: _config());
      final before = tester
          .getTopLeft(find.byKey(const ValueKey('meal-category-rename-meal_slot_2')))
          .dx;

      await _swipeOpen(tester, 'Lunch');

      final travelled = before -
          tester
              .getTopLeft(
                find.byKey(const ValueKey('meal-category-rename-meal_slot_2')),
              )
              .dx;
      expect(
        travelled,
        closeTo(MealCategorySwipeRow.revealWidth, 0.5),
        reason: 'it belongs to the foreground, not floating over the action',
      );
    });

    testWidgets('a default row offers no drag handle', (tester) async {
      await _pumpPage(tester, stored: _config(extraActive: 1));

      for (final id in ['meal_slot_1', 'meal_slot_2', 'meal_slot_3',
          'meal_slot_4']) {
        expect(
          find.byKey(ValueKey('meal-category-drag-$id')),
          findsNothing,
          reason: '$id is a canonical anchor and cannot move',
        );
      }
      // The custom one does.
      expect(
        find.byKey(const ValueKey('meal-category-drag-$_customId')),
        findsOneWidget,
      );
    });

    testWidgets('a default row advertises no reorder semantics',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpPage(tester, stored: _config(extraActive: 1));

      expect(
        find.bySemanticsLabel('Reorder Breakfast'),
        findsNothing,
        reason: 'never advertise an action the row cannot perform',
      );
      expect(find.bySemanticsLabel('Reorder Custom 0'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('the controller refuses to move a canonical default',
        (tester) async {
      final repo = _RecordingRepository(stored: _config(extraActive: 1));
      final controller = MealCategoriesController(repository: repo);
      addTearDown(controller.dispose);
      await controller.load();

      // Breakfast sits at active index 0.
      expect(
        await controller.reorderActive(oldIndex: 0, newIndex: 3),
        isFalse,
      );
      expect(repo.writes, 0, reason: 'nothing reaches the repository');
      expect(
        controller.state.actionError,
        MealCategoriesController.defaultsFixedReason,
      );
    });

    testWidgets('names stay in one column with and without a handle',
        (tester) async {
      await _pumpPage(tester, stored: _config(extraActive: 1));

      final defaultName = tester.getTopLeft(find.text('Breakfast')).dx;
      final customName = tester.getTopLeft(find.text('Custom 0')).dx;
      expect(
        customName,
        defaultName,
        reason: 'the handle slot is reserved, so names never jump',
      );
    });

    testWidgets('the archived entry waits for the write that created it',
        (tester) async {
      // The entry appears the moment the archive is shown optimistically, but
      // the destination behind it reads the repository. Tapping before the
      // write lands would arrive at a screen saying nothing is archived.
      final repo = _RecordingRepository(stored: _config());
      var opened = 0;
      await _pumpPage(
        tester,
        repository: repo,
        onArchivedPressed: () async => opened++,
      );

      repo.writeGate = Completer<void>();
      await _swipeOpen(tester, 'Lunch');
      await tester.tap(find.byKey(_swipeAction('meal_slot_2')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
      await tester.pump();

      final entry = find.byKey(_archivedEntry);
      expect(entry, findsOneWidget, reason: 'shown optimistically');
      expect(
        tester.widget<IconButton>(entry).onPressed,
        isNull,
        reason: 'but not yet reachable',
      );

      repo.writeGate!.complete();
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(entry).onPressed, isNotNull);
      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(opened, 1);
    });

    testWidgets('the moved row is in its new place before the write lands',
        (tester) async {
      // The symptom this fixes: the row snapped back to where it started and
      // only moved once the repository answered, so on anything slower than a
      // test the drag read as ignored.
      final repo = _RecordingRepository(stored: _config(extraActive: 1));
      repo.writeGate = Completer<void>();
      await _pumpPage(tester, repository: repo);

      tester
          .widget<SliverReorderableList>(find.byKey(_activeList))
          .onReorderItem!(4, 1);
      await tester.pump();

      expect(
        _renderedOrder(tester),
        ['Breakfast', 'Custom 0', 'Lunch', 'Dinner', 'Snacks'],
        reason: 'the list keeps up with the gesture, not with the round trip',
      );

      repo.writeGate!.complete();
      await tester.pumpAndSettle();
      expect(
        _renderedOrder(tester),
        ['Breakfast', 'Custom 0', 'Lunch', 'Dinner', 'Snacks'],
        reason: 'and does not move again when the write lands',
      );
      expect(
        (await repo.read())
            .activeItems
            .map((item) => item.displayName)
            .toList(),
        ['Breakfast', 'Custom 0', 'Lunch', 'Dinner', 'Snacks'],
      );
    });

    testWidgets('a move the repository refuses goes back where it was',
        (tester) async {
      final repo = _RecordingRepository(stored: _config(extraActive: 1));
      repo.writeGate = Completer<void>();
      repo.failNextWrite = StateError('offline');
      await _pumpPage(tester, repository: repo);

      tester
          .widget<SliverReorderableList>(find.byKey(_activeList))
          .onReorderItem!(4, 1);
      await tester.pump();
      expect(
        _renderedOrder(tester),
        ['Breakfast', 'Custom 0', 'Lunch', 'Dinner', 'Snacks'],
      );

      repo.writeGate!.complete();
      await tester.pumpAndSettle();
      // Shown optimistically is not the same as stored: a failed write puts
      // the row back rather than leaving a move that never happened on screen.
      expect(
        _renderedOrder(tester),
        ['Breakfast', 'Lunch', 'Dinner', 'Snacks', 'Custom 0'],
      );
      expect(
        find.byKey(const ValueKey('meal-categories-action-error')),
        findsOneWidget,
      );
    });

    testWidgets('Add Meal Category spans the full content width',
        (tester) async {
      await _pumpPage(tester, stored: _config());
      await _revealAdd(tester);

      final button = tester.getRect(find.byKey(_addButton));
      final page = tester.getRect(
        find.byKey(const ValueKey('meal-categories-destination-page')),
      );
      // Inset by the same gutter as the list above it, so the button lines up
      // with the card rather than hugging its label.
      expect(button.left, closeTo(page.left + TioSpacing.lg, 0.5));
      expect(button.right, closeTo(page.right - TioSpacing.lg, 0.5));
    });

    testWidgets('the edit affordance paints nothing when pressed',
        (tester) async {
      await _pumpPage(tester, stored: _config());

      // Core's own settings affordance has no ink at all — the ripple in
      // Settings belongs to the row — so a circle rippling here would be this
      // screen alone behaving differently. Asserted on the configuration
      // rather than on painted pixels, which a widget test cannot inspect.
      final ink = tester.widget<InkResponse>(
        find
            .descendant(
              of: find.byKey(const ValueKey('meal-category-rename-meal_slot_1')),
              matching: find.byType(InkResponse),
            )
            .first,
      );
      expect(ink.splashFactory, NoSplash.splashFactory);
      expect(ink.highlightColor, TioPalette.transparent);
      expect(ink.hoverColor, TioPalette.transparent);

      // And it still does its job.
      await tester.tap(
        find.byKey(const ValueKey('meal-category-rename-meal_slot_1')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(_nameField), findsOneWidget);
    });

    testWidgets('every canonical default fills its leading column with a glyph',
        (tester) async {
      await _pumpPage(tester, stored: _config(extraActive: 1));

      const glyphs = <String, IconData>{
        'meal_slot_1': Icons.free_breakfast_outlined,
        'meal_slot_2': Icons.lunch_dining_outlined,
        'meal_slot_3': Icons.dinner_dining_outlined,
        'meal_slot_4': Icons.cookie_outlined,
      };
      for (final entry in glyphs.entries) {
        final glyph = find.byKey(ValueKey('meal-category-glyph-${entry.key}'));
        expect(glyph, findsOneWidget, reason: '${entry.key} shows something');
        expect(tester.widget<Icon>(glyph).icon, entry.value);
        expect(
          find.byKey(ValueKey('meal-category-drag-${entry.key}')),
          findsNothing,
          reason: 'a glyph, never a grip: these rows cannot move',
        );
      }

      // The custom row keeps its grip and gains no second icon beside it.
      expect(
        find.byKey(const ValueKey('meal-category-glyph-$_customId')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('meal-category-drag-$_customId')),
        findsOneWidget,
      );
    });

    testWidgets('a long press on the row body picks it up, not just the grip',
        (tester) async {
      final repo = await _pumpPage(tester, stored: _config(extraActive: 1));
      expect(
        (await repo.read())
            .activeItems
            .map((item) => item.displayName)
            .toList(),
        ['Breakfast', 'Lunch', 'Dinner', 'Snacks', 'Custom 0'],
      );

      // Deliberately away from the handle: the finger lands on the name.
      final from = tester.getCenter(find.text('Custom 0'));
      final to = tester.getCenter(find.text('Dinner'));
      final gesture = await tester.startGesture(from);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));

      for (var step = 1; step <= 6; step++) {
        await gesture.moveTo(Offset.lerp(from, to, step / 6)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      final order = (await repo.read())
          .activeItems
          .map((item) => item.displayName)
          .toList();
      // Where exactly it lands depends on how far the finger travelled, so
      // this asserts what the gesture is for rather than a pixel outcome: the
      // row moved, and the anchors it passed did not.
      expect(order.last, isNot('Custom 0'), reason: 'the row was lifted');
      expect(
        order.where((name) => name != 'Custom 0').toList(),
        ['Breakfast', 'Lunch', 'Dinner', 'Snacks'],
      );
    });

    testWidgets('the long-press surface covers the row, not just the text',
        (tester) async {
      final repo = await _pumpPage(tester, stored: _config(extraActive: 1));

      // A finger lands above the glyphs as often as on them, so the press has
      // to be answered across the band the row reserves for its target rather
      // than only inside the text's own line box.
      final name = tester.getRect(find.text('Custom 0'));
      final from = Offset(name.center.dx, name.top - 8);
      final gesture = await tester.startGesture(from);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));

      for (var step = 1; step <= 6; step++) {
        await gesture.moveTo(from + Offset(0, -10.0 * step));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        (await repo.read()).activeItems.last.displayName,
        isNot('Custom 0'),
        reason: 'a press just above the name still lifted the row',
      );
    });

    testWidgets('a long press on a canonical default lifts nothing',
        (tester) async {
      final repo = await _pumpPage(tester, stored: _config(extraActive: 1));

      final from = tester.getCenter(find.text('Lunch'));
      final to = tester.getCenter(find.text('Snacks'));
      final gesture = await tester.startGesture(from);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));

      for (var step = 1; step <= 6; step++) {
        await gesture.moveTo(Offset.lerp(from, to, step / 6)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(repo.writes, 0, reason: 'a fixed row cannot be dragged anywhere');
      // The controller would refuse the move anyway, but refusing it is a
      // worse experience than never offering it: the row must not lift, float
      // under the finger and then snap back with an explanation.
      expect(
        find.byKey(const ValueKey('meal-categories-action-error')),
        findsNothing,
        reason: 'nothing was lifted, so nothing had to be refused',
      );
      expect(
        (await repo.read())
            .activeItems
            .map((item) => item.displayName)
            .toList(),
        ['Breakfast', 'Lunch', 'Dinner', 'Snacks', 'Custom 0'],
      );
    });

    testWidgets('picking a row up ticks, and so does putting it down',
        (tester) async {
      final ticks = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            ticks.add(call.arguments as String? ?? '');
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await _pumpPage(tester, stored: _config(extraActive: 1));

      final gesture =
          await tester.startGesture(tester.getCenter(find.text('Custom 0')));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(0, -30));
      await tester.pump();

      expect(
        ticks,
        ['HapticFeedbackType.mediumImpact'],
        reason: 'a silent lift reads as a row that did not respond',
      );

      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        ticks,
        [
          'HapticFeedbackType.mediumImpact',
          'HapticFeedbackType.selectionClick',
        ],
        reason: 'firmer on the way up than on the way down',
      );
    });
  });

  group('thirty-two retained maximum', () {
    /// Four canonical defaults plus [customs] customs, only [active] of them
    /// still active, so the active cap is not what refuses the add.
    MealCategoriesConfig retained({required int customs, int active = 2}) =>
        MealCategoriesConfig(
          items: [
            ...MealCategoriesConfig.canonicalDefaults().items,
            for (var index = 0; index < customs; index++)
              _category(
                id: 'meal_slot_00000000-0000-4000-8000-'
                    '${(index + 1).toString().padLeft(12, '0')}',
                displayName: 'Custom ${index + 1}',
                order: index + 4,
                active: index < active,
              ),
          ],
        );

    testWidgets('Add stays available one short of the ceiling',
        (tester) async {
      await _pumpPage(tester, stored: retained(customs: 27));
      await _revealAdd(tester);

      expect(tester.widget<TioButton>(find.byKey(_addButton)).onPressed,
          isNotNull);
      expect(find.byKey(_addCapReason), findsNothing);
    });

    testWidgets('at the ceiling Add is unavailable and names the way out',
        (tester) async {
      await _pumpPage(tester, stored: retained(customs: 28));
      await _revealAdd(tester);

      expect(
        tester.widget<TioButton>(find.byKey(_addButton)).onPressed,
        isNull,
      );
      expect(
        tester.widget<Text>(find.byKey(_addCapReason)).data,
        MealCategoriesController.retainedCapReason,
      );
      // Archiving cannot make room — it keeps the identity — so the copy has
      // to point somewhere that can.
      expect(
        MealCategoriesController.retainedCapReason,
        contains('Restore'),
      );
    });

    testWidgets('the controller refuses an add past the ceiling',
        (tester) async {
      final repo = _RecordingRepository(stored: retained(customs: 28));
      final controller = MealCategoriesController(repository: repo);
      addTearDown(controller.dispose);
      await controller.load();

      expect(controller.state.retainedCount, 32);
      expect(await controller.addCustom('One more'), isFalse);
      expect(repo.writes, 0, reason: 'nothing reaches the repository');
      expect(
        controller.state.actionError,
        MealCategoriesController.retainedCapReason,
      );
    });

    testWidgets('archiving at the ceiling is still allowed', (tester) async {
      // Archiving keeps the identity, so it cannot push the retained count up
      // and must not be refused by this cap.
      final repo = _RecordingRepository(stored: retained(customs: 28));
      final controller = MealCategoriesController(repository: repo);
      addTearDown(controller.dispose);
      await controller.load();

      expect(controller.state.activeCount, 6);
      expect(await controller.archive('meal_slot_1'), isTrue);
      expect(controller.state.retainedCount, 32, reason: 'nothing was lost');
      expect(controller.state.activeCount, 5);
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

    test('a restored default returns to its canonical slot', () async {
      // Corrected by owner decision: an archived category holds its position,
      // so restoring Lunch puts it back between Breakfast and Dinner rather
      // than at the end of the list.
      final repo = _RecordingRepository(stored: _config());
      final controller = MealCategoriesController(repository: repo);
      addTearDown(controller.dispose);
      await controller.load();

      expect(await controller.archive('meal_slot_2'), isTrue);
      expect(
        controller.state.activeItems.map((item) => item.displayName).toList(),
        ['Breakfast', 'Dinner', 'Snacks'],
        reason: 'the remaining anchors keep their order',
      );

      expect(await controller.reactivate('meal_slot_2'), isTrue);
      expect(
        controller.state.activeItems.map((item) => item.displayName).toList(),
        ['Breakfast', 'Lunch', 'Dinner', 'Snacks'],
      );
      expect(
        controller.state.confirmed!.findById('meal_slot_2')!.defaultKey,
        MealCategoryDefaultKey.lunch,
        reason: 'same identity throughout',
      );
    });

    test('the last active category cannot be archived', () async {
      final repo = _RecordingRepository(stored: _config());
      final controller = MealCategoriesController(repository: repo);
      addTearDown(controller.dispose);
      await controller.load();

      for (final id in ['meal_slot_2', 'meal_slot_3', 'meal_slot_4']) {
        expect(await controller.archive(id), isTrue);
      }
      expect(controller.state.activeCount, 1);
      expect(controller.state.canArchive, isFalse);

      final writesBefore = repo.writes;
      expect(await controller.archive('meal_slot_1'), isFalse);
      expect(repo.writes, writesBefore, reason: 'nothing was written');
      expect(
        controller.state.actionError,
        'At least one meal category is required.',
      );
      expect(
        controller.state.activeCount,
        1,
        reason: 'the previous valid state is preserved',
      );
    });

    test('the domain rejects an empty active set even bypassing the UI',
        () async {
      final defaults = MealCategoriesConfig.canonicalDefaults();
      expect(
        () => MealCategoriesConfig(
          items: defaults.items.map((item) => item.withActive(false)),
        ),
        throwsA(
          isA<MealCategoriesValidationException>().having(
            (error) => error.code,
            'code',
            MealCategoriesValidationCode.tooFewActiveCategories,
          ),
        ),
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

        // The description pushes the list down, so at this size the first row
        // starts below the fold and the lazy sliver has not built it yet.
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('meal-category-divider-meal_slot_1')),
          200,
          scrollable: _pageScrollable,
        );
        await tester.pumpAndSettle();

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

      // The shared affordance draws a 36dp circle; the target around it is
      // what has to clear the minimum.
      final target = tester.getSize(
        find
            .ancestor(
              of: find.byKey(const ValueKey('meal-category-rename-meal_slot_1')),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(target.width, greaterThanOrEqualTo(kMinInteractiveDimension));
      expect(target.height, greaterThanOrEqualTo(kMinInteractiveDimension));

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

      // The shared pencil carries no disabled state of its own, so the row
      // composes one: dimmed and inert while a write is in flight.
      expect(
        tester
            .widget<Opacity>(
              find
                  .ancestor(
                    of: find.byKey(
                      const ValueKey('meal-category-rename-meal_slot_1'),
                    ),
                    matching: find.byType(Opacity),
                  )
                  .first,
            )
            .opacity,
        TioOpacity.opacity64,
        reason: 'a control that ignores taps must not look tappable',
      );

      // And it genuinely ignores the tap rather than only looking dimmed.
      await tester.tap(
        find.byKey(const ValueKey('meal-category-rename-meal_slot_1')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(
        find.byKey(_nameField),
        findsNothing,
        reason: 'no editor opens while a write is in flight',
      );

      gate.complete();
      await tester.pumpAndSettle();

      // Live again once the write finishes.
      await tester.tap(
        find.byKey(const ValueKey('meal-category-rename-meal_slot_1')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(_nameField), findsOneWidget);
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
