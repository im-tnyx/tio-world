import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

/// Stands in for the real repository so a test can decide what the categories
/// are, and whether reading them succeeds.
class _Repository implements MealCategoriesRepository {
  _Repository({MealCategoriesConfig? stored}) : _stored = stored;

  MealCategoriesConfig? _stored;
  int reads = 0;
  Object? failNextRead;
  Completer<void>? readGate;

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
  Future<void> upsert(MealCategoriesConfig config) async => _stored = config;
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

/// The canonical four, with whatever edits a test needs applied on top.
MealCategoriesConfig _config({
  Map<String, String> renamed = const {},
  Set<String> archived = const {},
  List<({String id, String name, int order})> customs = const [],
}) {
  final defaults = <({String id, MealCategoryDefaultKey key, String name})>[
    (id: 'meal_slot_1', key: MealCategoryDefaultKey.breakfast, name: 'Breakfast'),
    (id: 'meal_slot_2', key: MealCategoryDefaultKey.lunch, name: 'Lunch'),
    (id: 'meal_slot_3', key: MealCategoryDefaultKey.dinner, name: 'Dinner'),
    (id: 'meal_slot_4', key: MealCategoryDefaultKey.snacks, name: 'Snacks'),
  ];

  final items = <MealCategory>[
    for (var index = 0; index < defaults.length; index++)
      _category(
        id: defaults[index].id,
        defaultKey: defaults[index].key,
        displayName: renamed[defaults[index].id] ?? defaults[index].name,
        order: index * 10,
        active: !archived.contains(defaults[index].id),
      ),
    for (final custom in customs)
      _category(
        id: custom.id,
        displayName: custom.name,
        order: custom.order,
        active: !archived.contains(custom.id),
      ),
  ];
  return MealCategoriesConfig(items: items);
}

const _customA = 'meal_slot_aaaaaaaa-aaaa-4aaa-8aaa-000000000000';
const _customB = 'meal_slot_bbbbbbbb-bbbb-4bbb-8bbb-000000000000';

const _footerCategory = ValueKey('meal-log-footer-category');
const _footerDateTime = ValueKey('meal-log-footer-date-time');
const _footerPrimary = ValueKey('meal-log-footer-primary');
const _selectorOptions = ValueKey('meal-category-selector-options');
const _selectorFailure = ValueKey('meal-category-selector-failure');
const _selectorRetry = ValueKey('meal-category-selector-retry');

ValueKey<String> _option(String id) => ValueKey('meal-category-option-$id');

Future<_Repository> _pumpQuickAdd(
  WidgetTester tester, {
  MealCategoriesConfig? stored,
  _Repository? repository,
  TioThemeMode mode = TioThemeMode.light,
  double textScale = 1,
  Size? size,
}) async {
  final repo = repository ?? _Repository(stored: stored);
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: TioTheme(
          config: TioThemeConfig(mode: mode),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: Scaffold(
        body: QuickAddEditorSheet(
          clock: () => DateTime(2026, 9, 9, 13, 42),
          mealCategoriesRepository: repo,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

/// The option labels the selector offers, top to bottom.
List<String> _openAndReadOptions(WidgetTester tester) {
  final entries = <(double, String)>[];
  for (final element in tester.elementList(
    find.byWidgetPredicate(
      (widget) => widget.key.toString().contains('meal-category-option-'),
    ),
  )) {
    final card = find.byWidget(element.widget);
    entries.add((
      tester.getTopLeft(card).dy,
      tester
          .widget<Text>(find.descendant(of: card, matching: find.byType(Text)).first)
          .data!,
    ));
  }
  entries.sort((a, b) => a.$1.compareTo(b.$1));
  return [for (final entry in entries) entry.$2];
}

Future<void> _openSelector(WidgetTester tester) async {
  await tester.tap(find.byKey(_footerCategory));
  await tester.pumpAndSettle();
}

void main() {
  group('options come from the Meal Categories source', () {
    testWidgets('a NULL stored config resolves the canonical four',
        (tester) async {
      // Not a fallback: the repository resolves defaults for an untouched
      // account, which is a real answer and different from a failed read.
      await _pumpQuickAdd(tester);
      await _openSelector(tester);

      expect(
        _openAndReadOptions(tester),
        ['Breakfast', 'Lunch', 'Dinner', 'Snacks'],
      );
    });

    testWidgets('a custom category appears without being asked for',
        (tester) async {
      await _pumpQuickAdd(
        tester,
        stored: _config(
          customs: [(id: _customA, name: 'Pre Workout', order: 15)],
        ),
      );
      await _openSelector(tester);

      expect(
        _openAndReadOptions(tester),
        ['Breakfast', 'Lunch', 'Pre Workout', 'Dinner', 'Snacks'],
        reason: 'and in the order the configuration puts it',
      );
    });

    testWidgets('a renamed category shows its new name', (tester) async {
      await _pumpQuickAdd(
        tester,
        stored: _config(renamed: {'meal_slot_2': 'Midday Meal'}),
      );
      await _openSelector(tester);

      final options = _openAndReadOptions(tester);
      expect(options, contains('Midday Meal'));
      expect(options, isNot(contains('Lunch')));
    });

    testWidgets('an archived category is not offered for a new log',
        (tester) async {
      await _pumpQuickAdd(
        tester,
        stored: _config(archived: {'meal_slot_3'}),
      );
      await _openSelector(tester);

      expect(_openAndReadOptions(tester), ['Breakfast', 'Lunch', 'Snacks']);
    });

    testWidgets('a restored category is offered again', (tester) async {
      // Same identity, brought back — the selector follows the source rather
      // than any list of its own.
      final repo = _Repository(stored: _config(archived: {'meal_slot_3'}));
      await _pumpQuickAdd(tester, repository: repo);
      await _openSelector(tester);
      expect(_openAndReadOptions(tester), isNot(contains('Dinner')));

      await tester.tap(find.byKey(_option('meal_slot_1')));
      await tester.pumpAndSettle();

      // Restored elsewhere, then a genuinely fresh editor session reads it
      // back. The blank pump forces a new State: without it Flutter reuses the
      // existing one and `initState` — where the read happens — never runs.
      await repo.upsert(_config());
      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpQuickAdd(tester, repository: repo);
      await _openSelector(tester);
      expect(_openAndReadOptions(tester), contains('Dinner'));
    });

    testWidgets('no internal identity is ever rendered', (tester) async {
      await _pumpQuickAdd(
        tester,
        stored: _config(
          customs: [(id: _customA, name: 'Pre Workout', order: 15)],
        ),
      );
      await _openSelector(tester);

      for (final id in [
        'meal_slot_1',
        'meal_slot_2',
        'meal_slot_3',
        'meal_slot_4',
        _customA,
      ]) {
        expect(find.textContaining(id), findsNothing, reason: '$id is not copy');
      }
      for (final key in ['breakfast', 'lunch', 'dinner', 'snacks']) {
        expect(
          find.textContaining(key, findRichText: true),
          findsNothing,
          reason: 'defaultKey $key is not copy',
        );
      }
    });
  });

  group('selection is an identity, not a label', () {
    testWidgets('choosing a category updates what the footer reads',
        (tester) async {
      await _pumpQuickAdd(tester);
      expect(find.text('Select meal type'), findsOne);

      await _openSelector(tester);
      await tester.tap(find.byKey(_option('meal_slot_2')));
      await tester.pumpAndSettle();

      expect(find.text('Lunch'), findsOne);
      expect(find.text('Select meal type'), findsNothing);
    });

    testWidgets('reopening the selector marks the current choice',
        (tester) async {
      await _pumpQuickAdd(tester);
      await _openSelector(tester);
      await tester.tap(find.byKey(_option('meal_slot_3')));
      await tester.pumpAndSettle();

      await _openSelector(tester);
      final selected = tester
          .widgetList<TioSelectableCard>(find.byType(TioSelectableCard))
          .where((card) => card.selected)
          .length;
      expect(selected, 1, reason: 'exactly one option reads as chosen');
      expect(
        tester.widget<TioSelectableCard>(find.byKey(_option('meal_slot_3'))).selected,
        isTrue,
      );
    });

    testWidgets('the selection survives a rebuild', (tester) async {
      await _pumpQuickAdd(tester);
      await _openSelector(tester);
      await tester.tap(find.byKey(_option('meal_slot_4')));
      await tester.pumpAndSettle();

      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('Snacks'), findsOne);
    });

    testWidgets('dismissing the selector leaves the selection alone',
        (tester) async {
      await _pumpQuickAdd(tester);
      await _openSelector(tester);
      await tester.tap(find.byKey(_option('meal_slot_1')));
      await tester.pumpAndSettle();
      expect(find.text('Breakfast'), findsOne);

      await _openSelector(tester);
      // Dismiss without choosing.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(
        find.text('Breakfast'),
        findsOne,
        reason: 'a dismissal is not a request to clear',
      );
    });
  });

  group('boundaries this slice must not cross', () {
    testWidgets('choosing a category does not touch the date or the numbers',
        (tester) async {
      await _pumpQuickAdd(tester);
      await tester.enterText(find.byKey(const ValueKey('quick-add-calories')), '420');
      await tester.pumpAndSettle();
      final dateBefore =
          tester.widget<Text>(find.descendant(
        of: find.byKey(_footerDateTime),
        matching: find.byType(Text),
      )).data;

      await _openSelector(tester);
      await tester.tap(find.byKey(_option('meal_slot_2')));
      await tester.pumpAndSettle();

      expect(
        tester.widget<Text>(find.descendant(
          of: find.byKey(_footerDateTime),
          matching: find.byType(Text),
        )).data,
        dateBefore,
        reason: 'meal type and date/time are separate state',
      );
      expect(find.text('420'), findsOne);
    });

    testWidgets('Log Meal stays disabled after a category is chosen',
        (tester) async {
      await _pumpQuickAdd(tester);
      await _openSelector(tester);
      await tester.tap(find.byKey(_option('meal_slot_2')));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TioButton>(find.byKey(_footerPrimary)).onPressed,
        isNull,
        reason: 'persistence is not this slice; the CTA stays honest',
      );
    });
  });

  group('limits', () {
    testWidgets('one active category is a usable selector', (tester) async {
      await _pumpQuickAdd(
        tester,
        stored: _config(
          archived: {'meal_slot_2', 'meal_slot_3', 'meal_slot_4'},
        ),
      );
      await _openSelector(tester);

      expect(_openAndReadOptions(tester), ['Breakfast']);
      await tester.tap(find.byKey(_option('meal_slot_1')));
      await tester.pumpAndSettle();
      expect(find.text('Breakfast'), findsOne);
    });

    testWidgets('all eight active categories stay reachable', (tester) async {
      await _pumpQuickAdd(
        tester,
        stored: _config(
          customs: [
            (id: _customA, name: 'Pre Workout', order: 5),
            (id: _customB, name: 'Post Workout', order: 15),
            (
              id: 'meal_slot_cccccccc-cccc-4ccc-8ccc-000000000000',
              name: 'Late Meal',
              order: 45
            ),
            (
              id: 'meal_slot_dddddddd-dddd-4ddd-8ddd-000000000000',
              name: 'Second Breakfast',
              order: 55
            ),
          ],
        ),
      );
      await _openSelector(tester);

      expect(_openAndReadOptions(tester), hasLength(8));
      // The last one is reachable, not merely present.
      final last =
          find.byKey(_option('meal_slot_dddddddd-dddd-4ddd-8ddd-000000000000'));
      await tester.ensureVisible(last);
      await tester.pumpAndSettle();
      await tester.tap(last);
      await tester.pumpAndSettle();
      expect(find.text('Second Breakfast'), findsOne);
    });
  });

  group('loading and failure', () {
    testWidgets('the control is inert while the categories load',
        (tester) async {
      final repo = _Repository()..readGate = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              TioTheme(child: child ?? const SizedBox.shrink()),
          home: Scaffold(
            body: QuickAddEditorSheet(mealCategoriesRepository: repo),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(_footerCategory));
      await tester.pumpAndSettle();
      expect(
        find.byKey(_selectorOptions),
        findsNothing,
        reason: 'nothing to offer yet, so nothing opens',
      );

      repo.readGate!.complete();
      await tester.pumpAndSettle();
      await _openSelector(tester);
      expect(find.byKey(_selectorOptions), findsOne);
    });

    testWidgets('a failed read never fabricates the canonical four',
        (tester) async {
      final repo = _Repository()..failNextRead = StateError('offline');
      await _pumpQuickAdd(tester, repository: repo);

      await _openSelector(tester);
      expect(find.byKey(_selectorFailure), findsOne);
      for (final name in const ['Breakfast', 'Lunch', 'Dinner', 'Snacks']) {
        expect(
          find.text(name),
          findsNothing,
          reason: 'a failed read must not claim these are the categories',
        );
      }
    });

    testWidgets('the failure offers a retry that reaches the repository',
        (tester) async {
      final repo = _Repository()..failNextRead = StateError('offline');
      await _pumpQuickAdd(tester, repository: repo);
      final readsBefore = repo.reads;

      await _openSelector(tester);
      await tester.tap(find.byKey(_selectorRetry));
      await tester.pumpAndSettle();

      expect(repo.reads, greaterThan(readsBefore));
      await _openSelector(tester);
      expect(
        find.byKey(_selectorOptions),
        findsOne,
        reason: 'the retry succeeded, so the options are there now',
      );
    });
  });

  group('accessibility', () {
    testWidgets('the control speaks a label and its value, never an id',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpQuickAdd(tester);

      expect(
        tester.getSemantics(find.byKey(_footerCategory)),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          label: 'Meal type. None selected.',
        ),
      );

      await _openSelector(tester);
      await tester.tap(find.byKey(_option('meal_slot_2')));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byKey(_footerCategory)),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          label: 'Meal type. Lunch.',
        ),
      );
      handle.dispose();
    });
  });

  group('theme and layout', () {
    for (final mode in TioThemeMode.values) {
      testWidgets('${mode.name} resolves without a hardcoded surface',
          (tester) async {
        await _pumpQuickAdd(tester, mode: mode);
        await _openSelector(tester);

        expect(find.byKey(_selectorOptions), findsOne);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a long custom name shortens rather than overflowing',
        (tester) async {
      await _pumpQuickAdd(
        tester,
        size: const Size(320, 640),
        textScale: 1.6,
        stored: _config(
          renamed: {'meal_slot_2': 'A Very Long Custom Meal Category Name'},
        ),
      );
      await _openSelector(tester);
      await tester.tap(find.byKey(_option('meal_slot_2')));
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'the footer row shortens the name, it does not overflow',
      );
      expect(
        find.byKey(_footerDateTime),
        findsOne,
        reason: 'and the date is not pushed off the row',
      );
    });
  });
}
