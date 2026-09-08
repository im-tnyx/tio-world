import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

class _Repository implements MealCategoriesRepository {
  _Repository({MealCategoriesConfig? stored}) : _stored = stored;

  MealCategoriesConfig? _stored;
  int writes = 0;
  Object? failNextRead;

  @override
  Future<MealCategoriesConfig> read() async {
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
    config.validate();
    final previous = _stored;
    if (previous != null) {
      MealCategoriesTransitionPolicy.validate(previous: previous, next: config);
    }
    _stored = config;
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

Future<_Repository> _pump(
  WidgetTester tester, {
  MealCategoriesConfig? stored,
  _Repository? repository,
  TioThemeMode mode = TioThemeMode.light,
}) async {
  final repo = repository ?? _Repository(stored: stored);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: mode),
        child: child ?? const SizedBox.shrink(),
      ),
      home: ArchivedMealCategoriesPage(repository: repo),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

const _firstArchived = 'meal_slot_bbbbbbbb-bbbb-4bbb-8bbb-000000000000';

void main() {
  testWidgets('an empty archive explains how something gets here',
      (tester) async {
    final repo = await _pump(tester, stored: _config());

    expect(
      find.byKey(const ValueKey('archived-categories-empty')),
      findsOneWidget,
    );
    expect(
      repo.writes,
      0,
      reason: 'looking at the archive must not write anything',
    );
  });

  testWidgets('archived categories are listed with a Restore action',
      (tester) async {
    await _pump(
      tester,
      stored: _config(archived: ['Evening Snack', 'Late Night Meal']),
    );

    expect(find.text('Evening Snack'), findsOneWidget);
    expect(find.text('Late Night Meal'), findsOneWidget);
    expect(find.text('Restore'), findsNWidgets(2));
    // Durable identities stay out of the interface.
    expect(find.textContaining('meal_slot_'), findsNothing);
  });

  testWidgets('the name leads and Restore trails', (tester) async {
    await _pump(tester, stored: _config(archived: ['Evening Snack']));

    final nameRect = tester.getRect(find.text('Evening Snack'));
    final restoreRect = tester.getRect(
      find.byKey(
        const ValueKey('archived-category-reactivate-$_firstArchived'),
      ),
    );

    expect(
      restoreRect.left,
      greaterThan(nameRect.right),
      reason: 'the action sits after the name, not beside it',
    );

    // Trailing, not merely later: it ends near the card's right edge, the way
    // the pencil does on the active list.
    final card = tester.getRect(find.byType(TioGroupCard));
    expect(
      card.right - restoreRect.right,
      lessThan(TioSpacing.xl),
      reason: 'right-aligned within the row',
    );
  });

  testWidgets('every archived row carries a glyph, whatever it was',
      (tester) async {
    final base = _config(archived: ['Evening Snack']);
    await _pump(
      tester,
      stored: MealCategoriesConfig(
        items: base.orderedItems.map(
          (item) => item.id == 'meal_slot_2' ? item.withActive(false) : item,
        ),
      ),
    );

    // An archived default keeps the glyph it carried on the active list, so
    // the same category reads the same on both screens.
    final lunch = find.byKey(const ValueKey('meal-category-glyph-meal_slot_2'));
    expect(lunch, findsOneWidget);
    expect(tester.widget<Icon>(lunch).icon, Icons.lunch_dining_outlined);

    // A custom had a grip in that column and can no longer be dragged, so it
    // takes the generic glyph rather than leaving the column empty beside its
    // neighbour's.
    final custom = find.byKey(
      const ValueKey('meal-category-glyph-$_firstArchived'),
    );
    expect(custom, findsOneWidget);
    expect(tester.widget<Icon>(custom).icon, Icons.restaurant_outlined);

    expect(
      tester.getRect(custom).right,
      lessThanOrEqualTo(tester.getRect(find.text('Evening Snack')).left),
      reason: 'the glyph leads the name',
    );
  });

  testWidgets('a long name shortens rather than pushing Restore off the row',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.6)),
          child: TioTheme(child: child ?? const SizedBox.shrink()),
        ),
        home: ArchivedMealCategoriesPage(
          repository: _Repository(
            stored: _config(archived: ['A Very Long Archived Category Name']),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.takeException(),
      isNull,
      reason: 'a Row can overflow where the previous Wrap could not',
    );
    expect(
      find.byKey(
        const ValueKey('archived-category-reactivate-$_firstArchived'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('rows are separated by a rule, with none after the last',
      (tester) async {
    await _pump(
      tester,
      stored: _config(archived: ['Evening Snack', 'Late Night Meal']),
    );

    final dividers = find.byWidgetPredicate((widget) =>
        widget is Divider &&
        widget.key.toString().contains('archived-category-divider'));
    expect(
      dividers,
      findsOneWidget,
      reason: 'two rows means one rule between them, and none after the last',
    );
    final divider = tester.widget<Divider>(dividers);
    expect(
      divider.indent,
      TioSpacing.lg + TioSize.dp20 + TioSpacing.md,
      reason: 'starts where the names do, past the glyph column',
    );
    expect(
      divider.endIndent,
      TioSpacing.none,
      reason: 'and flush at the end, matching the active list',
    );
  });

  testWidgets('restoring reuses the same identity and leaves the archive',
      (tester) async {
    final repo = await _pump(tester, stored: _config(archived: ['Late Night']));

    await tester.tap(
      find.byKey(const ValueKey('archived-category-reactivate-$_firstArchived')),
    );
    await tester.pumpAndSettle();

    final stored = await repo.read();
    final restored = stored.findById(_firstArchived);
    expect(restored, isNotNull, reason: 'same id, never a new one');
    expect(restored!.active, isTrue);
    expect(restored.displayName, 'Late Night');
    expect(
      stored.activeItems.last.id,
      _firstArchived,
      reason: 'restored categories land last, deterministically',
    );
    expect(
      find.byKey(const ValueKey('archived-categories-empty')),
      findsOneWidget,
      reason: 'nothing archived remains',
    );
  });

  testWidgets('restore is unavailable at the eight-active cap',
      (tester) async {
    await _pump(
      tester,
      stored: _config(extraActive: 4, archived: ['Late Night']),
    );

    expect(
      tester
          .widget<TioButton>(
            find.byKey(
              const ValueKey('archived-category-reactivate-$_firstArchived'),
            ),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('archived-categories-cap-reason')),
          )
          .data,
      'Maximum 8 active meal categories',
    );
  });

  testWidgets('a failed read is reported and can be retried', (tester) async {
    final repo = _Repository(stored: _config(archived: ['Late Night']))
      ..failNextRead = StateError('offline');
    await _pump(tester, repository: repo);

    expect(
      find.byKey(const ValueKey('archived-categories-load-failure')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('archived-categories-retry')));
    await tester.pumpAndSettle();

    expect(find.text('Late Night'), findsOneWidget);
    expect(repo.writes, 0);
  });

  for (final testCase in const [
    (name: 'Light', mode: TioThemeMode.light, expected: TioColors.light),
    (name: 'Dark', mode: TioThemeMode.dark, expected: TioColors.dark),
    (name: 'OLED', mode: TioThemeMode.oled, expected: TioColors.oled),
  ]) {
    testWidgets('${testCase.name} resolves the active palette', (tester) async {
      await _pump(
        tester,
        stored: _config(archived: ['Evening Snack', 'Late Night Meal']),
        mode: testCase.mode,
      );

      final scaffold = tester.widget<Scaffold>(
        find.byKey(const ValueKey('archived-meal-categories-page')),
      );
      expect(scaffold.backgroundColor, testCase.expected.background);
      expect(
        tester
            .widget<Divider>(
              find.byWidgetPredicate((widget) =>
                  widget is Divider &&
                  widget.key.toString().contains('archived-category-divider')),
            )
            .color,
        testCase.expected.outlineStrong.withAlpha(TioAlpha.alpha20),
      );
      expect(tester.takeException(), isNull, reason: testCase.name);
    });
  }
}
